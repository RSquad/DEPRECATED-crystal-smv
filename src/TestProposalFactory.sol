pragma ton-solidity >= 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/ISmvRoot.sol';

struct Specific {
    uint32 duration;
    string description;
}

contract ProposalFactory {
    address _addrSmvRoot;

    constructor(address addrSmvRoot) public {
        tvm.accept();
        _addrSmvRoot = addrSmvRoot;
    }

    function deployProposal(
        address client,
        string title,
        address[] whiteList,
        Specific specific
    ) public {
        TvmBuilder b;
        b.store(specific);
        TvmCell cellSpecific = b.toCell();
        ISmvRoot(_addrSmvRoot).deployProposal
            {value: 0, flag: 64, bounce: true}
            (
                client,
                title,
                1000,
                whiteList,
                'test',
                cellSpecific
            );
    }
}