import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// npx hardhat ignition verify votesbook-keeper


export default buildModule("VotesBookKeeperModule", (m) => {
    const votesBookKeeper = m.contract("VotesBookKeeper");
    return { votesBookKeeper };
});

