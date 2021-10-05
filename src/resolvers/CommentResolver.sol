pragma ton-solidity >= 0.47.0;

import '../Comment.sol';

contract CommentResolver {
    TvmCell _codeComment;

    function resolveComment(address addrProposal, uint32 id) public view returns (address addrComment) {
        TvmCell state = _buildCommentState(addrProposal, id);
        uint256 hashState = tvm.hash(state);
        addrComment = address.makeAddrStd(0, hashState);
    }

    function resolveCommentCodeHash(address addrProposal) public view returns (uint256 codeHashComment) {
        TvmCell code = _buildCommentCode(addrProposal);
        codeHashComment = tvm.hash(code);
    }
    
    function _buildCommentState(address addrProposal, uint32 id) internal view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Comment,
            varInit: {_id: id},
            code: _buildCommentCode(addrProposal)
        });
    }

    function _buildCommentCode(
        address addrProposal
    ) internal view inline returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrProposal);
        return tvm.setCodeSalt(_codeComment, salt.toCell());
    }
}