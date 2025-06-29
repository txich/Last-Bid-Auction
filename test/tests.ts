import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";

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

    


});