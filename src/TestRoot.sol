pragma ton-solidity >= 0.36.0;

import './Proposal.sol';

import "./interfaces/IClient.sol";
import './Glossary.sol';


contract SmvRoot is IClient {
    ProposalData public _ProposalData;
    ProposalSpecific public _specific;

    constructor() public {
        tvm.accept();
    }

    function onProposalDeploy(
        address addr,
        ProposalType proposalType,
        TvmCell specific
    ) external override {
        addr;
        proposalType;
        specific;
        msg.sender.transfer(0, false, 64);
    }

    function onProposalPassed(ProposalData ProposalData) external override {
        _ProposalData = ProposalData;
        TvmCell c = ProposalData.specific;
        _specific = c.toSlice().decode(ProposalSpecific);
        msg.sender.transfer(0, false, 64);
    }
}
