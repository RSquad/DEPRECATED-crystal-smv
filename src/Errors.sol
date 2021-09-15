pragma ton-solidity >= 0.47.0;

library Errors {
    uint16 constant INVALID_CALLER = 100;
    uint16 constant INVALID_VALUE = 101;

/* -------------------------------------------------------------------------- */
/*                                 200 Padawan                                */
/* -------------------------------------------------------------------------- */

    uint16 constant PADAWAN_NOT_ENOUGH_VOTES = 200;
    uint16 constant PADAWAN_INVALID_RETURN_ADDRESS = 201;

/* -------------------------------------------------------------------------- */
/*                                 300 Proposal                               */
/* -------------------------------------------------------------------------- */

    uint16 constant PROPOSAL_VOTING_NOT_STARTED = 300;
    uint16 constant PROPOSAL_VOTING_HAS_ENDED = 301;
}