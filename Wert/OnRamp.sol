// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LogReceipt is Ownable {

    IERC20 public immutable USDC;

    mapping(uint256 => bool) public allTrasfers;

    event Recieved(uint256 amount, uint256 transferID, bytes32 data);

    constructor(address usdc) {
        USDC = IERC20(usdc);
    }

    function transfer(address token, address to, uint256 amount) external onlyOwner {
        if(token == address(0)) {
            payable(to).transfer(amount);
        }
        else {
            IERC20(token).transfer(to, amount);
        }
    }

    function log(uint256 amount, uint256 transferID, bytes32 data) external {
        IERC20(USDC).transferFrom(msg.sender, address(this), amount);
        allTrasfers[transferID] = true;
        emit Recieved(amount, transferID, data);
    }
}
