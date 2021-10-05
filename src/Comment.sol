pragma ton-solidity >= 0.47.0;

pragma AbiHeader expire;
pragma AbiHeader time;

contract Comment {

/* -------------------------------------------------------------------------- */
/*                                 ANCHOR Init                                */
/* -------------------------------------------------------------------------- */

    address public _addrProposal;
    address public _addrAuthor;
    address public _addrReply;

    uint32 static public _id;
    uint32 public _createdAt;

    string public _content;

    constructor(
      address addrAuthor,
      address addrReply,
      string content
    ) public {
        optional(TvmCell) oSalt = tvm.codeSalt(tvm.code());
        require(oSalt.hasValue());
        (address addrProposal) = oSalt.get().toSlice().decode(address);
        require(msg.sender != address(0));
        require(msg.sender == addrProposal);

        _addrProposal = addrProposal;
        _addrAuthor = addrAuthor;
        _addrReply = addrReply;
        _createdAt = uint32(now);
        _content = content;
    }

/* -------------------------------------------------------------------------- */
/*                              ANCHOR Getters                                */
/* -------------------------------------------------------------------------- */

    function getPublic() public returns (
        address addrProposal,
        address addrAuthor,
        address addrReply,
        uint32 id,
        uint32 createdAt,
        string content
    ) {
        addrProposal = _addrProposal;
        addrAuthor = _addrAuthor;
        addrReply = _addrReply;
        createdAt = _createdAt;
        id = _id;
        content = _content;
    }
}