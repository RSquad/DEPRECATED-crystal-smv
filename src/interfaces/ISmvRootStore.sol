pragma ton-solidity >= 0.42.0;

enum ContractCode {
    Proposal,
    Padawan,
    Comment
}

enum ContractAddr {
    ProposalFactory
}

enum ContractAbi {
    ProposalFactory
}

interface ISmvRootStore {
    function setPadawanCode(TvmCell code) external;
    function setProposalCode(TvmCell code) external;
    function setCommentCode(TvmCell code) external;

    function setProposalFactoryAddr(address addr) external;

    function setProposalFactoryAbi(bytes strAbi) external;

    function queryCode(ContractCode kind) external;
    function queryAddr(ContractAddr kind) external;
    function queryAbi(ContractAbi kind) external;
}

interface ISmvRootStoreCb {
    function updateCode(ContractCode kind, TvmCell code) external;
    function updateAddr(ContractAddr kind, address addr) external;
    function updateAbi(ContractAbi kind, bytes strAbi) external;
}