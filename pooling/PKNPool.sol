// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// This contract handles pooling PKN to get pPKN - and harvest periodic rewards
contract PooledPKN is ERC20("PooledPKN", "pPKN") {
    IERC20 public immutable PKN;

    constructor(IERC20 _PKN) {
        PKN = _PKN;
    }

    // Locks PKN and mints pPKN
    function enter(uint256 _amount) public {
        uint256 totalPKN = PKN.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalPKN == 0) {
            _mint(msg.sender, _amount);
        } 
        else {
            uint256 what = (_amount * totalShares) / totalPKN;
            _mint(msg.sender, what);
        }
        PKN.transferFrom(msg.sender, address(this), _amount);
    }

    function pknPooledByUser(address user) public view returns(uint256) {
        uint256 totalPKN = PKN.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        return (balanceOf(user) * totalPKN) / totalShares;
    }

    // Unlocks the staked PKN and burns pPKN
    function leave(uint256 _share) public {
        uint256 totalPKN = PKN.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        uint256 what = (_share * totalPKN) / totalShares;
        _burn(msg.sender, _share);
        PKN.transfer(msg.sender, what);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal pure override {
        require(false, "pPKN: No transfers allowed");
    }
}
