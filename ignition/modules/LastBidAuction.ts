import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LastBidAuctionModule = buildModule("LastBidAuctionModule", (m) => {
  const deployer = m.getAccount(0);

  const lastBidAuction = m.contract("LastBidAuction", [deployer]);

  return { lastBidAuction };
});

export default LastBidAuctionModule;