import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import ProposalTemplatesProxyModule from "./ProposalTemplatesProxy";
import VotesBookKeeperModule from "./VotesBookKeeper";

// npx hardhat ignition deploy ./ignition/modules/Governance.ts --network mainnet --deployment-id governance --parameters ignition/params.json


export default buildModule("GovernanceModule", (m) => {
    const { proposalTemplatesProxy } = m.useModule(ProposalTemplatesProxyModule);
    const { votesBookKeeper } = m.useModule(VotesBookKeeperModule);
    const owner = m.getParameter('owner');

    const governance = m.contract("Governance", [], {
        proxy: {
            methodName: "initialize",
            args: [owner],
            kind: "uups", // or "transparent" if using Transparent Proxy
        },
    });

    // initialize votesBookKeeper
    const maxProposalsPerVoter = m.getParameter('maxProposalsPerVoter');
    m.call(votesBookKeeper, 'initialize', [owner, governance, maxProposalsPerVoter])

    // initialize governance
    const governableContract = m.getParameter('sfcContract');
    m.call(governance, 'initialize', [governableContract, proposalTemplatesProxy, votesBookKeeper])

    // const networkProposalFactory = m.contract("NetworkParameterProposalFactory",
    //     [governance],);

    const plainTextProposalFactory = m.contract("PlainTextProposalFactory", [governance]);
    const slashingRefundProposalFactory = m.contract("SlashingRefundProposalFactory", [governance, governableContract]);


    return { proposalTemplatesProxy, votesBookKeeper, governance, plainTextProposalFactory, slashingRefundProposalFactory };
});

