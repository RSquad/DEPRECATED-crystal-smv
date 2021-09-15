pragma ton-solidity >= 0.42.0;

interface IFaucet {
    function claimTokens(address addrTokenWallet) external;
    function getTotalDistributed() external;
    function changeBalance(
        address addr,
        uint256 pubkey,
        uint128 amount
    ) external returns (uint128);
    function deployWallet() external;
    function getBalance(address addr, uint256 pubkey) external returns (uint128 balance);
}

interface IFaucetCb {
    function getTotalDistributedCb(uint128 totalDistributed) external;
}
