pragma ton-solidity >= 0.42.0;

enum ContractCode {
    Proposal,
    Padawan
}

enum ContractAddr {
    ProposalFactory
}

interface ISmvRootStore {
    function setPadawanCode(TvmCell code) external;
    function setProposalCode(TvmCell code) external;

    function setProposalFactoryAddr(address addr) external;

    function queryCode(ContractCode kind) external;
    function queryAddr(ContractAddr kind) external;
}

interface ISmvRootStoreCb {
    function updateAddr(ContractAddr kind, address addr) external;
    function updateCode(ContractCode kind, TvmCell code) external;
}