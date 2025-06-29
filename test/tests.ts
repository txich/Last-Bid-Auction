import { ethers, network } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { Block, ZeroAddress } from "ethers";

describe("LastBidAuction", function () {
    async function deploy() {
        const [aucowner, seller, bidder1, bidder2, randwallet] = await ethers.getSigners();
        const Factory = await ethers.getContractFactory("LastBidAuction");
        const auction = await Factory.connect(aucowner).deploy(aucowner);
        await auction.waitForDeployment();

        return { auction, aucowner, seller, bidder1, bidder2, randwallet };
    };

    describe("Deployment", function () {

        it("Should deploy & set the right owner", async function () {

            const { auction, aucowner } = await loadFixture(deploy);

            expect(await auction.getAddress()).to.be.properAddress;
            expect(await auction.owner()).to.equal(aucowner.address);
        });


        it("Should have initial accumulated fees as zero", async function () {

            const { auction } = await loadFixture(deploy);

            expect(await auction.accumulatedFees()).to.equal(0);
        });
    });

    describe("Auction Creation", function () {
        it("Should create an auction with correct parameters", async function () {

            const { auction, seller } = await loadFixture(deploy);

            const tx = await auction.connect(seller).createAuction("Test Item", 100, 3600);
            await expect(tx)
                .to.emit(auction, "AuctionCreated")
                .withArgs(1, "Test Item", seller.address, anyValue, 3600, 100);

            const auc = await auction.auctions(1);
            expect(auc.creator).to.equal(seller.address);
            expect(auc.name).to.equal("Test Item");
            expect(auc.startTime).to.be.a("bigint");
            expect(auc.addedTime).to.be.above(0);
            expect(auc.currentPrice).to.equal(100);
            expect(auc.startPrice).to.equal(100);
            expect(auc.isActive).to.equal(true);
            expect(auc.lastBidder).to.equal(ZeroAddress);
            expect(await auction.aucId()).to.equal(1);
        });


        it("Should not allow creating an auction with zero price", async function () {

            const { auction, seller } = await loadFixture(deploy);

            await expect(auction.connect(seller).createAuction("Test Item", 0, 3600))
                .to.be.revertedWith("Start price must be greater than zero");
        });


        it("Should not allow creating an auction with duration < 60s", async function () {

            const { auction, seller } = await loadFixture(deploy);

            await expect(auction.connect(seller).createAuction("Test Item", 100, 59))
                .to.be.revertedWith("Auction duration must be greater than 60 seconds");
        });

    });
    
    describe("Bidding", function () {
        it("Should allow bidding and update auction state", async function () {

            const { auction, seller, bidder1 } = await loadFixture(deploy);

            await auction.connect(seller).createAuction("Test Item", 100, 3600);
            await network.provider.send("evm_increaseTime", [1800]); // 30 minutes
            await network.provider.send("evm_mine");

            const tx = await auction.connect(bidder1).placeBid(1, { value: 150 });
            const receipt = await tx.wait();
            const block = await ethers.provider.getBlock(receipt!.blockNumber);

            await expect(tx)
                .to.emit(auction, "BidPlaced")
                .withArgs(1, "Test Item", bidder1.address, 150, anyValue);

            const auc = await auction.auctions(1);
            expect(auc.currentPrice).to.equal(150);
            expect(auc.lastBidder).to.equal(bidder1.address);
            expect(auc.isActive).to.equal(true);
            expect(auc.lastbidtime).to.be.equal(block!.timestamp);
        });


        it("Should not allow bidding on non-existent auction", async function () {

            const { auction, bidder1 } = await loadFixture(deploy);

            await expect(auction.connect(bidder1).placeBid(999, { value: 150 }))
                .to.be.revertedWith("Auction is not active");
        });


        it("Should not allow bidding on ended auction", async function () {

            const { auction, seller, bidder1 } = await loadFixture(deploy);

            await auction.connect(seller).createAuction("Test Item", 100, 3600);
            await network.provider.send("evm_increaseTime", [3800]); // 1 hour
            await network.provider.send("evm_mine");

            await auction.connect(seller).endAuction(1);

            const auc = await auction.auctions(1);

            expect(auc.isActive).to.equal(false);

            await expect(auction.connect(bidder1).placeBid(1, { value: 150 }))
                .to.be.revertedWith("Auction is not active");
        });


        it("Should not allow bidding when the time is up", async function () {

            const { auction, seller, bidder1 } = await loadFixture(deploy);

            await auction.connect(seller).createAuction("Test Item", 100, 3600);
            await network.provider.send("evm_increaseTime", [3700]); // 1 hour and 40 seconds
            await network.provider.send("evm_mine");

            await expect(auction.connect(bidder1).placeBid(1, { value: 150 }))
                .to.be.revertedWith("Time is up for this auction");
        });
        

        it("Should not allow bidding on your own auction", async function () {
            const { auction, seller } = await loadFixture(deploy);

            await auction.connect(seller).createAuction("Test Item", 100, 3600);

            await expect(auction.connect(seller).placeBid(1, { value: 150 }))
                .to.be.revertedWith("Creator cannot bid on their own auction");
        });

        it("Should not allow bidding below minimum increment", async function () {

            const { auction, seller, bidder1, bidder2 } = await loadFixture(deploy);

            await auction.connect(seller).createAuction("Test Item", 100, 3600);
            await auction.connect(bidder1).placeBid(1, { value: 150 });

            await expect(auction.connect(bidder2).placeBid(1, { value: 151 }))
                .to.be.revertedWith("Bid must be higher than current price at least by the minimum increment");
        });

        it("Should refund previous bidder when a new bid is placed", async function () {
            const { auction, seller, bidder1, bidder2 } = await loadFixture(deploy);

            await auction.connect(seller).createAuction("Test Item", ethers.parseEther("1"), 3600);
            const initialBidder1Balance = await ethers.provider.getBalance(bidder1.address);

            await auction.connect(bidder1).placeBid(1, { value: ethers.parseEther("10") });
            await auction.connect(bidder2).placeBid(1, { value: ethers.parseEther("100") });

            expect(await auction.userBalance(bidder1.address)).to.equal(ethers.parseEther("10"));

            const auc = await auction.auctions(1);
            expect(auc.currentPrice).to.equal(ethers.parseEther("100"));
            expect(auc.lastBidder).to.equal(bidder2.address);
        });
    });

    describe("Auction Ending", function () {

        it("Should allow to end an auction", async function () {

            const { auction, seller, bidder1, randwallet } = await loadFixture(deploy);

            await auction.connect(seller).createAuction("Test Item", 10000, 3600);
            await auction.connect(bidder1).placeBid(1, { value: 15000 });

            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");

            const tx = await auction.connect(randwallet).endAuction(1);

            const auc = await auction.auctions(1);

            await expect(tx)
                .to.emit(auction, "AuctionEnded")
                .withArgs(1, "Test Item", anyValue, auc.currentPrice, anyValue);

            expect(auc.isActive).to.equal(false);

            expect(await auction.userBalance(seller.address)).to.equal(BigInt(15000 * 95 / 100));
            expect(await auction.accumulatedFees()).to.equal(BigInt(15000 * 5 / 100));
        });


        it("Should not allow ending an auction twice", async function () {

            const { auction, seller, bidder1 } = await loadFixture(deploy);

            await auction.connect(seller).createAuction("Test Item", 100, 3600);
            await auction.connect(bidder1).placeBid(1, { value: 150 });

            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");

            await auction.connect(seller).endAuction(1);

            await expect(auction.connect(seller).endAuction(1))
                .to.be.revertedWith("Auction already ended");
        });


        it("Should not allow ending an auction that has not yet ended", async function () {

            const { auction, seller } = await loadFixture(deploy);

            await auction.connect(seller).createAuction("Test Item", 100, 3600);

            await expect(auction.connect(seller).endAuction(1))
                .to.be.revertedWith("Auction not yet ended");
        });

        it("Should not increase seller balance after ending an auction with no bids", async function () {

            const { auction, seller } = await loadFixture(deploy);

            await auction.connect(seller).createAuction("Test Item", 100, 3600);

            await network.provider.send("evm_increaseTime", [3800]);
            await network.provider.send("evm_mine");

            

            const initialBalance = await auction.userBalance(seller.address);
            const tx = await auction.connect(seller).endAuction(1);
            await tx.wait();

            const auc = await auction.auctions(1);
            expect(auc.isActive).to.equal(false);

            expect(await auction.userBalance(seller.address)).to.equal(initialBalance);
        });

    });


});