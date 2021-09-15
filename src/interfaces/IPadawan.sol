pragma ton-solidity >= 0.47.0;

import "./IProposal.sol";

interface IPadawan {
    function vote(address addrProposal, bool choice, uint128 votes) external;
    function confirmVote(uint128 votes) external;
    function rejectVote(uint128 votes) external;
    function queryStatusCb(ProposalState state) external;
}
