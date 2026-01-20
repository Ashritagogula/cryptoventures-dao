# CryptoVentures DAO – Decentralized Investment Governance System

## Overview
CryptoVentures DAO is a decentralized investment fund governance system that enables ETH contributors to collectively manage treasury allocations and investment decisions through on-chain governance.

This project implements production-grade DAO governance patterns including:
- Stake-based weighted voting (anti-whale)
- Proposal lifecycle management
- Delegation of voting power
- Timelocked execution
- Multi-tier treasury management
- Role-based emergency controls

The design mirrors real-world DAO systems such as Compound, Aave, and MakerDAO.

---

## Architecture

The system is implemented as a single governance contract for simplicity and gas efficiency.

### Core Components
- **DAOGovernance.sol**
  - Stake deposits & voting power
  - Proposal creation & lifecycle
  - Voting & delegation
  - Timelock & execution
  - Treasury category enforcement
  - Admin & guardian controls

---

## Governance Flow

1. Members deposit ETH into the DAO treasury
2. Voting power is calculated using square-root weighting to prevent whale dominance
3. Members create proposals (High-Conviction / Experimental / Operational)
4. Proposals move through lifecycle:
   - Pending → Active → Queued → Executed / Defeated / Canceled
5. Approved proposals are delayed via timelock before execution
6. Guardian can pause or cancel malicious proposals

---

## Voting Mechanism

- Voting power = √(stake + delegated power)
- Vote options: For / Against / Abstain
- One vote per proposal per member
- Delegated voting power is automatically included
- Voting only allowed during active voting window

---

## Treasury Management

Treasury funds are logically split into categories:
- **High-Conviction**: 60% allocation, 7-day timelock
- **Experimental**: 30% allocation, 3-day timelock
- **Operational**: 10% allocation, 1-day timelock

Execution fails gracefully if:
- Category allocation is exceeded
- Treasury balance is insufficient

---

## Security & Emergency Controls

- Timelock prevents instant execution
- Guardian role can:
  - Pause the system
  - Cancel queued proposals
- Admin role manages guardian assignment
- Re-entrancy protected via Checks-Effects-Interactions

---

## Setup Instructions

### 1. Install dependencies
```bash
npm install
```

### 2. Compile contracts
```bash
npx hardhat compile
```

### 3. Deploy & seed test state
```bash
npx hardhat run scripts/deploy.js
```

## Example Usage

- Deposit ETH: deposit()

- Create proposal: propose(...)

- Vote: castVote(...)

- Delegate: delegate(address)

- Queue proposal: queue(proposalId)

- Execute proposal: execute(proposalId)

## Proposal Lifecycle States
- Pending
- Active
- Queued
- Executed
- Defeated
- Canceled


## Design Decisions

- Single-contract architecture chosen for simplicity

- Square-root voting prevents plutocracy

- Custom role system used instead of OpenZeppelin to reduce complexity

- JavaScript deploy script used for compatibility and stability

## Future Improvements

- On-chain quorum thresholds per proposal type

- Snapshot-based delegation

- Frontend governance dashboard

- Off-chain indexing support

## Author

### Ashrita Gogula