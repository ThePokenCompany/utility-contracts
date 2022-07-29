// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract PKNDistributor is AccessControl {

    IERC20 public immutable PKN;
    uint256 public totalAllocations;

    struct Allocation {
        uint256 startTime;
        uint256 amountPerDistribution;
        uint256 waitingDuration;
        uint256 frequency;
        uint256 amountClaimed;
        uint256 frequencyClaimed;
    }

    mapping (address => Allocation) public pknAllocations;

    event Allocated(
        address recipient,
        uint256 startTime,
        uint256 amountPerDistribution,
        uint256 waitingDuration,
        uint256 frequency);

    constructor(address pkn) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        PKN = IERC20(pkn);
    }

    function getAvailableAmount(address recipient) public view returns(uint256 frequencyAvailable, uint256 amountAvailable) {
        Allocation storage pknAllocation = pknAllocations[recipient];

        uint256 startTime = pknAllocation.startTime;
        uint256 frequency = pknAllocation.frequency;
        uint256 frequencyClaimed = pknAllocation.frequencyClaimed;
        uint256 amountPerDistribution = pknAllocation.amountPerDistribution;

        require(frequencyClaimed < frequency, "Allocation fully claimed");

        if (currentTime() < startTime) {
            return (0, 0);
        }

        uint256 elapsedFrequency = 1 + (currentTime() - startTime) / pknAllocation.waitingDuration;

        if(elapsedFrequency >= frequency) {
            uint256 remainingAmount = amountPerDistribution * frequency - pknAllocation.amountClaimed;
            return (frequency - frequencyClaimed, remainingAmount);
        }

        frequencyAvailable = elapsedFrequency - frequencyClaimed;
        amountAvailable = frequencyAvailable * amountPerDistribution;
    }

    function getAllocationDetails(address recipient) external view returns(Allocation memory) {
        return pknAllocations[recipient];
    }

    function currentTime() public view returns(uint256) {
        return block.timestamp;
    }

    function addAllocation(
        address[] calldata recipients,
        uint256[] calldata startTime,
        uint256[] calldata amountPerDistribution,
        uint256[] calldata waitingDuration,
        uint256[] calldata frequency
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = recipients.length;

        require(
            length == startTime.length && length == amountPerDistribution.length
            && length == waitingDuration.length && length == frequency.length,
            "Input length mismatch"
        );

        uint256 totalAmount;
        for (uint256 i = 0; i < length; i++) {
            totalAmount += amountPerDistribution[i] * frequency[i];
            _addAllocation(
                recipients[i],
                startTime[i],
                amountPerDistribution[i],
                waitingDuration[i],
                frequency[i]
            );
        }

        totalAllocations += length;
        require(_receivePKN(msg.sender, totalAmount) == totalAmount, "Recieved less PKN than transferred");
    }

    function resetAllocation(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Allocation storage pknAllocation = pknAllocations[recipient];

        uint256 amountPerDistribution = pknAllocation.amountPerDistribution;
        require(amountPerDistribution > 0, "No allocation available");

        uint256 amountRemaining = amountPerDistribution * (pknAllocation.frequency - pknAllocation.frequencyClaimed);
        delete pknAllocations[recipient];

        if(amountRemaining > 0) {
            PKN.transfer(msg.sender, amountRemaining);
        }
    }

    function releaseAvailableTokens() external {
        _releaseAvailableTokens(msg.sender);
    }

    function batchReleaseAvailableTokens(address[] calldata recipients) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            _releaseAvailableTokens(recipients[i]);
        }
    }

    // DOES NOT transfer PKN to the contract. Needs to be handled by the caller.
    function _addAllocation(
        address recipient,
        uint256 startTime,
        uint256 amountPerDistribution,
        uint256 waitingDuration,
        uint256 frequency
    ) internal {
        require(
            startTime > 0
            && amountPerDistribution > 0
            && waitingDuration > 0
            && frequency > 0,
            "Inputs must be more than 0"
        );
        require(pknAllocations[recipient].startTime == 0, "Allocation already exists");

        Allocation memory allocation = Allocation(
            startTime,
            amountPerDistribution,
            waitingDuration,
            frequency,
            0, //amountClaimed
            0  // frequency claimed
        );

        pknAllocations[recipient] = allocation;
        emit Allocated(recipient, startTime, amountPerDistribution, waitingDuration, frequency);
    }

    function _releaseAvailableTokens(address recipient) internal {
        (uint256 frequencyAvailable, uint256 amountAvailable) = getAvailableAmount(recipient);
        require(amountAvailable > 0, "Available amount is 0");

        Allocation storage pknAllocation = pknAllocations[recipient];
        pknAllocation.amountClaimed += amountAvailable;
        pknAllocation.frequencyClaimed += frequencyAvailable;

        PKN.transfer(recipient, amountAvailable);
    }

    function _receivePKN(address from, uint256 amount) internal returns(uint256) {
        uint256 balanceBefore = PKN.balanceOf(address(this));
        PKN.transferFrom(from, address(this), amount);
        uint256 balanceAfter = PKN.balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }
}
