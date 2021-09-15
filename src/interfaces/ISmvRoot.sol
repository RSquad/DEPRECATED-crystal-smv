pragma ton-solidity >= 0.47.0;

interface ISmvRoot {
    function deployProposal(
        address addrClient,
        string title,
        uint128 totalVotes,
        address[] addrsPadawan,
        string proposalType,
        TvmCell specific
    ) external;
}