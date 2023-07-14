// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHypercoreTransfers {

  	////////////////
    // ERRORS
    ////////////////
    
  	/**
     * @dev Transfer exceeds shareholder limit.
     */
    error ExceedsMaximumShareholders();

    /**
     * @dev Transfer results in shareholdings below minimum.
     */
    error BelowMinimumShareholding();

    /**
     * @dev Transfer results in divisible shares.
     */
    error ShareDivision();

    /**
     * @dev Update to shareholder limit is less than the current amount of shareholders.
     */
    error LimitLessThanCurrentShareholders();

  	////////////////
    // EVENTS
    ////////////////

    /**
     * @dev Change to divisible status of share
     */ 
    event NonDivisible(uint256 indexed tokenId, bool indexed nonDivisible);

    /**
     * @dev The maximum number of shareholders has been updated
     */ 
    event ShareholderLimitSet(uint256 indexed tokenId, uint256 holderLimit);

    /**
     * @dev The minimum amount of shares per shareholder
     */ 
    event MinimumShareholdingSet(uint256 indexed tokenId, uint256 minimumAmount);

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////
    
    function checkCanTransferBatch(address from, address to, uint256[] memory tokenIds, uint256[] memory amounts) external view returns (bool);
    function checkCanTransfer(address from, address to, uint256 tokenId, uint256 amount) external view returns (bool);
    function checkWithinShareholderLimit(uint256 tokenId) external view returns (bool);
    function checkAboveMinimumShareholdingTransfer(address from, address to, uint256 tokenId, uint256 amount) external view returns (bool);
    function checkAmountNonDivisibleTransfer(address from, address to, uint256 tokenId, uint256 amount) external view returns (bool);
    function checkNonDivisible(uint256 tokenId) external view returns (bool);
    function checkAmountNonDivisible(uint256 amount) external pure returns (bool);
    function checkAboveMinimumShareholding(uint256 tokenId, uint256 amount) external  view  returns (bool);
    
    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    function getHolderAt(uint256 tokenId, uint256 index) external view returns (address);
    function getShareholderLimit(uint256 tokenId) external view returns (uint256);
    function getShareholderCount(uint256 tokenId) external view returns (uint256);
    function getShareholderCountByCountry(uint256 tokenId, uint16 country) external view returns (uint256);
    function getShareholdingMinimum(uint256 tokenId) external view returns (uint256);
    function getFrozenShares(address account, uint256 tokenId) external view returns (uint256);
    
}