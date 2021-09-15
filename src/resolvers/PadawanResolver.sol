pragma ton-solidity >= 0.36.0;
pragma AbiHeader expire;
pragma AbiHeader time;

import '../Padawan.sol';

contract PadawanResolver {
    TvmCell _codePadawan;

    function resolvePadawan(
        address addrRoot,
        address addrOwner
    ) public view returns (address addrPadawan) {
        TvmCell state = _buildPadawanState(addrRoot, addrOwner);
        uint256 hashState = tvm.hash(state);
        addrPadawan = address.makeAddrStd(0, hashState);
    }

    function _buildPadawanState(
        address addrRoot,
        address addrOwner
    ) internal view inline returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Padawan,
            varInit: {_addrOwner: addrOwner},
            code: _buildPadawanCode(addrRoot)
        });
    }

    function _buildPadawanCode(
        address addrRoot
    ) internal view inline returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrRoot);
        return tvm.setCodeSalt(_codePadawan, salt.toCell());
    }
}