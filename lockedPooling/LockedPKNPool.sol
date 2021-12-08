// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// This contract handles locking PKN to get pool rewards
contract LockedPKNPool is Ownable {

    uint256 private constant MIN_DEPOSIT = 98000 * 10**18;
    uint256 private _userCount;
    uint256 private _currentStage;
    uint256 private _totalSupply;

    IERC20 public immutable PKN;
    
    mapping(address => uint256) private _balances;

    constructor(IERC20 _PKN) {
        PKN = _PKN;
    }

    function userCount() public view returns (uint256) {
        return _userCount;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function currentStage() public view returns (uint256) {
        return _currentStage;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function pknShareOf(address user) public view returns(uint256) {
        uint256 totalPKN = PKN.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        return (balanceOf(user) * totalPKN) / totalShares;
    }

    function setStage(uint256 newStage) external onlyOwner {
        /*
            0 : default state, everything disabled
            1 : only entry enabled
            2 : only exit enabled
        */
        _currentStage = newStage;
    }

    // Locks PKN
    function enter(uint256 _amount) external {
        require(currentStage() == 1, "Entry not enabled");

        uint256 totalPKN = PKN.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        uint256 _actualAmount = _receivePKN(msg.sender, _amount);

        if (totalShares == 0 || totalPKN == 0) {
            _allocate(msg.sender, _actualAmount);
        } 
        else {
            uint256 what = (_actualAmount * totalShares) / totalPKN;
            _allocate(msg.sender, what);
        }

        require(pknShareOf(msg.sender) >= MIN_DEPOSIT, "Amount less than minimum deposit");
    }

    // Unlocks PKN and rewards
    function leave(uint256 _share) public {
        require(currentStage() == 2, "Exit not enabled");

        uint256 totalPKN = PKN.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        uint256 what = (_share * totalPKN) / totalShares;
        _deallocate(msg.sender, _share);
        PKN.transfer(msg.sender, what);
    }

    function _receivePKN(address from, uint256 amount) internal returns (uint256) {
        uint256 balanceBefore = PKN.balanceOf(address(this));
        PKN.transferFrom(from, address(this), amount);
        return PKN.balanceOf(address(this)) - balanceBefore;
    }

    function _allocate(address account, uint256 amount) internal {
        if(_balances[account] == 0) {
            _userCount += 1;
        }
        _balances[account] += amount;
        _totalSupply += amount;
    }

    function _deallocate(address account, uint256 amount) internal {
        _balances[account] = _balances[account] - amount;
        _totalSupply -= amount;
        if(_balances[account] == 0) {
            _userCount -= 1;
        }
    }
}
