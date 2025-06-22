// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract LastBidAuction is ReentrancyGuard, Ownable(msg.sender) {

    uint fee = 5; // 5% fee on the winning bid
    uint public aucId;

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
        require(_startprice > 0, "Start price must be positive");
        require(_addedtime > 0, "Auction duration must be positive");

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
        if (auc.lastbidtime + auc.addedTime <= block.timestamp) {
            endAuction(_aucId);
            return;
        }
        require(msg.sender != auc.creator, "Creator cannot bid on their own auction");
        require(msg.value > auc.currentPrice, "Bid must be higher than current price");

        // Refund the last bidder if there was one
        if (auc.lastBidder != address(0)) {
            (bool success, ) = auc.lastBidder.call{value: auc.currentPrice}("");
            require(success, "Refund failed");
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

    function endAuction(uint _aucId) public {
        Auction storage auc = auctions[_aucId];
        require(auc.isActive, "Auction already ended");
        require(block.timestamp >= auc.lastbidtime + auc.addedTime, "Auction not yet ended");

        auc.isActive = false;
        emit AuctionEnded(_aucId, auc.name, auc.lastBidder, auc.currentPrice, block.timestamp);

        if (auc.currentPrice > 0 && auc.creator != address(0)) {
            uint payout = auc.currentPrice - (auc.currentPrice * fee / 100);
            
            (bool success, ) = auc.creator.call{value: payout}("");
            require(success, "Payout failed");
        }
    }

    function changeFee(uint newFee) external onlyOwner {
        require(newFee <= 100, "Fee cannot exceed 100%");
        fee = newFee;
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        transferOwnership(newOwner);
    }


    function withdrawFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }



}
