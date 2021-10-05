pragma ton-solidity >=0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/ISmvRootStore.sol';

import './Errors.sol';

contract SmvRootStore is ISmvRootStore {
    mapping(uint8 => address) public _addrs;
    mapping(uint8 => bytes) public _abis;
    mapping(uint8 => TvmCell) public _codes;

    function setPadawanCode(TvmCell code) public override {
        require(msg.pubkey() == tvm.pubkey(), Errors.INVALID_CALLER);
        tvm.accept();
        _codes[uint8(ContractCode.Padawan)] = code;
    }
    function setProposalCode(TvmCell code) public override {
        require(msg.pubkey() == tvm.pubkey(), Errors.INVALID_CALLER);
        tvm.accept();
        _codes[uint8(ContractCode.Proposal)] = code;
    }
    function setCommentCode(TvmCell code) public override {
        require(msg.pubkey() == tvm.pubkey(), Errors.INVALID_CALLER);
        tvm.accept();
        _codes[uint8(ContractCode.Comment)] = code;
    }

    function setProposalFactoryAddr(address addr) public override {
        require(msg.pubkey() == tvm.pubkey(), Errors.INVALID_CALLER);
        tvm.accept();
        _addrs[uint8(ContractAddr.ProposalFactory)] = addr;
    }

    function setProposalFactoryAbi(bytes strAbi) public override {
        require(msg.pubkey() == tvm.pubkey(), Errors.INVALID_CALLER);
        tvm.accept();
        _abis[uint8(ContractAbi.ProposalFactory)] = strAbi;
    }

    function queryCode(ContractCode kind) public override {
        TvmCell code = _codes[uint8(kind)];
        ISmvRootStoreCb(msg.sender).updateCode
            {value: 0, flag: 64, bounce: false}
            (kind, code);
    }
    
    function queryAddr(ContractAddr kind) public override {
        address addr = _addrs[uint8(kind)];
        ISmvRootStoreCb(msg.sender).updateAddr
            {value: 0, flag: 64, bounce: false}
            (kind, addr);
    }
    
    function queryAbi(ContractAbi kind) public override {
        bytes strAbi = _abis[uint8(kind)];
        ISmvRootStoreCb(msg.sender).updateAbi
            {value: 0, flag: 64, bounce: false}
            (kind, strAbi);
    }
}