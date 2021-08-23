# The smart contract to stack $PKN and get access to Premium features.

## Setup
1. Deploy the smart contract on both ETH and BSC.
2. Exclude the contract from fee in $PKN contract. (optional)

## Usage (for users)
1. Create an `allowance` from their wallet for the PKNPremium smart contract for the amount of tokens to be stacked.
2. Call the `enter(amount)` function, with the number of $PKN to stack as input.
3. Call the `leave(share)` function, with the number of $PKN to unstack as input.

## Usage (for dev)
1. Calling `balanceOf(user)` will return the amount of $xPKN available in user's wallet.
2. Calling `pknStacked(user)` will return the amount of $PKN that the user's $xPKN is worth if unstacked today.
3. The contract also supports handing out rewards to all stackers in $PKN. (if need be in the future).

Note: Whenever a user calls `enter(...)` and stacks some $PKN, they get $xPKN in return.
This $xPKN is an ERC20 token that denotes the underlying $PKN stacked in the contract.
It is freely transferable/sellable on any exchange.
