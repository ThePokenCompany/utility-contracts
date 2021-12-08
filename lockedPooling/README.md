# The smart contract to lock $PKN and earn rewards.

## Usage (for users)
1. Create an `allowance` from their wallet for the PooledPKN smart contract for the amount of tokens to be pooled.
2. Call the `enter(amount)` function, with the number of $PKN to pool as input.
3. Wait for the unlock
4. Call the `leave(share)` function, with the output of `balanceOf()` as input.

## Usage (for admin)
1. Call `setStage(1)` to enable entry to the pool.
2. Call `setStage(2)` to enable exit from the pool.
3. Call `setStage(0)` to disable both entry & exit to/from the pool.

- Calling `balanceOf(user)` will return the amount of allocation to the user.
- Calling `pknShareOf(user)` will return the amount of $PKN that the user's allocation is worth if unpooled today.
- The contract supports handing out rewards to all stackers in $PKN by simply sending the $PKN to this contract.
