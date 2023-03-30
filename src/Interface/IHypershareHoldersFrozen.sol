
pragma solidity ^0.8.6;

interface IHypershareHoldersFrozen {

    event RecoverySuccess(address lostWallet, address newWallet, address holderIdentity);
    event AddressFrozen(address indexed account, bool indexed isFrozen, address indexed owner);
    event SharesFrozen(address indexed account, uint256 amount);
    event SharesUnfrozen(address indexed account, uint256 amount);
    
    // Transfer functions
    function batchTransferred(address from, address to, uint256[] memory ids, uint256[] memory amounts) external returns (bool);
    function transferred(address from, address to, uint256 id, uint256 amount) external returns (bool);
    
    function toggleAddressFrozenAll(address account, bool freeze) external;
    function toggleAddressFrozen(address account, uint256 id, bool freeze) external;
    
    function batchToggleAddressFrozen(address[] memory accounts, uint256[] memory ids, bool[] memory freeze) external;
    function batchFreezeShares(address[] memory accounts, uint256[] memory ids, uint256[] memory amounts) external;
    
    function freezeShares(address account, uint256 id, uint256 amount) external;
    function updateUnfrozenShares(address from, uint256 id, uint256 amount) external;

    function checkIsNotFrozenAllTransfer(address from, address to) external returns (bool);
    function checkIsNotFrozenAccountsTransfer(uint256 id, address from, address to) external returns (bool);
    function checkIsNotFrozenSharesTransfer(uint256 amount, uint256 id, address from) external returns (bool);

    function checkCanTransfer(address to, address from, uint256 id, uint256 amount) external view returns (bool);
    function checkCanTransferBatch(address from, address to, uint256[] memory ids, uint256[] memory amounts) external  view  returns (bool);
    function checkFrozenAll(address account) external view returns (bool);

    function getShareholdingMinimum(uint256 id) external view returns (uint256);
    function getFrozenShares(address account, uint256 id) external view returns (uint256);
    function getFrozenAccounts(address account, uint256 id) external view returns (bool);

}