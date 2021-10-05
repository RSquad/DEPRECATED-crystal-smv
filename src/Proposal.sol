pragma ton-solidity >= 0.36.0;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./resolvers/PadawanResolver.sol";
import "./resolvers/CommentResolver.sol";
import "./Checks.sol";

import "./interfaces/IClient.sol";
import "./interfaces/IProposal.sol";
import "./interfaces/IPadawan.sol";
import "./interfaces/ISmvRootStore.sol";

import "./Fees.sol";
import "./Errors.sol";

contract Proposal is PadawanResolver, CommentResolver, Checks, ISmvRootStoreCb, IProposal {

/* -------------------------------------------------------------------------- */
/*                                ANCHOR Checks                               */
/* -------------------------------------------------------------------------- */

    uint8 constant CHECK_PADAWAN = 1;
    uint8 constant CHECK_COMMENT = 2;

    function _createChecks() private inline {
        _checkList =
            CHECK_PADAWAN |
            CHECK_COMMENT;
    }

/* -------------------------------------------------------------------------- */
/*                                ANCHOR Init                                 */
/* -------------------------------------------------------------------------- */
    
    address public _addrRoot;
    address public _addrSmvStore;
    uint32 static public _id;
    
    ProposalData public _data;
    ProposalResults public _results;
    VoteCountModel public _voteCountModel;

    constructor(
        address addrSmvStore,
        string title,
        string desc,
        uint128 totalVotes,
        address addrClient,
        string proposalType,
        TvmCell specific
    ) public {
        optional(TvmCell) oSalt = tvm.codeSalt(tvm.code());
        require(oSalt.hasValue());
        (address addrRoot) = oSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot, Errors.INVALID_CALLER);
        
        _addrRoot = addrRoot;
        _addrSmvStore = addrSmvStore;

        _data.title = title;
        _data.desc = desc;
        _data.proposalType = proposalType;
        _data.specific = specific;
        _data.client = addrClient;
        _data.start = uint32(now);
        _data.end = uint32(now + 60 * 60 * 24 * 7);
        _data.state = ProposalState.New;
        _data.totalVotes = totalVotes;

        _voteCountModel = VoteCountModel.SoftMajority;

        ISmvRootStore(_addrSmvStore).queryCode
            {value: 0.2 ton, bounce: true}
            (ContractCode.Padawan);
        ISmvRootStore(_addrSmvStore).queryCode
            {value: 0.2 ton, bounce: true}
            (ContractCode.Comment);

        IClient(_data.client).onProposalDeployed
            {value: 0.2 ton}
            (_data);
    }

    bool public _inited = false;

    function _onInit() private {
        if(_isCheckListEmpty() && !_inited) {
            _inited = true;
            if(_data.start <= uint32(now)) {
                _data.state = ProposalState.OnVoting;
            }
        }
    }

    function updateCode(
        ContractCode kind,
        TvmCell code
    ) external override {
        require(msg.sender == _addrSmvStore, Errors.INVALID_CALLER);
        if (kind == ContractCode.Padawan) {
            _codePadawan = code;
            _passCheck(CHECK_PADAWAN);
        } else if (kind == ContractCode.Comment) {
            _codeComment = code;
            _passCheck(CHECK_COMMENT);
        }
        _onInit();
    }

    function updateAddr(ContractAddr kind, address addr) external override {}

    function updateAbi(ContractAbi kind, bytes strAbi) external override {}

    function wrapUp() external override {
        _wrapUp();
        msg.sender.transfer(0, false, 64);
    }

    function vote(
        address addrPadawanOwner,
        bool choice,
        uint128 votes
    ) external override {
        require(msg.value >= Fees.START + Fees.PROCESS, Errors.INVALID_VALUE);
        address addrPadawan = resolvePadawan(_addrRoot, addrPadawanOwner);
        uint16 errorCode = 0;

        if (addrPadawan != msg.sender) {
            errorCode = Errors.INVALID_CALLER;
        } else if (now < _data.start) {
            errorCode = Errors.PROPOSAL_VOTING_NOT_STARTED;
        } else if (now > _data.end) {
            errorCode = Errors.PROPOSAL_VOTING_HAS_ENDED;
        }

        if (errorCode > 0) {
            IPadawan(msg.sender).rejectVote{value: 0, flag: 64, bounce: true}(votes);
        } else {
            IPadawan(msg.sender).confirmVote{value: 0, flag: 64, bounce: true}(votes);
            if (choice) {
                _data.votesFor += votes;
            } else {
                _data.votesAgainst += votes;
            }
        }

        _wrapUp();
    }

    function _finalize(bool passed) private {
        _results = ProposalResults(
            true,
            passed,
            _data.votesFor,
            _data.votesAgainst,
            _data.totalVotes,
            _voteCountModel
        );

        ProposalState state = passed ? ProposalState.Passed : ProposalState.NotPassed;

        _changeState(state);

        if(passed) {
            IClient(_data.client).onProposalPassed
                {value: Fees.START}
                (_data, _results);
        } else {
            IClient(_data.client).onProposalNotPassed
                {value: Fees.PROCESS}
                (_data, _results);
        }
    }

    function _tryEarlyComplete(
        uint128 yes,
        uint128 no
    ) private view returns (bool, bool) {
        (bool completed, bool passed) = (false, false);
        if (yes * 2 > _data.totalVotes) {
            completed = true;
            passed = true;
        } else if(no * 2 >= _data.totalVotes) {
            completed = true;
            passed = false;
        }
        return (completed, passed);
    }

    function _wrapUp() private {
        (bool completed, bool passed) = (false, false);

        if (now > _data.end) {
            completed = true;
            passed = _calculateVotes(_data.votesFor, _data.votesAgainst);
        } else {
            (completed, passed) = _tryEarlyComplete(_data.votesFor, _data.votesAgainst);
        }

        if (completed) {
            _changeState(ProposalState.Ended);
            _finalize(passed);
        }
    }

    function _calculateVotes(
        uint128 yes,
        uint128 no
    ) private view returns (bool) {
        bool passed = false;
        passed = _softMajority(yes, no);
        return passed;
    }

    function _softMajority(
        uint128 yes,
        uint128 no
    ) private view returns (bool) {
        bool passed = false;
        passed = yes >= 1 + (_data.totalVotes / 10) + (no * ((_data.totalVotes / 2) - (_data.totalVotes / 10))) / (_data.totalVotes / 2);
        return passed;
    }

    function _changeState(ProposalState state) private inline {
        _data.state = state;
    }

    function queryStatus() external override {
        IPadawan(msg.sender).queryStatusCb{value: 0, flag: 64, bounce: true}(_data.state);
    }

/* -------------------------------------------------------------------------- */
/*                              ANCHOR Comments                               */
/* -------------------------------------------------------------------------- */

    uint32 _commentsCounter = 0;

    function addComment(address addrReply, string content) external {
        require(msg.value >= Fees.START, Errors.INVALID_VALUE);
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        TvmCell state = _buildCommentState(address(this), _commentsCounter);
        new Comment
            {stateInit: state, value: Fees.START - 0.2 ton}
            (msg.sender, addrReply, content);
        _commentsCounter += 1;
    }

}
