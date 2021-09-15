pragma ton-solidity >= 0.47.0;

import "./resolvers/PadawanResolver.sol";

contract TestSmvRoot is PadawanResolver {

    constructor(TvmCell codePadawan) public {
        tvm.accept();
        _codePadawan = codePadawan;
    }

    function deployPadawan(address addrOwner) external {
        TvmCell state = _buildPadawanState(address(this), addrOwner);
        new Padawan
            {stateInit: state, value: 1 ton}
            (address(0));
    }
}