// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract LastBidAuction is ReentrancyGuard, Ownable {

    constructor(address initialOwner) Ownable(initialOwner) {
    }

    uint public fee = 5; // 5% fee on the winning bid
    uint public aucId;
    uint public accumulatedFees;
    uint public minIncrement = 10; // Minimum increment for bids (1% of current price, 1 = 0.1%)

    struct Auction {
        string name;
        address creator;
        uint startTime;
        uint addedTime;
        uint lastbidtime;
        uint startPrice;
        uint currentPrice;
        bool isActive;
        address lastBidder;
    }

    mapping(uint => Auction) public auctions;

    mapping(address => uint) public userBalance;

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
        uint bidAmount,
        uint timestamp
    );

    event AuctionEnded(
        uint indexed aucId,
        string name,
        address indexed winner,
        uint winningBid,
        uint timestamp
    );

    function getAuction(uint _aucId) external view returns (
        string memory name,
        address creator,
        uint startTime,
        uint addedTime,
        uint lastbidtime,
        uint startPrice,
        uint currentPrice,
        bool isActive,
        address lastBidder
    ) {
        Auction storage auc = auctions[_aucId];
        return (
            auc.name,
            auc.creator,
            auc.startTime,
            auc.addedTime,
            auc.lastbidtime,
            auc.startPrice,
            auc.currentPrice,
            auc.isActive,
            auc.lastBidder
        );
    }

    function createAuction(string memory _name, uint _startprice, uint _addedtime) external {
        // Logic to create an auction
        require(_startprice > 0, "Start price must be greater than zero");
        require(_addedtime > 60, "Auction duration must be greater than 60 seconds");

        aucId++;
        auctions[aucId] = Auction({
            name: _name,
            creator: msg.sender,
            startTime: block.timestamp,
            addedTime: _addedtime,
            lastbidtime: block.timestamp,
            startPrice: _startprice,
            currentPrice: _startprice,
            isActive: true,
            lastBidder: address(0)
        });   
        emit AuctionCreated(aucId, _name, msg.sender, block.timestamp, _addedtime, _startprice);
    }

    function placeBid(uint _aucId) external payable nonReentrant {
        // Logic to place a bid
        Auction storage auc = auctions[_aucId];
        require(auc.isActive, "Auction is not active");
        require(block.timestamp < auc.lastbidtime + auc.addedTime, "Time is up for this auction");
        require(msg.sender != auc.creator, "Creator cannot bid on their own auction");
        require(msg.value > auc.currentPrice + auc.currentPrice * minIncrement / 1000 , 
        "Bid must be higher than current price at least by the minimum increment");

        // Refund the last bidder if there was one
        if (auc.lastBidder != address(0)) {
            userBalance[auc.lastBidder] += auc.currentPrice; // Refund last bidder
        }

        auc.lastBidder = msg.sender;
        auc.currentPrice = msg.value;
        auc.lastbidtime = block.timestamp;


        emit BidPlaced(
            _aucId,
            auc.name,
            msg.sender,
            msg.value,
            block.timestamp
        );
    }

    function endAuction(uint _aucId) public returns (string memory) {
        Auction storage auc = auctions[_aucId];
        require(auc.isActive, "Auction already ended");
        require(block.timestamp >= auc.lastbidtime + auc.addedTime, "Auction not yet ended");
        if (auc.lastBidder == address(0)) {
            auc.isActive = false;
            return("No bids were placed in this auction");
        }

        auc.isActive = false;
        emit AuctionEnded(_aucId, auc.name, auc.lastBidder, auc.currentPrice, block.timestamp);

        userBalance[auc.creator] += auc.currentPrice * (100 - fee) / 100; // Transfer winning amount to creator after fee
        accumulatedFees += auc.currentPrice * fee / 100; // Accumulate fees
        return("Auction ended successfully, funds transferred to creator");

    }

    function getUserBalance() external view returns (uint) {
        return userBalance[msg.sender];
    }

    function withdrawBalance(uint _amount) external nonReentrant {
        require(_amount > 0, "No balance to withdraw");
        require(_amount <= userBalance[msg.sender], "Insufficient balance");
        userBalance[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    function changeFee(uint newFee) external onlyOwner {
        require(newFee <= 50, "Fee cannot exceed 50%");
        fee = newFee;
    }

    function changeMinIncrement(uint newMinIncrement) external onlyOwner {
        require(newMinIncrement > 0, "Minimum increment must be positive");
        minIncrement = newMinIncrement;
    }

    function withdrawFees() external onlyOwner {
        require(accumulatedFees > 0, "No fees to withdraw");
        uint amount = accumulatedFees;
        accumulatedFees = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }



}
