pragma ton-solidity >= 0.47.0;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IProposal.sol";
import "./interfaces/IPadawan.sol";

import "./Errors.sol";
import "./Fees.sol";

contract Padawan is IPadawan {
    address public _addrSmvRoot;
    address static public _addrOwner;

    mapping(address => uint128) public _proposals;
    uint128 public _proposalsCount;

    uint128 public _requestedVotes;
    uint128 public _totalVotes;
    uint128 public _lockedVotes;

    address _returnTo;

    constructor(address) public {
        optional(TvmCell) oSalt = tvm.codeSalt(tvm.code());
        require(oSalt.hasValue());
        (address addrSmvRoot) = oSalt.get().toSlice().decode(address);
        require(msg.sender == addrSmvRoot);
        _addrSmvRoot = addrSmvRoot;
    }

/* -------------------------------------------------------------------------- */
/*                                ANCHOR Voting                               */
/* -------------------------------------------------------------------------- */

    function vote(
        address addrProposal,
        bool choice,
        uint128 votes
    ) override external {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Fees.START, Errors.INVALID_VALUE);

        optional(uint128) oProposal = _proposals.fetch(addrProposal);
        uint128 proposalVotes = oProposal.hasValue() ? oProposal.get() : 0;
        uint128 availableVotes = _totalVotes - proposalVotes;
        require(votes <= availableVotes, Errors.PADAWAN_NOT_ENOUGH_VOTES);

        if(_proposals[addrProposal] == 0) {
            _proposalsCount += 1;
        }
        _proposals[addrProposal] += votes;
        
        IProposal(addrProposal).vote
            {value: 0, flag: 64, bounce: true}
            (_addrOwner, choice, votes);
    }

    function confirmVote(uint128 votes) override external {
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        optional(uint128) oProposal = _proposals.fetch(msg.sender);
        require(oProposal.hasValue(), Errors.INVALID_CALLER);
        
        _updateLockedVotes();

        _addrOwner.transfer(0, false, 64);
    }

    function rejectVote(uint128 votes) override external {
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        optional(uint128) oProposal = _proposals.fetch(msg.sender);
        require(oProposal.hasValue(), Errors.INVALID_CALLER);

        uint128 proposalVotes = oProposal.get() - votes;

        if (proposalVotes == 0) {
            _proposalsCount -= 1;
            delete _proposals[msg.sender];
        } else {
            _proposals[msg.sender] -= votes;
        }

        _addrOwner.transfer(0, false, 64);
    }

/* -------------------------------------------------------------------------- */
/*                               ANCHOR Deposits                              */
/* -------------------------------------------------------------------------- */

    function deposit(uint128 votes) external {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= votes * 1 ton + Fees.PROCESS_SM, Errors.INVALID_VALUE);

        tvm.rawReserve(votes * 1 ton, 4);
        _totalVotes += votes;
        _addrOwner.transfer(0, false, 128);
    }

    function reclaim(uint128 votes, address returnTo) external {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Fees.PROCESS * _proposalsCount + Fees.PROCESS_SM, Errors.INVALID_VALUE);
        require(returnTo != address(0), Errors.PADAWAN_INVALID_RETURN_ADDRESS);

        _returnTo = returnTo;
        _requestedVotes = votes;

        if (_requestedVotes <= _totalVotes - _lockedVotes) {
            _transferRequestedVotes();
        }

        _queryProposalStatuses();

        // TODO
        // tvm.rawReserve(_proposalsCount * Fees.PROCESS_SM, 5);
        // _addrOwner.transfer(0, false, 128);
    }

    function updateLockedVotes() external {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Fees.PROCESS * _proposalsCount + Fees.PROCESS_SM, Errors.INVALID_VALUE);
        _queryProposalStatuses();
    }

    function queryStatusCb(ProposalState state) external override {
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        optional(uint128) oProposal = _proposals.fetch(msg.sender);
        require(oProposal.hasValue(), Errors.INVALID_CALLER);

        if (state >= ProposalState.Ended) {
            if(_proposals[msg.sender] == _lockedVotes)
            delete _proposals[msg.sender];
            _updateLockedVotes();
        }

        if (_requestedVotes != 0 && _requestedVotes <= _totalVotes - _lockedVotes) {
            _transferRequestedVotes();
        }
        
        // TODO:
        // _addrOwner.transfer(0, false, 64);
    }

    function _transferRequestedVotes() private inline {
        _returnTo.transfer(_requestedVotes * 1 ton, false, 1);
        _totalVotes -= _requestedVotes;
        _requestedVotes = 0;
        _returnTo = address(0);
    }

    function _queryProposalStatuses() private inline {
        optional(address, uint128) oProposal = _proposals.min();
        while (oProposal.hasValue()) {
            (address addr,) = oProposal.get();
            IProposal(addr).queryStatus
                {value: Fees.PROCESS, bounce: false, flag: 1}
                ();
            oProposal = _proposals.next(addr);
        }
    }

    function _updateLockedVotes() private inline {
        optional(address, uint128) oProposal = _proposals.min();
        uint128 lockedVotes;
        while (oProposal.hasValue()) {
            (address addr, uint128 votes) = oProposal.get();
            if (votes > lockedVotes) {
                lockedVotes = votes;
            }
            oProposal = _proposals.next(addr);
        }
        _lockedVotes = lockedVotes;
    }

/* -------------------------------------------------------------------------- */
/*                              ANCHOR Getters                                */
/* -------------------------------------------------------------------------- */

    function getPublic() public returns (
        address addrSmvRoot,
        address addrOwner,
        mapping(address => uint128) proposals,
        uint128 proposalsCount,
        uint128 requestedVotes,
        uint128 totalVotes,
        uint128 lockedVotes
    ) {
        addrSmvRoot = _addrSmvRoot; 
        addrOwner = _addrOwner;
        proposals = _proposals;
        proposalsCount = _proposalsCount;
        requestedVotes = _requestedVotes;
        totalVotes = _totalVotes;
        lockedVotes = _lockedVotes;
    }
}
