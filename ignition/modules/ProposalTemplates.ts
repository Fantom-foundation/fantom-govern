import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// npx hardhat ignition deploy ./ignition/modules/ProposalTemplates.ts --network testnet --deployment-id proposal-templates

export default buildModule("ProposalTemplatesModule", (m) => {
    const proposalTemplates = m.contract("ProposalTemplates");
    return { proposalTemplates };
});

