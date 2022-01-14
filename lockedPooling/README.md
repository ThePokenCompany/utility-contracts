# The smart contracts to lock $PKN and earn rewards.

## Usage
1. Create an `allowance` from their wallet for the PooledPKN smart contract for the amount of tokens to be pooled.
2. Call the `enter(amount)` function, with the number of $PKN to pool as input.
  - Optionally add more PKN by calling the `enter(amount)` function multiple times.
3. Wait for the unlock date (365/730 days from the first deposit)
4. Call the `leave()` function

## Usage (for admin)
1. Deposit PKN rewards, as determined by the `pendingRewards()` function. The function returns the exact amount of $PKN to be sent to the contract to give out rewards to all the people who locked till now.

## Read Functions
- Calling `depositOf(user)` will return the amount of $PKN locked by the user.
- Calling `totalRewardOf(user)` will return the amount of $PKN made available to the user at unlock.
- Calling `unlockTimeOf(address account)` will return the unlock timestamp for the given account.

## Reward Rates
Lock 12 month : entry open until 21/12/2022
 - 0 → 1 M       : 25 % bonus
 - 1 M → 10 M    : 30 % bonus
 - more than 10M : 35 % bonus

Lock 24 month : entry open until 21/12/2022
 - 0 → 1 M       : 65 % bonus
 - 1 M → 10 M    : 80 % bonus
 - more than 10M : 90 % bonus
