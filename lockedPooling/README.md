# The smart contract to lock $PKN and earn rewards.

## Usage (for users)
1. Create an `allowance` from their wallet for the PooledPKN smart contract for the amount of tokens to be pooled.
2. Call the `enter(amount)` function, with the number of $PKN to pool as input.
3. Wait for the unlock
4. Call the `leave()` function

## Usage (for admin)
1. Call `enableDeposits()` to enable entry to the pool.

## Read Functions
- Calling `depositOf(user)` will return the amount of $PKN locked by the user.
- Calling `totalRewardOf(user)` will return the amount of $PKN made available to the user at unlock.
- Calling `pendingRewards()` will return the amount of $PKN that needs to be sent to the contract to give out rewards to all the people who locked till now.
