
pragma solidity ^0.8.6;

interface IHypershareRegistry {

    function batchTransferred(address from, address to, uint256[] memory ids, uint256[] memory amounts) external returns (bool);
    function transferred(address from, address to, uint256 id, uint256 amount) external returns (bool);
    
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address account, uint256 id, uint256 amount) external;
    
    function newToken(uint256 id, uint256 shareholderLimit, uint256 shareholdingMinimum, bool shareholdingNonFractional) external;

    function updateShareholders(address account, uint256 id) external;
    function pruneShareholders(address account, uint256 id) external;
    
	function delegateTo(address from, address delegatee, uint256 id) external payable;
    
    function batchToggleAddressFrozenAll(address[] memory accounts, bool[] memory freeze) external;
    function toggleAddressFrozenAll(address account, bool freeze) external;
    
    function batchToggleAddressFrozen(address[] memory accounts, uint256[] memory ids, bool[] memory freeze) external;
    function toggleAddressFrozen(address account, uint256 id, bool freeze) external;

    function batchFreezeShares(address[] memory accounts, uint256[] memory ids, uint256[] memory amounts) external;
    function freezeShares(address account, uint256 id, uint256 amount) external;

    function getHolderAt(uint256 index, uint256 id) external view returns (address);
    function getShareholderLimit(uint256 id) external view returns (uint256);
    function getShareholderCount(uint256 id) external view returns (uint256);
    function getShareholderCountByCountry(uint256 id, uint16 country) external view returns (uint256);
    function getShareholdingMinimum(uint256 id) external view returns (uint256);
    function getNonFractional(uint256 id) external view returns (bool);
    function getDelegates(address account, uint256 id) external view returns (address);
    function getCurrentVotes(address account, uint256 id) external view returns (uint256);
    function getPriorVotes(address account, uint256 id, uint256 timestamp) external view returns (uint256);
    function getFrozenShares(address account, uint256 id) external view returns (uint256);
    function getFrozenAccounts(address account, uint256 id) external view returns (bool);

    function checkCanTransferBatch(address from, address to, uint256[] memory ids, uint256[] memory amounts) external view returns (bool);
    function checkCanTransfer(address to, address from, uint256 id, uint256 amount) external view returns (bool);
    function checkIsWithinShareholderLimit(uint256 id) external view returns (bool);
    function checkIsAboveMinimumShareholdingTransfer(address to, address from, uint256 id, uint256 amount) external view returns (bool);
    function checkIsNonFractionalTransfer(address to, address from, uint256 id, uint256 amount) external view returns (bool);
    function checkIsNotFrozenAllTransfer(address from, address to) external view returns (bool);
    function checkIsNotFrozenAccountsTransfer(uint256 id, address from, address to) external view returns (bool);
    function checkIsNotFrozenSharesTransfer(uint256 amount, uint256 id, address from) external view returns (bool);
    function checkFrozenAll(address account) external view returns (bool);
    function checkIsNonFractional(uint256 amount) external pure returns (bool);
    function checkIsAboveMinimumShareholding(uint256 id, uint256 amount) external  view  returns (bool);

    function setShare(address share) external;
    function setShareholderLimit(uint256 holderLimit, uint256 id) external;
    function setShareholdingMinimum(uint256 id, uint256 minimumAmount) external;

    function setNonFractional(uint256 id) external;
}