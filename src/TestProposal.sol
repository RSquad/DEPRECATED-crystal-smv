pragma ton-solidity >= 0.47.0;

import "./resolvers/PadawanResolver.sol";

import "./interfaces/IPadawan.sol";
import "./interfaces/IProposal.sol";

contract TestProposal is PadawanResolver {

    constructor(
        string, // title,
        uint128, // totalVotes,
        address, // addrClient,
        string, // proposalType,
        TvmCell, // specific,
        TvmCell codePadawan
    ) public {
        tvm.accept();
        _codePadawan = codePadawan;
    }

    function vote(address _addrOwner, bool choice, uint128 votes) external {
        IPadawan(msg.sender).confirmVote
            {value: 0, flag: 64, bounce: true}
            (votes);
    }

    function queryStatus() external {
        IPadawan(msg.sender).queryStatusCb
            {value: 0, flag: 64, bounce: true}
            (ProposalState.Ended);
    }
}