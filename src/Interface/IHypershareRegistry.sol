
pragma solidity ^0.8.6;

interface IHypershareRegistry {

    event NonFractional(address indexed account, uint256 token);
    event Fractional(address indexed account, uint256 token);
    event HolderLimitSetTransfer(uint256 _transferHoolderLimit, uint256 _id);
    event HolderLimitSetIssuer(uint256 _transferHoolderLimit, uint256 _id);
    event MinimumShareholdingSet(uint256 id, uint256 minimumAmount);
    
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate, uint256 id);
    event DelegateVotesChanged(address indexed delegate, uint256 indexed id, uint256 previousBalance, uint256 newBalance);

    event RecoverySuccess(address lostWallet, address newWallet, address holderIdentity);
    event AddressFrozen(address indexed account, bool indexed isFrozen, address indexed owner);
    event SharesFrozen(address indexed account, uint256 amount);
    event SharesUnfrozen(address indexed account, uint256 amount);
    
    // Transfer functions
    function batchTransferred(address from, address to, uint256[] memory ids, uint256[] memory amounts) external returns (bool);
    function transferred(address from, address to, uint256 id, uint256 amount) external returns (bool);
    
    // Mint | Burn
    function mint(address to, uint256 id, uint256 amount) external;

    function burn(address account, uint256 id, uint256 amount) external;
    
    function updateShareholders(address account, uint256 id) external;
    function pruneShareholders(address account, uint256 id) external;
    
	function delegateTo(address delegatee, uint256 id) external payable;
    
    function freezeShares(address account, uint256 id, uint256 amount) external;
    function updateUnfrozenShares(address from, uint256 id, uint256 amount) external;
    function toggleAddressFrozenAll(address account, bool freeze) external;
    function toggleAddressFrozen(address account, uint256 id, bool freeze) external;
    function batchToggleAddressFrozen(address[] memory accounts, uint256[] memory ids, bool[] memory freeze) external;
    function batchFreezeShares(address[] memory accounts, uint256[] memory ids, uint256[] memory amounts) external;

    function getHolderAt(uint256 index, uint256 id) external view returns (address);
    function getShareholderLimitIssuer(uint256 id) external view returns (uint256);
    function getShareholderLimitTransfer(uint256 id) external view returns (uint256);
    function getShareholderCount(uint256 id) external view returns (uint256);
    function getShareholderCountByCountry(uint256 id, uint16 country) external view returns (uint256);
    function getShareholdingMinimum(uint256 id) external view returns (uint256);
    function getDelegates(address account, uint256 id) external view returns (address);
    function getCurrentVotes(address account, uint256 id) external view returns (uint256);
    function getPriorVotes(address account, uint256 id, uint256 timestamp) external view returns (uint256);
    function getFrozenShares(address account, uint256 id) external view returns (uint256);
    function getFrozenAccounts(address account, uint256 id) external view returns (bool);

    function checkCanTransferBatch(address from, address to, uint256[] memory ids, uint256[] memory amounts) external  view  returns (bool);
    function checkTransferWithinLimit(uint256 id) external returns (bool);
    function checkIsNonFractional(uint256 amount, uint256 id) external returns (bool);
    function checkIsNotFrozenAllTransfer(address from, address to) external returns (bool);
    function checkIsNotFrozenAccountsTransfer(uint256 id, address from, address to) external returns (bool);
    function checkIsNotFrozenSharesTransfer(uint256 amount, uint256 id, address from) external returns (bool);
    function checkFrozenAll(address account) external view returns (bool);

    function setShareholderLimitIssuer(uint256 holderLimit, uint256 id) external;
    function setShareholderLimitTransfer(uint256 holderLimit, uint256 id) external;
    function setShareholdingMinimum(uint256 id, uint256 minimumAmount) external;

    function setNonFractional(uint256 id) external;
}