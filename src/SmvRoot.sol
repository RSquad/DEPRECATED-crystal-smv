pragma ton-solidity >= 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./Proposal.sol";
import "./SmvRootStore.sol";

import "./interfaces/IProposal.sol";
import "./interfaces/ISmvRoot.sol";
import "./interfaces/ISmvRootStore.sol";

import "./resolvers/PadawanResolver.sol";
import "./resolvers/ProposalResolver.sol";

import './Checks.sol';
import "./Errors.sol";
import "./Fees.sol";


contract SmvRoot is ISmvRoot, PadawanResolver, ProposalResolver, ISmvRootStoreCb, Checks {

/* -------------------------------------------------------------------------- */
/*                                ANCHOR Checks                               */
/* -------------------------------------------------------------------------- */

    uint8 constant CHECK_PROPOSAL = 1;
    uint8 constant CHECK_PADAWAN = 2;
    uint8 constant CHECK_ADDR_PROPOSAL_FACTORY = 4;
    uint8 constant CHECK_ABI_PROPOSAL_FACTORY = 8;

    function _createChecks() private inline {
        _checkList =
            CHECK_PROPOSAL |
            CHECK_PADAWAN |
            CHECK_ADDR_PROPOSAL_FACTORY |
            CHECK_ABI_PROPOSAL_FACTORY;
    }

/* -------------------------------------------------------------------------- */
/*                                 ANCHOR Init                                */
/* -------------------------------------------------------------------------- */

    string public _title;

    uint32 public _deployedPadawansCounter = 0;
    uint32 public _deployedProposalsCounter = 0;
    uint16 public _version = 4;

    address public _addrSmvStore;
    address public _addrProposalFactory;
    bytes public _abiProposalFactory;

    constructor(string title, address addrSmvStore) public {
        if (msg.sender == address(0)) {
            require(msg.pubkey() == tvm.pubkey(), 101);
            tvm.accept();
        }

        require(addrSmvStore != address(0));

        _title = title;
        
        _addrSmvStore = addrSmvStore;
        ISmvRootStore(_addrSmvStore).queryCode
            {value: 0.2 ton, bounce: true}
            (ContractCode.Proposal);
        ISmvRootStore(_addrSmvStore).queryCode
            {value: 0.2 ton, bounce: true}
            (ContractCode.Padawan);
        ISmvRootStore(_addrSmvStore).queryAddr
            {value: 0.2 ton, bounce: true}
            (ContractAddr.ProposalFactory);
        ISmvRootStore(_addrSmvStore).queryAbi
            {value: 0.2 ton, bounce: true}
            (ContractAbi.ProposalFactory);

        _createChecks();
    }

    bool public _inited = false;

    function _onInit() private {
        if(_isCheckListEmpty() && !_inited) {
            _inited = true;
        }
    }

    function updateCode(
        ContractCode kind,
        TvmCell code
    ) external override {
        require(msg.sender == _addrSmvStore, Errors.INVALID_CALLER);
        if (kind == ContractCode.Proposal) {
            _codeProposal = code;
            _passCheck(CHECK_PROPOSAL);
        } else if (kind == ContractCode.Padawan) {
            _codePadawan = code;
            _passCheck(CHECK_PADAWAN);
        }
        _onInit();
    }

    function updateAddr(ContractAddr kind, address addr) external override {
        require(msg.sender == _addrSmvStore, Errors.INVALID_CALLER);
        require(addr != address(0));
        if (kind == ContractAddr.ProposalFactory) {
            _addrProposalFactory = addr;
            _passCheck(CHECK_ADDR_PROPOSAL_FACTORY);
        }
        _onInit();
    }

    function updateAbi(ContractAbi kind, bytes strAbi) external override {
        require(msg.sender == _addrSmvStore, Errors.INVALID_CALLER);
        if (kind == ContractAbi.ProposalFactory) {
            _abiProposalFactory = strAbi;
            _passCheck(CHECK_ABI_PROPOSAL_FACTORY);
        }
        _onInit();
    }

/* -------------------------------------------------------------------------- */
/*                               ANCHOR Padawans                              */
/* -------------------------------------------------------------------------- */
    
    function deployPadawan(address addrOwner) external {
        require(msg.value >= Fees.DEPLOY_DEFAULT + 0.2 ton, Errors.INVALID_VALUE);
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        require(addrOwner != address(0));
        TvmCell state = _buildPadawanState(address(this), addrOwner);
        new Padawan
            {stateInit: state, value: Fees.DEPLOY_DEFAULT}
            (address(0));
        _deployedPadawansCounter += 1;

        // TODO
        // tvm.rawReserve(Fees.DEPLOY_DEFAULT, 4);
        // msg.sender.transfer(0, false, 128);
    }

/* -------------------------------------------------------------------------- */
/*                              ANCHOR Proposals                              */
/* -------------------------------------------------------------------------- */

    function deployProposal(
        address addrClient,
        string title,
        string desc,
        uint128 totalVotes,
        address[] addrsPadawan,
        string proposalType,
        TvmCell specific
    ) external override {
        require(msg.sender == _addrProposalFactory, Errors.INVALID_CALLER);
        require(msg.value >= Fees.DEPLOY_DEFAULT + 0.2 ton, Errors.INVALID_VALUE);
        TvmBuilder builder;
        builder.store(specific);
        TvmCell cellSpecific = builder.toCell();
        new Proposal {
                stateInit: _buildProposalState(address(this), _deployedProposalsCounter),
                value: Fees.DEPLOY_DEFAULT
            }(
                _addrSmvStore,
                title,
                desc,
                totalVotes,
                addrClient,
                proposalType,
                specific
            );
        _deployedProposalsCounter++;
    }

/* -------------------------------------------------------------------------- */
/*                              ANCHOR Getters                                */
/* -------------------------------------------------------------------------- */

    function getPublic() public returns (
        string title,
        uint32 deployedPadawansCounter,
        uint32 deployedProposalsCounter,
        uint16 version,
        address addrSmvStore,
        address addrProposalFactory,
        bytes abiProposalFactory,
        bool inited
    ) {
        title = _title;
        deployedPadawansCounter = _deployedPadawansCounter;
        deployedProposalsCounter = _deployedProposalsCounter;
        version = _version;
        addrSmvStore = _addrSmvStore;
        addrProposalFactory = _addrProposalFactory;
        abiProposalFactory = _abiProposalFactory;
        inited = _inited;
    }
}