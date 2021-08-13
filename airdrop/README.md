# The smart contract to airdrop $PKN to ICO investors.

## Usage
1. Deploy the smart contract on both ETH and BSC.
2. Create an `allowance` from the owner wallet for the smart contract for the amount of tokens to be airdropped.
3. Craft an input in the format described below.
4. Call the `airdrop()` function, from the owner wallet, with the input created above.

Note: The airdrop may have to be done in batches depending on block gas limit on each chain.

### Input
The input to the `airdrop()` function consists of 2 parameters:
* `_to` : denotes a list of wallet addresses
* `_amounts` : denotes the corresponding amounts to send to the above wallets (this value has to be scaled by 10^18 to account for decimals)

Example:
```
["0xCB2726077dbff638E14791ed30714bd8e57F707D", "0x84646bC0c5805B86032e311015e3916f9e6101AB"]
[100000000000000000000, 200000000000000000000]
```
Will send:
* 100 PKN to 0xCB2726077dbff638E14791ed30714bd8e57F707D
* 200 PKN to 0x84646bC0c5805B86032e311015e3916f9e6101AB 
