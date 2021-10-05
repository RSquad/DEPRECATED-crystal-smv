pragma ton-solidity >= 0.42.0;

import '../Proposal.sol';

contract ProposalResolver {
    TvmCell _codeProposal;

    function resolveProposal(address addrRoot, uint32 id) public view returns (address addrProposal) {
        TvmCell state = _buildProposalState(addrRoot, id);
        uint256 hashState = tvm.hash(state);
        addrProposal = address.makeAddrStd(0, hashState);
    }

    function resolveProposalCodeHash(address addrRoot) public view returns (uint256 codeHashProposal) {
        TvmCell code = _buildProposalCode(addrRoot);
        codeHashProposal = tvm.hash(code);
    }
    
    function _buildProposalState(address addrRoot, uint32 id) internal view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Proposal,
            varInit: {_id: id},
            code: _buildProposalCode(addrRoot)
        });
    }

    function _buildProposalCode(
        address addrRoot
    ) internal view inline returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrRoot);
        return tvm.setCodeSalt(_codeProposal, salt.toCell());
    }
}