# The smart contract to pool $PKN and earn rewards.

## Setup
1. Deploy the smart contract on both ETH and BSC.
2. Exclude the contract from fee in $PKN contract. (optional)

## Usage (for users)
1. Create an `allowance` from their wallet for the PooledPKN smart contract for the amount of tokens to be pooled.
2. Call the `enter(amount)` function, with the number of $PKN to pool as input.
3. Call the `leave(share)` function, with the number of $PKN to unpool as input.

## Usage (for dev)
1. Calling `balanceOf(user)` will return the amount of $pPKN available in user's wallet.
2. Calling `pknPooledByUser(user)` will return the amount of $PKN that the user's $pPKN is worth if unpooled today.
3. The contract supports handing out rewards to all stackers in $PKN by simply sending the $PKN to this contract.

Note: Whenever a user calls `enter(...)` and pools some $PKN, they get $pPKN in return.
This $pPKN is an ERC20 token that denotes the underlying $PKN pooled in the contract, but it is NOT freely transferable - it remains locked in the wallet of the user.
