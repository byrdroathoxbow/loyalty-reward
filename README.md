# Loyalty Reward Distribution Smart Contract

A comprehensive time-locked loyalty reward system built on the Stacks blockchain using Clarity. This contract enables businesses to reward users with cashback, transaction-based bonuses, and time-locked reward distributions.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Contract Architecture](#contract-architecture)
- [Installation & Deployment](#installation--deployment)
- [Usage Guide](#usage-guide)
- [API Reference](#api-reference)
- [Configuration](#configuration)
- [Security Features](#security-features)
- [Error Codes](#error-codes)
- [Examples](#examples)
- [Contributing](#contributing)

## 🎯 Overview

The Loyalty Reward Contract is designed to incentivize user engagement through automated reward distribution. It tracks on-chain transactions, calculates cashback rewards, and distributes bonuses based on user activity milestones.

### Key Benefits
- **Automated Rewards**: Seamless cashback calculation and distribution
- **Time-Locked Security**: Prevents immediate reward extraction
- **Milestone Bonuses**: Encourages sustained platform engagement
- **Transparent Operations**: All rewards and transactions are on-chain
- **Flexible Configuration**: Adjustable parameters for different business models

## ✨ Features

### 🔒 Time-Locked Rewards
- All rewards are locked for a configurable period (default: ~24 hours)
- Prevents immediate extraction and encourages long-term engagement
- Automatic unlock based on block height

### 💰 Cashback System
- Automatic cashback calculation on user transactions
- Configurable cashback percentage (default: 5%)
- Instant cashback accrual with time-locked claiming

### 🏆 Transaction-Based Bonuses
- Milestone rewards for reaching transaction thresholds
- One-time bonus claiming per user
- Configurable minimum transaction requirements

### 📊 User Analytics
- Comprehensive user profile tracking
- Transaction count monitoring
- Total rewards earned history
- Last activity timestamps

## 🏗 Contract Architecture

### Data Structures

#### User Profiles
```clarity
{
  total-transactions: uint,
  total-rewards: uint,
  last-activity: uint,
  cashback-earned: uint,
  bonus-claimed: bool
}
```

#### Pending Rewards
```clarity
{
  amount: uint,
  unlock-block: uint,
  reward-type: string-ascii,
  claimed: bool
}
```

### Core Components
- **Reward Pool Management**: Centralized STX pool for reward distribution
- **Time-Lock Mechanism**: Block-height based reward unlocking
- **User Profile System**: Comprehensive activity tracking
- **Batch Operations**: Efficient multi-reward claiming

## 🚀 Installation & Deployment

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet with STX for deployment
- Node.js (for testing and interaction scripts)

### Deployment Steps

1. **Clone and Setup**
```bash
git clone <repository-url>
cd loyalty-reward-contract
clarinet new loyalty-rewards
```

2. **Add Contract**
```bash
# Copy the contract code to contracts/loyalty-reward.clar
```

3. **Test Locally**
```bash
clarinet test
```

4. **Deploy to Testnet**
```bash
clarinet deploy --testnet
```

5. **Deploy to Mainnet**
```bash
clarinet deploy --mainnet
```

## 📖 Usage Guide

### For Business Owners

#### 1. Fund the Reward Pool
```clarity
(contract-call? .loyalty-reward fund-rewards-pool u10000000) ;; Fund with 10 STX
```

#### 2. Configure Parameters
```clarity
;; Set 3% cashback
(contract-call? .loyalty-reward set-cashback-percentage u3)

;; Require 20 transactions for bonus
(contract-call? .loyalty-reward set-min-transactions-for-bonus u20)
```

### For Users

#### 1. Register Transaction Activity
```clarity
;; Register a transaction worth 1 STX
(contract-call? .loyalty-reward register-transaction 'SP1234... u1000000)
```

#### 2. Check Reward Status
```clarity
;; Get user profile
(contract-call? .loyalty-reward get-user-profile 'SP1234...)

;; Check specific reward
(contract-call? .loyalty-reward get-pending-reward 'SP1234... u1)
```

#### 3. Claim Rewards
```clarity
;; Claim single reward
(contract-call? .loyalty-reward claim-reward u1)

;; Claim milestone bonus
(contract-call? .loyalty-reward claim-bonus)

;; Batch claim multiple rewards
(contract-call? .loyalty-reward batch-claim-rewards (list u1 u2 u3))
```

## 📚 API Reference

### Read-Only Functions

| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `get-user-profile` | `principal` | `Profile \| none` | Retrieves user activity data |
| `get-pending-reward` | `principal`, `uint` | `Reward \| none` | Gets specific reward details |
| `get-total-rewards-pool` | - | `uint` | Returns available reward pool |
| `is-reward-unlocked` | `principal`, `uint` | `bool` | Checks if reward is claimable |
| `calculate-cashback` | `uint` | `uint` | Calculates cashback for amount |
| `is-eligible-for-bonus` | `principal` | `bool` | Checks bonus eligibility |

### Public Functions

| Function | Access | Parameters | Returns | Description |
|----------|--------|------------|---------|-------------|
| `register-transaction` | Anyone | `principal`, `uint` | `Response` | Records user transaction |
| `claim-reward` | User | `uint` | `Response` | Claims specific reward |
| `claim-bonus` | User | - | `Response` | Claims milestone bonus |
| `batch-claim-rewards` | User | `(list 10 uint)` | `Response` | Claims multiple rewards |
| `fund-rewards-pool` | Owner | `uint` | `Response` | Adds STX to pool |
| `set-cashback-percentage` | Owner | `uint` | `Response` | Updates cashback rate |
| `emergency-withdraw` | Owner | `uint` | `Response` | Emergency fund recovery |

## ⚙️ Configuration

### Default Settings
- **Cashback Percentage**: 5%
- **Reward Lock Period**: 144 blocks (~24 hours)
- **Minimum Transactions for Bonus**: 10
- **Bonus Amount**: 1 STX (1,000,000 microSTX)

### Customization Options
All parameters are configurable by the contract owner:

```clarity
;; Update cashback rate (max 100%)
(set-cashback-percentage u10) ;; 10% cashback

;; Change lock period (blocks)
(set-reward-lock-period u288) ;; ~48 hours

;; Adjust bonus threshold
(set-min-transactions-for-bonus u5) ;; 5 transactions
```

## 🔐 Security Features

### Access Control
- **Owner-Only Functions**: Critical operations restricted to contract deployer
- **User-Specific Claims**: Users can only claim their own rewards
- **Double-Claim Prevention**: Built-in checks prevent reward duplication

### Financial Security
- **Balance Verification**: Ensures sufficient funds before transfers
- **Emergency Controls**: Owner can withdraw funds if needed
- **Time-Lock Protection**: Prevents immediate reward extraction

### Input Validation
- **Amount Limits**: Validates all monetary inputs
- **Parameter Bounds**: Enforces reasonable configuration limits
- **User Verification**: Confirms user existence before operations

## ❌ Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `ERR_NOT_OWNER` | Unauthorized access to owner function |
| u101 | `ERR_INSUFFICIENT_BALANCE` | Not enough STX in reward pool |
| u102 | `ERR_TIME_LOCKED` | Reward not yet unlocked |
| u103 | `ERR_USER_NOT_FOUND` | User profile doesn't exist |
| u104 | `ERR_ALREADY_CLAIMED` | Reward already claimed |
| u105 | `ERR_INSUFFICIENT_TRANSACTIONS` | Not enough transactions for bonus |
| u106 | `ERR_INVALID_AMOUNT` | Invalid amount parameter |

## 💡 Examples

### Complete User Journey

```clarity
;; 1. Business funds the contract
(contract-call? .loyalty-reward fund-rewards-pool u50000000) ;; 50 STX

;; 2. User makes their first transaction
(contract-call? .loyalty-reward register-transaction 'SP1A2B3C... u2000000) ;; 2 STX transaction

;; 3. Check earned cashback (5% = 0.1 STX)
(contract-call? .loyalty-reward get-user-profile 'SP1A2B3C...)
;; Returns: { cashback-earned: u100000, total-transactions: u1, ... }

;; 4. Wait for time-lock period (24 hours)

;; 5. Claim cashback reward
(contract-call? .loyalty-reward claim-reward u1)
;; Returns: (ok u100000)

;; 6. After 10 total transactions, claim bonus
(contract-call? .loyalty-reward claim-bonus)
;; Returns: (ok u1000000) ;; 1 STX bonus
```

### Batch Operations

```clarity
;; Claim multiple rewards at once
(contract-call? .loyalty-reward batch-claim-rewards (list u1 u2 u3 u4 u5))
```

### Administrative Tasks

```clarity
;; Configure for high-volume business
(contract-call? .loyalty-reward set-cashback-percentage u2) ;; 2% cashback
(contract-call? .loyalty-reward set-min-transactions-for-bonus u50) ;; 50 tx bonus
(contract-call? .loyalty-reward set-reward-lock-period u72) ;; 12 hour lock
```

## 🤝 Contributing

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Submit a pull request

### Testing
```bash
clarinet test
clarinet check
```

**Built with ❤️ for the Stacks ecosystem**