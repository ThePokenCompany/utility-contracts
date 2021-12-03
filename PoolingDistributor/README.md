# The smart contract to distribute $PKN to NFT holders.

## Usage
1. Deploy the smart contract on both ETH and BSC.
2. Create an `allowance` from the owner wallet for the smart contract.
3. Craft an input in the format described below.
4. Call the `addAllToNFTList()` function, from the owner wallet, with the input created above.
5. Call the `createDistribution()` function with parameters: list of creator addresses, list of amounts to distribute.


### Input
The input to the `addAllToNFTList()` function consists of 2 parameters:
* `address[] calldata creators` : denotes a list of creator addresses
* `uint256[][] calldata newIDs` : denotes a list of lists of NFT IDs belonging to each creator.

Example:
```
["0xCB2726077dbff638E14791ed30714bd8e57F707D", "0x84646bC0c5805B86032e311015e3916f9e6101AB"]
[[1, 2], [3, 4, 5]]
```
Will allot:
* NFT ID #1, #2 to 0xCB2726077dbff638E14791ed30714bd8e57F707D
* NFT ID #3, #4, #5 to 0x84646bC0c5805B86032e311015e3916f9e6101AB 
