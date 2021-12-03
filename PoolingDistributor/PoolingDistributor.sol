// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract PoolingDistributor is Ownable {

    event NFTListUpdated(address indexed creator, uint256[] tokenIDs);
    event claimedReward(address user, uint256 indexed tokenId, uint256 reward);
    event distributionCreated(address indexed creator, uint256 totalReward);

    IERC20 public immutable PKN;
    IERC721Enumerable public immutable NFT;

    // Updated when:
    //  - a new tokenID is added to the contract
    //  - someone claims their rewards
    mapping(uint256 => uint256) private _tokenIDToRewardDebt;

    // Updated when:
    //  - a new tokenID is added to the contract
    //  - a tokenID is removed from the creator
    mapping(uint256 => address) private _tokenIDToCreator;

    // Updated when:
    //  - a new tokenID is added to the contract
    //  - a tokenID is removed from the creator
    mapping(address => uint256) private _creatorToNFTCount;

    // Updated when:
    //  - a new distribution is added for the creator
    mapping(address => uint256) private _creatorToAccPKNPerNFT;

    constructor(IERC20 _pkn, IERC721Enumerable _nft) {
        PKN = _pkn;
        NFT = _nft;
    }

    // View function to see pending PKN rewards for a given ID
    function amountPendingForID(uint256 tokenID) public view returns (uint256) {
        address creator = _tokenIDToCreator[tokenID];
        if(creator == address(0)) {
            return 0;
        }
        return _creatorToAccPKNPerNFT[creator] - _tokenIDToRewardDebt[tokenID];
    }

    // View function to see pending PKN rewards for a address
    function amountPendingForUser(address user) public view returns (uint256) {
        uint256 amount;
        uint256 balance = NFT.balanceOf(user);
        for (uint256 i = 0; i < balance; i++) {
            amount += amountPendingForID(NFT.tokenOfOwnerByIndex(user, i));
        }
        return amount;
    }

    function tokenIDToCreator(uint256 tokenID) external view returns (address) {
        return _tokenIDToCreator[tokenID];
    }

    function creatorToNFTCount(address creator) external view returns (uint256) {
        return _creatorToNFTCount[creator];
    }

    function addAllToNFTList(address[] calldata creators, uint256[][] calldata newIDs) external onlyOwner {
        uint256 lengthCreators = creators.length;
        uint256 lengthIDs = newIDs.length;
        require(lengthCreators == lengthIDs, "Input length mismatch");
        for (uint256 i = 0; i < lengthCreators; i++) {
            _addToNFTList(creators[i], newIDs[i]);
        }
    }

    function createDistribution(address[] calldata creators, uint256[] calldata amounts) external {

        require(creators.length == amounts.length, "Invalid input");

        uint256 amountTotal;
        uint256 reward;
        for (uint256 i = 0; i < creators.length; i++) {
            reward = amounts[i] / _creatorToNFTCount[creators[i]];
            require(reward > 0, "Amount too low");
            _creatorToAccPKNPerNFT[creators[i]] += reward;
            amountTotal += amounts[i];
            emit distributionCreated(creators[i], amounts[i]);
        }

        require(_receivePKN(msg.sender, amountTotal) == amountTotal, "Recieved less PKN than transferred");
    }

    function claim(uint256[] calldata tokenIDs) external {
        uint256 reward;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            require(NFT.ownerOf(tokenIDs[i]) == msg.sender, "Caller is not the owner of tokenID");
            reward += _setupClaim(msg.sender, tokenIDs[i]);
        }
        if(reward > 0) {
            PKN.transfer(msg.sender, reward);
        }
    }

    function _addToNFTList(address creator, uint256[] calldata newIDs) internal {
        uint256 length = newIDs.length;
        uint256 accPKNPerNFT = _creatorToAccPKNPerNFT[creator];

        for (uint256 i = 0; i < length; i++) {
            require(_tokenIDToCreator[newIDs[i]] == address(0), "Token ID already added");

            _tokenIDToCreator[newIDs[i]] = creator;
            _tokenIDToRewardDebt[newIDs[i]] = accPKNPerNFT;
        }

        _creatorToNFTCount[creator] += length;
        emit NFTListUpdated(creator, newIDs);
    }

    function _setupClaim(address user, uint256 tokenID) internal returns (uint256) {
        uint256 pending = amountPendingForID(tokenID);
        if(pending > 0) {
            address creator = _tokenIDToCreator[tokenID];
            _tokenIDToRewardDebt[tokenID] = _creatorToAccPKNPerNFT[creator];

            emit claimedReward(user, tokenID, pending);
        }
        return pending;
    }

    function _receivePKN(address from, uint256 amount) internal returns (uint256) {
        uint256 balanceBefore = PKN.balanceOf(address(this));
        PKN.transferFrom(from, address(this), amount);
        return PKN.balanceOf(address(this)) - balanceBefore;
    }
}
