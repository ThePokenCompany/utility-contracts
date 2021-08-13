// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PKNAirdropper {

    IERC20 public PKN;

    constructor(IERC20 _PKN) {
        PKN = _PKN;
    }

    function airdrop(address[] calldata _to, uint256[] calldata _amounts) external {
        require(_to.length == _amounts.length, "Invalid input lengths");
        for (uint256 i = 0; i < _to.length; i++) {
            PKN.transferFrom(msg.sender, _to[i], _amounts[i]);
        }
    }
}
