pragma ton-solidity >= 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/ISmvRoot.sol';

struct RegularSpecific {
    uint32 duration;
    string description;
}

contract ProposalFactory {
    address _addrSmvRoot;

    string constant public _PROPOSAL_TYPES = "Regular";

    constructor(address addrSmvRoot) public {
        tvm.accept();
        _addrSmvRoot = addrSmvRoot;
    }

    function deployRegularProposal(
        address client,
        string title,
        string desc,
        address[] whiteList,
        RegularSpecific specific
    ) public {
        TvmBuilder b;
        b.store(specific);
        TvmCell cellSpecific = b.toCell();
        ISmvRoot(_addrSmvRoot).deployProposal
            {value: 0, flag: 64, bounce: true}
            (
                client,
                title,
                desc,
                1000000,
                whiteList,
                'Regular',
                cellSpecific
            );
    }
/* -------------------------------------------------------------------------- */
/*                              ANCHOR Getters                                */
/* -------------------------------------------------------------------------- */

    function getPublic() public returns (
        string PROPOSAL_TYPES
    ) {
        PROPOSAL_TYPES = _PROPOSAL_TYPES;
    }
}