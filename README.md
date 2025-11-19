```markdown
# StackBounty - Decentralized Bounty Board

A smart contract for the Stacks blockchain that enables a decentralized bounty system where users can post tasks, developers can submit solutions, and rewards are distributed trustlessly using STX tokens.

## Overview

StackBounty is a peer-to-peer bounty platform built on Clarity smart contracts. It allows task posters to create bounties with STX rewards, developers to submit solutions, and automated payment upon approval. The system includes reputation tracking to build trust within the community.

## Features

### Core Functionality

- **Post Bounties**: Create bounties with title, description, category, reward amount, and deadline
- **Submit Solutions**: Developers can submit solutions to open bounties before the deadline
- **Approve & Pay**: Bounty posters approve solutions and automatically pay developers
- **Refund Expired**: Unclaimed bounties can be refunded after the deadline passes
- **Developer Reputation**: Track developer ratings (1-5 points) based on completed work
- **Admin Controls**: Contract owner can remove fraudulent bounties

### Security Features

- Principal-based access control (only posters can approve, only developers can submit)
- Escrow system - rewards held in contract until approval
- Deadline enforcement - prevents submissions after deadline
- Status tracking - prevents duplicate approvals or refunds
- Input validation - ensures valid reward amounts and rating scores

## Smart Contract Functions

### Public Functions

#### `post-bounty`
Creates a new bounty with specified parameters.

```clarity
(post-bounty 
  title: (string-ascii 64)
  description: (string-ascii 256)
  category: (string-ascii 32)
  reward: uint
  duration: uint
) -> (response {bounty-id: uint, reward: uint} uint)
```

**Parameters:**
- `title`: Brief title of the bounty task
- `description`: Detailed description of what needs to be done
- `category`: Category tag (e.g., "frontend", "backend", "design")
- `reward`: STX amount to be awarded (must be > 0)
- `duration`: Block height duration until deadline

**Returns:** Bounty ID and reward amount on success, error code on failure

---

#### `submit-solution`
Allows a developer to submit a solution to an open bounty.

```clarity
(submit-solution 
  bounty-id: uint
  submission: (string-ascii 256)
) -> (response (string-ascii 31) uint)
```

**Parameters:**
- `bounty-id`: ID of the target bounty
- `submission`: Solution details/documentation

**Returns:** Success message or error code

---

#### `approve-solution`
Approves a submission and transfers the reward to the developer.

```clarity
(approve-solution 
  bounty-id: uint
  developer: principal
) -> (response (string-ascii 12) uint)
```

**Parameters:**
- `bounty-id`: ID of the bounty to approve
- `developer`: Principal address of the developer who submitted

**Returns:** Success message or error code

**Restrictions:** Only the bounty poster can approve

---

#### `get-reputation`
Retrieves a developer's reputation data.

```clarity
(get-reputation developer: principal) -> (optional {
  points: uint
  completed: uint
})
```

---

#### `get-total-bounties`
Gets the total number of bounties posted.

```clarity
(get-total-bounties) -> uint
```

```

### Submission Object

```clarity
{
  submission: (string-ascii 256), ;; Solution details
  approved: bool                  ;; Approval status
}
```

### Reputation Object

```clarity
{
  points: uint,       ;; Total reputation points
  completed: uint     ;; Number of completed bounties
}
```

## Usage Examples

### Example 1: Post a Bounty

```clarity
;; Post a $100 bounty (100,000,000 microSTX) with 1000 block duration
(contract-call? .stackbounty post-bounty
  "Build a Todo App"
  "Create a simple todo application with add/delete functionality"
  "frontend"
  u100000000
  u1000)
```

### Example 2: Submit a Solution

```clarity
(contract-call? .stackbounty submit-solution
  u1
  "Solution implemented at https://github.com/user/todo-app")
```

### Example 3: Approve and Pay

```clarity
;; Bounty poster approves the solution
(contract-call? .stackbounty approve-solution
  u1
  'SP2JXKMXPNZ7Z3M6FG7UXCPXNKR6GJJZZ7ZZZZ01)
```

### Deployment

1. Clone the repository
2. Run `clarinet contract deploy stackbounty`
3. Interact with the contract via web app or CLI

### Testing

```bash
clarinet test
```

## File Structure

```
stackbounty/
├── contracts/
│   └── stackbounty.clar          ;; Main smart contract
├── tests/
│   └── stackbounty.test.ts       ;; Unit tests (optional)
├── README.md                      ;; This file
└── Clarinet.toml                 ;; Project configuration





## Disclaimer

This smart contract is provided as-is for educational purposes. Always audit contracts before mainnet deployment. Users are responsible for their transactions and fund management.


**Last Updated**: November 19, 2025  
**Status**: Production Ready ✅
