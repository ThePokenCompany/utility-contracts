// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// This contract handles staking PKN per creator
contract PKNStake4Creator {

    mapping(address => mapping(address => uint256)) private _staked;
    mapping(address => uint256) private _totalStakedBy;
    mapping(address => uint256) private _totalStakedFor;

    IERC20 public immutable PKN;

    event Staked(address user, address creator, uint256 amount);
    event Unstaked(address user, address creator, uint256 amount);

    constructor(IERC20 _PKN) {
        PKN = _PKN;
    }

    function staked(address user, address creator) public view returns(uint256) {
        return _staked[user][creator];
    }

    function totalStakedBy(address user) public view returns(uint256) {
        return _totalStakedBy[user];
    }

    function totalStakedFor(address creator) public view returns(uint256) {
        return _totalStakedFor[creator];
    }

    // Stake PKN for for a specific creator
    function stake(address creator, uint256 amount) external {
        uint256 _actualAmount = _receivePKN(msg.sender, amount);

        _staked[msg.sender][creator] += _actualAmount;
        _totalStakedBy[msg.sender] += _actualAmount;
        _totalStakedFor[creator] += _actualAmount;

        emit Staked(msg.sender, creator, _actualAmount);
    }

    // Unstake the staked PKN
    function unstake(address creator, uint256 amount) external {
        require(staked(msg.sender, creator) >= amount, "PKNStake4Creator: Amount too high!");

        _staked[msg.sender][creator] -= amount;
        _totalStakedBy[msg.sender] -= amount;
        _totalStakedFor[creator] -= amount;

        PKN.transfer(msg.sender, amount);

        emit Unstaked(msg.sender, creator, amount);
    }

    function _receivePKN(address from, uint256 amount) internal returns(uint256) {
        uint256 balanceBefore = PKN.balanceOf(address(this));
        PKN.transferFrom(from, address(this), amount);
        uint256 balanceAfter = PKN.balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }
}
