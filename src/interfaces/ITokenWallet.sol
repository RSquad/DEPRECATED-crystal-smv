pragma ton-solidity >= 0.43.0;

interface ITokenWallet {
    function transfer(address addrTokenWallet, uint128 amount) external;
    function recieve(uint128 amount, uint256 pubkeyOwner, address addrOwner) external;
    function burn(uint128 amount) external;
    function depositTokens(address addrPadawan, uint128 amount) external;
    function reclaimTokens(uint128 amount) external;
}

interface ITokenWalletCb {
    function depositTokensCb(uint128 amount) external;
}
