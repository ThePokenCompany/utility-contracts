// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

interface TokenMover {
    function transferERC20(address currency, address from, address to, uint256 amount) external;
}

contract PaymentContract is Ownable, AccessControlEnumerable {

    bytes32 public constant APP_ROLE = keccak256("APP_ROLE");
    
    TokenMover public immutable tokenMover;
    address public immutable PKN;

    address public feeRecipient;

    constructor(address _pkn, address _tokenMover, address _feeRecipient) {
        PKN = _pkn;
        tokenMover = TokenMover(_tokenMover);
        feeRecipient = _feeRecipient;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(APP_ROLE, msg.sender);
    }

    function pay(
        address buyer,
        address seller,
        address creator,
        uint256 amount,
        uint256 royaltyPercent,
        uint256 feesPercent
    ) external onlyRole(APP_ROLE) {
        uint256 creatorShare = amount * royaltyPercent / 10000;
        uint256 platformShare = amount * feesPercent / 10000;
        uint256 sellerShare = amount - creatorShare - platformShare;

        tokenMover.transferERC20(PKN, buyer, seller, sellerShare);
        tokenMover.transferERC20(PKN, buyer, creator, creatorShare);
        tokenMover.transferERC20(PKN, buyer, feeRecipient, platformShare);
    }

    function changeFeeRecipient(address _feeRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeRecipient = _feeRecipient;
    }
}
