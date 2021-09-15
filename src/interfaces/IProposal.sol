pragma ton-solidity >= 0.47.0;

struct ProposalResults {
    bool completed;
    bool passed;
    uint128 votesFor;
    uint128 votesAgainst;
    uint256 totalVotes;
    VoteCountModel model;
}

struct ProposalData {
    string title;
    string proposalType;
    TvmCell specific;
    address client;
    ProposalState state;
    uint32 start;
    uint32 end;
    uint128 votesFor;
    uint128 votesAgainst;
    uint128 totalVotes;
}

enum VoteCountModel {
    Undefined,
    Majority,
    SoftMajority,
    SuperMajority,
    Other,
    Reserved,
    Last
}

enum ProposalState {
    Undefined,
    New,
    OnVoting,
    Ended,
    Passed,
    NotPassed,
    Finalized,
    Distributed,
    Reserved,
    Last
}


interface IProposal {

    function vote(
        address addrPadawanOwner,
        bool choice,
        uint128 votes
    ) external;
    
    function queryStatus() external;
    function wrapUp() external;
}
