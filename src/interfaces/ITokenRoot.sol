pragma ton-solidity >= 0.43.0;

struct TokenRootData {
    string name;
    string symbol;
    string icon;
    string desc;
    uint8 decimals;
    uint128 totalSupply;
}

interface ITokenRoot {
    function deployTokenWallet(
        uint256 pubkeyOwner,
        address addrOwner,
        uint128 initialAmount
    ) external;

    function burn(
        uint128 amount
    ) external;
}

interface ITokenRootCb {
    function deployTokenWalletCb(address addrTokenWallet) external;
    function getDataCb(TokenRootData tokenRootData) external;
}