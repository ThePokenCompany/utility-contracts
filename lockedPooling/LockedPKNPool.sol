// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

// This contract handles locking PKN to get great rewards
contract LockedPool is Ownable {

    uint256 public constant TIER_MIN = 98000 * 10**18;
    uint256 public constant TIER_MID = TIER_MIN * 10;
    uint256 public constant TIER_MAX = TIER_MIN * 100;
    
    uint256 public constant REWARD_MIN = 15;
    uint256 public constant REWARD_MID = 25;
    uint256 public constant REWARD_MAX = 35;
    uint256 public constant TOTAL_DURATION = 365 days;

    uint256 public stage;
    uint256 public endTime;
    uint256 public totalOwed;
    uint256 public totalDeposit;

    mapping(address => uint256) private userOwed;
    mapping(address => uint256) private userDeposit;

    IERC20 public immutable PKN;

    constructor(IERC20 _PKN) {
        PKN = _PKN;
    }

    function splitTiers(uint256 amount) public pure returns(uint256 tA, uint256 tB, uint256 tC) {
        if(amount > TIER_MAX) {
            tC = amount - TIER_MAX;
        }
        if(amount > TIER_MID) {
            tB = amount - tC - TIER_MID;
        }
        tA = amount - tC - tB;
    }

    function depositOf(address account) public view returns (uint256) {
        return userDeposit[account];
    }

    function totalRewardOf(address account) public view returns (uint256) {
        return userOwed[account];
    }

    function pendingRewards() external view returns(uint256 pending) {
        uint256 currentBalance = PKN.balanceOf(address(this));
        if(totalOwed > currentBalance) {
            pending = totalOwed - currentBalance;
        }
    }

    function enableDeposits() external onlyOwner() {
        require(stage == 0, "Deposit already enabled");
        stage = 1;
        endTime = block.timestamp + TOTAL_DURATION;
    }

    function enter(uint256 _amount) external {
        require(stage == 1, "Deposit not enabled");

        uint256 amount = _receivePKN(msg.sender, _amount);
        uint256 uDeposit = userDeposit[msg.sender];
        uint256 uTotal = uDeposit + amount;

        require(uTotal >= TIER_MIN, "Amount less than minimum deposit");

        (uint256 depA, uint256 depB, uint256 depC) = splitTiers(uDeposit);
        (uint256 totA, uint256 totB, uint256 totC) = splitTiers(uTotal);

        uint256 amtA = totA - depA;
        uint256 amtB = totB - depB;
        uint256 amtC = totC - depC;

        uint256 remainingTime = endTime - block.timestamp;
        uint256 owed;
        if(amtA > 0) {
            owed += amtA + amtA * REWARD_MIN * remainingTime / (100 * TOTAL_DURATION);
        }

        if(amtB > 0) {
            owed += amtB + amtB * REWARD_MID * remainingTime / (100 * TOTAL_DURATION);
        }

        if(amtC > 0) {
            owed += amtC + amtC * REWARD_MAX * remainingTime / (100 * TOTAL_DURATION);
        }

        userDeposit[msg.sender] += amount;
        totalDeposit += amount;
        userOwed[msg.sender] += owed;
        totalOwed += owed;
    }

    function leave() external {
        require(block.timestamp >= endTime, "Locking not completed yet");

        uint256 amount = userOwed[msg.sender];
        require(amount > 0, "No pending withdrawal");
        userOwed[msg.sender] = 0;
        totalOwed -= amount;
        PKN.transfer(msg.sender, amount);
    }

    function _receivePKN(address from, uint256 amount) internal returns (uint256) {
        uint256 balanceBefore = PKN.balanceOf(address(this));
        PKN.transferFrom(from, address(this), amount);
        return PKN.balanceOf(address(this)) - balanceBefore;
    }
}
