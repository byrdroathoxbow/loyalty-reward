;; Loyalty Reward Distribution Contract
;; A time-locked contract for loyalty rewards, bonuses, and cashback

;; Contract constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_OWNER (err u100))
(define-constant ERR_INSUFFICIENT_BALANCE (err u101))
(define-constant ERR_TIME_LOCKED (err u102))
(define-constant ERR_USER_NOT_FOUND (err u103))
(define-constant ERR_ALREADY_CLAIMED (err u104))
(define-constant ERR_INSUFFICIENT_TRANSACTIONS (err u105))
(define-constant ERR_INVALID_AMOUNT (err u106))

;; Data variables
(define-data-var total-rewards-pool uint u0)
(define-data-var min-transactions-for-bonus uint u10)
(define-data-var cashback-percentage uint u5) ;; 5% cashback
(define-data-var reward-lock-period uint u144) ;; ~24 hours in blocks

;; Data maps
(define-map user-profiles
  principal
  {
    total-transactions: uint,
    total-rewards: uint,
    last-activity: uint,
    cashback-earned: uint,
    bonus-claimed: bool
  }
)

(define-map pending-rewards
  { user: principal, reward-id: uint }
  {
    amount: uint,
    unlock-block: uint,
    reward-type: (string-ascii 20),
    claimed: bool
  }
)

(define-map user-reward-count principal uint)

;; Read-only functions
(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles user)
)

(define-read-only (get-pending-reward (user principal) (reward-id uint))
  (map-get? pending-rewards { user: user, reward-id: reward-id })
)

(define-read-only (get-total-rewards-pool)
  (var-get total-rewards-pool)
)

(define-read-only (get-user-reward-count (user principal))
  (default-to u0 (map-get? user-reward-count user))
)

(define-read-only (is-reward-unlocked (user principal) (reward-id uint))
  (match (get-pending-reward user reward-id)
    reward (>= block-height (get unlock-block reward))
    false
  )
)

(define-read-only (calculate-cashback (amount uint))
  (/ (* amount (var-get cashback-percentage)) u100)
)

(define-read-only (is-eligible-for-bonus (user principal))
  (match (get-user-profile user)
    profile (and 
      (>= (get total-transactions profile) (var-get min-transactions-for-bonus))
      (not (get bonus-claimed profile))
    )
    false
  )
)

;; Private functions
(define-private (get-next-reward-id (user principal))
  (+ (get-user-reward-count user) u1)
)

(define-private (update-reward-count (user principal))
  (map-set user-reward-count user (get-next-reward-id user))
)

;; Public functions

;; Initialize or update user profile
(define-public (register-transaction (user principal) (amount uint))
  (let (
    (current-profile (default-to 
      { total-transactions: u0, total-rewards: u0, last-activity: u0, cashback-earned: u0, bonus-claimed: false }
      (get-user-profile user)
    ))
    (new-transaction-count (+ (get total-transactions current-profile) u1))
    (cashback (calculate-cashback amount))
  )
    (map-set user-profiles user
      (merge current-profile {
        total-transactions: new-transaction-count,
        last-activity: block-height,
        cashback-earned: (+ (get cashback-earned current-profile) cashback)
      })
    )
    
    ;; Add cashback as pending reward
    (if (> cashback u0)
      (add-pending-reward user cashback "cashback")
      true
    )
    
    (ok true)
  )
)

;; Add pending reward (internal function)
(define-private (add-pending-reward (user principal) (amount uint) (reward-type (string-ascii 20)))
  (let (
    (reward-id (get-next-reward-id user))
    (unlock-block (+ block-height (var-get reward-lock-period)))
  )
    (map-set pending-rewards 
      { user: user, reward-id: reward-id }
      {
        amount: amount,
        unlock-block: unlock-block,
        reward-type: reward-type,
        claimed: false
      }
    )
    (update-reward-count user)
    true
  )
)

;; Owner function to add rewards to pool
(define-public (fund-rewards-pool (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_OWNER)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set total-rewards-pool (+ (var-get total-rewards-pool) amount))
    (ok true)
  )
)

;; Claim unlocked rewards
(define-public (claim-reward (reward-id uint))
  (let (
    (user tx-sender)
    (reward (unwrap! (get-pending-reward user reward-id) ERR_USER_NOT_FOUND))
  )
    (asserts! (not (get claimed reward)) ERR_ALREADY_CLAIMED)
    (asserts! (>= block-height (get unlock-block reward)) ERR_TIME_LOCKED)
    (asserts! (>= (var-get total-rewards-pool) (get amount reward)) ERR_INSUFFICIENT_BALANCE)
    
    ;; Mark reward as claimed
    (map-set pending-rewards 
      { user: user, reward-id: reward-id }
      (merge reward { claimed: true })
    )
    
    ;; Transfer reward
    (try! (as-contract (stx-transfer? (get amount reward) tx-sender user)))
    
    ;; Update pools and user profile
    (var-set total-rewards-pool (- (var-get total-rewards-pool) (get amount reward)))
    
    (match (get-user-profile user)
      profile (map-set user-profiles user
        (merge profile { total-rewards: (+ (get total-rewards profile) (get amount reward)) })
      )
      false
    )
    
    (ok (get amount reward))
  )
)

;; Claim bonus for reaching transaction threshold
(define-public (claim-bonus)
  (let (
    (user tx-sender)
    (profile (unwrap! (get-user-profile user) ERR_USER_NOT_FOUND))
    (bonus-amount u1000000) ;; 1 STX bonus
  )
    (asserts! (>= (get total-transactions profile) (var-get min-transactions-for-bonus)) ERR_INSUFFICIENT_TRANSACTIONS)
    (asserts! (not (get bonus-claimed profile)) ERR_ALREADY_CLAIMED)
    (asserts! (>= (var-get total-rewards-pool) bonus-amount) ERR_INSUFFICIENT_BALANCE)
    
    ;; Mark bonus as claimed
    (map-set user-profiles user (merge profile { bonus-claimed: true }))
    
    ;; Transfer bonus
    (try! (as-contract (stx-transfer? bonus-amount tx-sender user)))
    
    ;; Update reward pool
    (var-set total-rewards-pool (- (var-get total-rewards-pool) bonus-amount))
    
    (ok bonus-amount)
  )
)

;; Batch claim multiple rewards
(define-public (batch-claim-rewards (reward-ids (list 10 uint)))
  (let (
    (user tx-sender)
    (results (map claim-single-reward reward-ids))
  )
    (ok results)
  )
)

(define-private (claim-single-reward (reward-id uint))
  (match (claim-reward reward-id)
    success success
    error u0
  )
)

;; Admin functions
(define-public (set-cashback-percentage (new-percentage uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_OWNER)
    (asserts! (<= new-percentage u100) ERR_INVALID_AMOUNT)
    (var-set cashback-percentage new-percentage)
    (ok true)
  )
)

(define-public (set-min-transactions-for-bonus (new-min uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_OWNER)
    (var-set min-transactions-for-bonus new-min)
    (ok true)
  )
)

(define-public (set-reward-lock-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_OWNER)
    (var-set reward-lock-period new-period)
    (ok true)
  )
)

;; Emergency withdraw (owner only)
(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_OWNER)
    (asserts! (<= amount (var-get total-rewards-pool)) ERR_INSUFFICIENT_BALANCE)
    (try! (as-contract (stx-transfer? amount tx-sender CONTRACT_OWNER)))
    (var-set total-rewards-pool (- (var-get total-rewards-pool) amount))
    (ok true)
  )
)