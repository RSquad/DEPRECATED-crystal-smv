pragma ton-solidity >= 0.47.0;

import './IProposal.sol';

interface IClient {
    function onProposalNotPassed(ProposalData data, ProposalResults results) external;
    function onProposalPassed(ProposalData data, ProposalResults results) external;
    function onProposalDeployed(ProposalData data) external;
}