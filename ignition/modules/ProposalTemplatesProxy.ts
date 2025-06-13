import {buildModule} from "@nomicfoundation/hardhat-ignition/modules";
import proposalTemplatesModule from "./ProposalTemplates";

// npx hardhat ignition deploy ./ignition/modules/ProposalTemplatesProxy.ts --network testnet --deployment-id proposal-templates-proxy --parameters ignition/params.json

export default buildModule("ProposalTemplatesProxyModule", (m) => {
    const { proposalTemplates } = m.useModule(proposalTemplatesModule);

    const owner = m.getParameter('owner');

    const proposalTemplatesProxy = m.contract('ERC1967Proxy', [
        proposalTemplates,
        m.encodeFunctionCall(proposalTemplates, 'initialize', [owner]),
    ]);

    return { proposalTemplatesProxy };
});

