// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract LastBidAuction is ReentrancyGuard {

    address public owner;
    uint fee = 5; // 5% fee on the winning bid
    uint public aucId;

    struct Auction {
        string name;
        address creator;
        uint startTime;
        uint addedTime;
        uint startPrice;
        uint currentPrice;
        bool isActive;
        address lastBidder;
    }

    mapping(uint => Auction) public auctions;

    event AuctionCreated(
        uint indexed aucId,
        string name,
        address indexed creator,
        uint startTime,
        uint addedTime,
        uint startPrice
    );

    event BidPlaced(
        uint indexed aucId,
        string name,
        address indexed bidder,
        uint bidAmount
    );

    event AuctionEnded(
        uint indexed aucId,
        string name,
        address indexed winner,
        uint winningBid
    );


    constructor() {
        owner = msg.sender;    
    }

    function createAuction() external {
        // Logic to create an auction
    }

    function changeFee(uint newFee) external onlyOwner {
        require(newFee <= 100, "Fee cannot exceed 100%");
        fee = newFee;
    }




}
