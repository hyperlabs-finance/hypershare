
pragma solidity ^0.8.6;

interface IHypershareHolders {

    event NonFractional(address indexed account, uint256 token);
    event Fractional(address indexed account, uint256 token);
    event HolderLimitSetTransfer(uint256 _transferHoolderLimit, uint256 _id);
    event HolderLimitSetIssuer(uint256 _transferHoolderLimit, uint256 _id);
    event MinimumShareholdingSet(uint256 id, uint256 minimumAmount);
    
    // Transfer functions
    function batchTransferred(address from, address to, uint256[] memory ids, uint256[] memory amounts) external returns (bool);
    function transferred(address from, address to, uint256 id, uint256 amount) external returns (bool);
    
    function updateShareholders(address account, uint256 id) external;
    function pruneShareholders(address account, uint256 id) external;
    function created(address to, uint256 id, uint256 amount) external;
    
    function getHolderAt(uint256 index, uint256 id) external view returns (address);
    function getShareholderLimitIssuer(uint256 id) external view returns (uint256);
    function getShareholderLimitTransfer(uint256 id) external view returns (uint256);
    function getShareholderCount(uint256 id) external view returns (uint256);
    function getShareholderCountByCountry(uint256 id, uint16 country) external view returns (uint256);
    function getShareholdingMinimum(uint256 id) external view returns (uint256);
    
    function checkCanTransferBatch(address from, address to, uint256[] memory ids, uint256[] memory amounts) external  view  returns (bool);
    function checkTransferWithinLimit(uint256 id) external returns (bool);
    function checkIsNonFractional(uint256 amount, uint256 id) external returns (bool);

    function setShareholderLimitIssuer(uint256 holderLimit, uint256 id) external;
    function setShareholderLimitTransfer(uint256 holderLimit, uint256 id) external;
    function setShareholdingMinimum(uint256 id, uint256 minimumAmount) external;

    function setNonFractional(uint256 id) external;

}