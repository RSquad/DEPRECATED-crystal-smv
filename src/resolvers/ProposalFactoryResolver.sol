pragma ton-solidity >= 0.42.0;

import '../ProposalFactory.sol';

contract ProposalFactoryResolver {
    TvmCell _codeProposalFactory;

    function resolveProposalFactory(address addrSmvRoot) public view returns (address addrProposalFactory) {
        TvmCell codeProposalFactory = _buildProposalFactoryCode(addrSmvRoot);
        TvmCell state = _buildProposalFactoryState(codeProposalFactory);
        uint256 hashState = tvm.hash(state);
        addrProposalFactory = address.makeAddrStd(0, hashState);
    }
    
    function _buildProposalFactoryState(TvmCell codeProposalFactory) internal view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: ProposalFactory,
            varInit: {},
            code: codeProposalFactory
        });
    }

    function _buildProposalFactoryCode(address addrSmvRoot) internal virtual view returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrSmvRoot);
        return tvm.setCodeSalt(_codeProposalFactory, salt.toCell());
    }
}