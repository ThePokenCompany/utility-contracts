// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PKNVesting is Ownable {

    uint256 private constant ONE_MONTH = 30 days;
    uint256 public immutable START_TIME;
    uint256 public immutable DURATION_MONTHS;
    uint256 public totalAllocations;

    IERC20 public PKN;

    struct Allocation {
        uint256 amount;
        uint256 amountClaimed;
        uint256 monthsClaimed;
    }

    mapping (address => Allocation) public PKNAllocations;

    event AllocationAdded(address indexed recipient, uint256 amount);
    event AllocationReleased(address indexed recipient, uint256 amountClaimed);

    constructor(address _PKN, uint256 _startTime, uint256 _numOfMonths) {
        PKN = IERC20(_PKN);
        START_TIME = _startTime;
        DURATION_MONTHS = _numOfMonths;
    }

    function getVestedAmount(address _recipient) public view returns(uint256 monthsVested, uint256 amountVested) {
        Allocation storage PKNAllocation = PKNAllocations[_recipient];

        require(PKNAllocation.amountClaimed < PKNAllocation.amount, "Allocation fully claimed");

        if (_currentTime() < START_TIME) {
            return (0, 0);
        }

        uint256 elapsedMonths = 1 + (_currentTime() - START_TIME) / ONE_MONTH;

        if(elapsedMonths >= DURATION_MONTHS) {
            uint256 remainingAllocation = PKNAllocation.amount - PKNAllocation.amountClaimed;
            return (DURATION_MONTHS, remainingAllocation);
        }

        monthsVested = elapsedMonths - PKNAllocation.monthsClaimed;
        amountVested = monthsVested * (PKNAllocation.amount / DURATION_MONTHS);
    }

    function addAllocation(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        require(_recipients.length == _amounts.length, "Invalid input lengths");
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            totalAmount += _amounts[i];
            _addAllocation(_recipients[i], _amounts[i]);
        }
        totalAllocations += _recipients.length;
        require(_receivePKN(msg.sender, totalAmount) == totalAmount, "Recieved less PKN than transferred");
    }

    function releaseVestedTokens() external {
        _releaseVestedTokens(msg.sender);
    }

    function batchReleaseVestedTokens(address[] calldata _recipients) external {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _releaseVestedTokens(_recipients[i]);
        }
    }

    // DOES NOT transfer PKN to the contract. Needs to be handled by the caller.
    function _addAllocation(address _recipient, uint256 _amount) internal {
        require(PKNAllocations[_recipient].amount == 0, "Allocation already exists");
        require(_amount >= DURATION_MONTHS, "Amount too low");

        Allocation memory allocation = Allocation({
            amount: _amount,
            amountClaimed: 0,
            monthsClaimed: 0
        });
        PKNAllocations[_recipient] = allocation;
        emit AllocationAdded(_recipient, _amount);
    }

    function _releaseVestedTokens(address _recipient) internal {
        (uint256 monthsVested, uint256 amountVested) = getVestedAmount(_recipient);
        require(amountVested > 0, "Vested amount is 0");

        Allocation storage PKNAllocation = PKNAllocations[_recipient];
        PKNAllocation.monthsClaimed = PKNAllocation.monthsClaimed + monthsVested;
        PKNAllocation.amountClaimed = PKNAllocation.amountClaimed + amountVested;

        PKN.transfer(_recipient, amountVested);
        emit AllocationReleased(_recipient, amountVested);
    }

    function _receivePKN(address from, uint256 amount) internal returns(uint256) {
        uint256 balanceBefore = PKN.balanceOf(address(this));
        PKN.transferFrom(from, address(this), amount);
        uint256 balanceAfter = PKN.balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    function _currentTime() internal view returns(uint256) {
        return block.timestamp;
    }
}
