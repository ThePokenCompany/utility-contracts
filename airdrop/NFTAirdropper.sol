// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTAirdropper is Ownable {
    struct Airdrop {
        address nft;
        uint id;
    }

    uint public nextAirdropId;
    uint public claimedAirdropId;
    mapping(uint => Airdrop) public airdrops;
    mapping(address => bool) public recipients;

    constructor() {}

    function sendAirdrops(Airdrop[] memory _airdrops, address[] memory _recipients) external onlyOwner() {
        require(_airdrops.length == _recipients.length, "Invalid input lengths");
        for(uint i = 0; i < _airdrops.length; i++) {
            IERC721(_airdrops[i].nft).transferFrom(msg.sender,  _recipients[i],  _airdrops[i].id);
        }
    }

    function addAirdrops(Airdrop[] memory _airdrops) external onlyOwner() {
        uint _nextAirdropId = nextAirdropId;
        for(uint i = 0; i < _airdrops.length; i++) {
            airdrops[_nextAirdropId] = _airdrops[i];
            IERC721(_airdrops[i].nft).transferFrom(msg.sender,  address(this),  _airdrops[i].id);
            _nextAirdropId++;
        }
        nextAirdropId = _nextAirdropId;
    }

    function addRecipients(address[] memory _recipients) external onlyOwner() {
        for(uint i = 0; i < _recipients.length; i++) {
            recipients[_recipients[i]] = true;
        }
    }

    function removeRecipients(address[] memory _recipients) external onlyOwner() {
        for(uint i = 0; i < _recipients.length; i++) {
            recipients[_recipients[i]] = false;
        }
    }

    function claim() external {
        require(recipients[msg.sender] == true, 'PKNAirdropNFT: recipient not added');
        recipients[msg.sender] = false;
        Airdrop storage airdrop = airdrops[claimedAirdropId];
        IERC721(airdrop.nft).transferFrom(address(this), msg.sender, airdrop.id);
        claimedAirdropId++;
    }
}
