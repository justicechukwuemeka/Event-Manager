# Event Attendance Verification Protocol (EAVP) Smart Contract

## Overview

The Event Attendance Verification Protocol (EAVP) is a comprehensive blockchain-based system built on the Stacks blockchain for managing event attendance verification and automated reward distribution. This smart contract enables event organizers to create verifiable attendance records, allows participants to check in/out of events, supports authorized verification of attendance, and distributes STX rewards based on verified participation and engagement duration.

## Features

- **Event Creation and Management**: Create events with customizable parameters including duration, rewards, and minimum participation requirements
- **Attendance Tracking**: Automated check-in/check-out system with block-level precision
- **Verification System**: Authorized verifiers can validate participant attendance
- **Reward Distribution**: Automated STX reward distribution based on participation and engagement
- **Treasury Management**: Secure fund management for reward distribution
- **Access Control**: Role-based permissions for administrators and verifiers

## Contract Architecture

### Core Data Structures

- **Event Information Registry**: Stores event metadata, timing, and reward configurations
- **Participant Attendance Records**: Tracks check-in/out times and verification status
- **Attendance Verification Details**: Records verification authorities and timestamps
- **Reward Claim History**: Maintains records of distributed rewards
- **Authorized Verification Agents**: Manages verified agent permissions

### Key Constants

- **Maximum Event Duration**: 52,560 blocks (approximately 1 year)
- **Minimum Event Duration**: 144 blocks (approximately 1 day)
- **Maximum Reward Amount**: 1,000,000,000,000 µSTX
- **Event Title Length**: 3-50 characters
- **Event Description Length**: 10-200 characters

## Functions

### Administrative Functions

#### `create-new-event`
Creates a new event with specified parameters.

**Parameters:**
- `event-title`: String (3-50 characters)
- `event-description`: String (10-200 characters)
- `start-block-height`: Event start block
- `duration-in-blocks`: Event duration
- `base-participation-reward`: Base reward amount
- `bonus-engagement-reward`: Additional reward for extended participation
- `minimum-participation-blocks`: Minimum blocks for bonus eligibility

**Access:** System Administrator only

#### `deactivate-existing-event`
Deactivates an active event.

**Parameters:**
- `event-identifier`: Unique event ID

**Access:** System Administrator only

### Attendance Management Functions

#### `register-event-check-in`
Allows participants to check into an active event.

**Parameters:**
- `event-identifier`: Event ID to check into

**Access:** Any user during event period

#### `register-event-check-out`
Records participant check-out time and calculates attendance duration.

**Parameters:**
- `event-identifier`: Event ID to check out from

**Access:** Checked-in participants only

### Verification Functions

#### `verify-participant-attendance`
Allows authorized verifiers to validate participant attendance.

**Parameters:**
- `event-identifier`: Event ID
- `participant-address`: Address of participant to verify

**Access:** Authorized verification agents only

### Reward Functions

#### `claim-participation-reward`
Enables verified participants to claim their STX rewards after event completion.

**Parameters:**
- `event-identifier`: Event ID for reward claim

**Access:** Verified participants only (after event end)

### Agent Management Functions

#### `authorize-verification-agent`
Grants verification privileges to a principal.

**Parameters:**
- `agent-address`: Address to authorize

**Access:** System Administrator only

#### `revoke-verification-agent`
Revokes verification privileges from a principal.

**Parameters:**
- `agent-address`: Address to revoke

**Access:** System Administrator only

### Treasury Functions

#### `deposit-treasury-funds`
Adds STX to the contract treasury for reward distribution.

**Parameters:**
- `deposit-amount`: Amount of STX to deposit

**Access:** Any user

#### `withdraw-treasury-funds`
Withdraws STX from the contract treasury.

**Parameters:**
- `withdrawal-amount`: Amount of STX to withdraw

**Access:** System Administrator only

## Read-Only Functions

- `get-system-administrator`: Returns current administrator address
- `get-event-information`: Retrieves event details by ID
- `get-participant-attendance`: Gets attendance record for specific participant
- `get-reward-claim-information`: Returns reward claim details
- `check-verifier-authorization`: Checks if address is authorized verifier
- `validate-event-existence`: Confirms if event exists
- `check-attendance-verification-eligibility`: Validates if attendance can be verified
- `get-verification-details`: Returns verification information
- `get-comprehensive-verification-status`: Complete verification status overview

## Error Codes

### System Errors (100-199)
- `u100`: Unauthorized access
- `u101`: Reward already claimed
- `u102`: Event not finished
- `u103`: Event expired
- `u104`: No reward available
- `u105`: Event not found
- `u106`: Insufficient treasury balance
- `u107`: Invalid duration range
- `u108`: Duplicate event registration
- `u110`: Invalid start time
- `u111`: Invalid reward configuration
- `u112`: Invalid minimum participation
- `u120`: Event currently inactive
- `u121`: Missing check-in record
- `u122`: Attendance already verified
- `u123`: Invalid participant address

### Principal and Transfer Errors (1000-1099)
- `u1002`: Invalid principal address
- `u1003`: Verifier already authorized
- `u1004`: Verifier not authorized
- `u1005`: Invalid deposit amount
- `u1006`: Event already deactivated
- `u1007`: Transfer operation failed

### Text Validation Errors (2000-2099)
- `u2000`: Invalid event title
- `u2001`: Invalid event description
- `u2002`: Invalid text format

## Usage Workflow

### For Event Organizers

1. **Deposit Funds**: Use `deposit-treasury-funds` to add STX for rewards
2. **Create Event**: Call `create-new-event` with event parameters
3. **Authorize Verifiers**: Use `authorize-verification-agent` to add trusted verifiers
4. **Monitor Event**: Track participation through read-only functions
5. **Manage Treasury**: Withdraw remaining funds after event completion

### For Participants

1. **Check In**: Call `register-event-check-in` when arriving at event
2. **Check Out**: Call `register-event-check-out` when leaving
3. **Wait for Verification**: Authorized verifier must validate attendance
4. **Claim Rewards**: Use `claim-participation-reward` after event ends

### For Verifiers

1. **Verify Attendance**: Use `verify-participant-attendance` to validate participants
2. **Monitor Status**: Check verification eligibility through read-only functions

## Reward Structure

- **Base Reward**: Fixed amount for verified attendance
- **Bonus Reward**: Additional amount for meeting minimum participation duration
- **Total Reward**: Base + Bonus (if eligible)

## Security Features

- **Access Control**: Role-based permissions for different functions
- **Validation**: Comprehensive input validation and business logic checks
- **Treasury Protection**: Secure fund management with balance verification
- **Time-based Controls**: Block height validation for event timing
- **Duplicate Prevention**: Protection against multiple claims and registrations

## Deployment Requirements

- Stacks blockchain environment
- Administrator account for initial setup
- Treasury funding for reward distribution
- Authorized verifier accounts