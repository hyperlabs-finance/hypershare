// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHypercoreFreeze {

    /**
     * @dev Emitted when freeze is changed.
     */
    event UpdateFrozen(bool freeze);

    /**
     * @dev Amount exceeds available balance.
     */
    error ExceedsUnfrozenBalance();

    /**
     * @dev Account is frozen.
     */
    error AccountFrozen();  

    /**
     * @dev Share type is frozen on this account.
     */
    error FrozenSharesAccount();

    /**
     * @dev Accounts and freeze length mismatch.
     */
    error UnequalAccountsFreeze();

    /**
     * @dev Token tokenIds, accounts and freeze length mismatch.
     */
    error UnequalTokensAccountsFreeze();

  	////////////////
    // EVENTS
    ////////////////
	
    /**
     * @dev The account has been frozen or unfrozen
     */ 
    event UpdateFrozenAll(address indexed account, bool indexed freeze);

    /**
     * @dev All transfers of share type have been frozen or unfrozen on account
     */ 
    event UpdateFrozenTokenId(uint256 indexed tokenId, address indexed account, bool indexed freeze);

    /**
     * @dev An amount of shares have been frozen on the account
     */ 
    event SharesFrozen(uint256 indexed tokenId, address indexed account, uint256 amount);

    /**
     * @dev An amount of shares have been unfrozen on the account
     */ 
    event SharesUnfrozen(uint256 indexed tokenId, address indexed account, uint256 amount);

    //////////////////////////////////////////////
    // FREEZE | UNFREEZE
    //////////////////////////////////////////////
    
    function batchSetFrozenAll(address[] memory accounts, bool[] memory freeze) external;
    function setFrozenAll(address account, bool freeze) external;
    function batchSetFrozenTokenId(uint256[] memory tokenIds, address[] memory accounts, bool[] memory freeze) external;
    function setFrozenTokenId(uint256 tokenId, address account, bool freeze) external;
    function batchFreezeShares(uint256[] memory tokenIds, address[] memory accounts, uint256[] memory amounts) external;
    function freezeShares(uint256 tokenId, address account, uint256 amount) external;

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    function checkNotFrozenAllTransfer(address from, address to) external view returns (bool);
    function checkNotFrozenTokenIdTransfer(address from, address to, uint256 tokenId) external view returns (bool);
    function checkNotFrozenSharesTransfer(address from, uint256 tokenId, uint256 amount) external view returns (bool);
    function checkFrozenAll(address account) external view returns (bool);

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    function getFrozenShares(address account, uint256 tokenId) external view returns (uint256);
}