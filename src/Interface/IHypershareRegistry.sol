// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHypercoreRegistry {

  	////////////////
    // ERRORS
    ////////////////
    
    /**
     * @dev Ids and amounts do not match.
     */
    error UnequalAmountsIds();

    /**
     * @dev Could not transfer.
     */
    error TransferFailed();

    /**
     * @dev Accounts, tokenIds and amounts length mismatch.
     */
    error UnequalAccountsAmountsIds();

    //////////////////////////////////////////////
    // TRANSFER FUNCTIONS
    //////////////////////////////////////////////

    function transferred(address from, address to, uint256 tokenId, uint256 amount) external returns (bool);
    
    //////////////////////////////////////////////
    // NEW TOKEN 
    //////////////////////////////////////////////
    
    function createToken(uint256 tokenId, uint256 shareholderLimit, uint256 shareholdingMinimum, bool shareholdingNonDivisible) external;

    //////////////////////////////////////////////
    // UPDATES
    //////////////////////////////////////////////

    function updateShareholders(address account, uint256 tokenId) external;
    function pruneShareholders(address account, uint256 tokenId) external;
    
    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    function setShare(address share) external;
    function setShareholderLimit(uint256 holderLimit, uint256 tokenId) external;
    function setShareholdingMinimum(uint256 tokenId, uint256 minimumAmount) external;
    function setNonDivisible(uint256 tokenId, bool nonDivisible) external;
    
    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    function getHolderAt(uint256 tokenId, uint256 index) external view returns (address);
    
}