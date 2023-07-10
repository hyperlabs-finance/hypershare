
pragma solidity ^0.8.6;

interface IHypershareRegistry {

  	////////////////
    // ERRORS
    ////////////////

    /**
     * @dev Only callable by the Hypershare contract.
     */
    error OnlyShareContract();
    
    /**
     * @dev Only callable by the Hypershare contract or the Owner.
     */
    error OnlyShareContractOrOwner();
    
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

    /**
     * @dev Added or updated the Hypershare contract
     */ 
    event UpdatedHypershare(address indexed share);

    /**
     * @dev Added or updated the Identity registry contract
     */ 
    event UpdatedHyperbaseIdentityregistry(address indexed tokenIdentity);

    //////////////////////////////////////////////
    // TRANSFER FUNCTIONS
    //////////////////////////////////////////////

    function batchTransferred(address from, address to, uint256[] memory tokenIds, uint256[] memory amounts) external returns (bool);
    function transferred(address from, address to, uint256 tokenId, uint256 amount) external returns (bool);
    
    //////////////////////////////////////////////
    // NEW TOKEN 
    //////////////////////////////////////////////
    
    function newToken(uint256 tokenId, uint256 shareholderLimit, uint256 shareholdingMinimum, bool shareholdingNonDivisible) external;

    //////////////////////////////////////////////
    // MINT | BURN 
    //////////////////////////////////////////////

    function mint(address to, uint256 tokenId, uint256 amount) external;
    function burn(address account, uint256 tokenId, uint256 amount) external;
    
    //////////////////////////////////////////////
    // UPDATES
    //////////////////////////////////////////////

    function updateShareholders(address account, uint256 tokenId) external;
    function pruneShareholders(address account, uint256 tokenId) external;
    
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
    
    function checkCanTransferBatch(address from, address to, uint256[] memory tokenIds, uint256[] memory amounts) external view returns (bool);
    function checkCanTransfer(address from, address to, uint256 tokenId, uint256 amount) external view returns (bool);
    function checkWithinShareholderLimit(uint256 tokenId) external view returns (bool);
    function checkAboveMinimumShareholdingTransfer(address from, address to, uint256 tokenId, uint256 amount) external view returns (bool);
    function checkAmountNonDivisibleTransfer(address from, address to, uint256 tokenId, uint256 amount) external view returns (bool);
    function checkNotFrozenAllTransfer(address from, address to) external view returns (bool);
    function checkNotFrozenTokenIdTransfer(address from, address to, uint256 tokenId) external view returns (bool);
    function checkNotFrozenSharesTransfer(address from, uint256 tokenId, uint256 amount) external view returns (bool);
    function checkFrozenAll(address account) external view returns (bool);
    function checkNonDivisible(uint256 tokenId) external view returns (bool);
    function checkAmountNonDivisible(uint256 amount) external pure returns (bool);
    function checkAboveMinimumShareholding(uint256 tokenId, uint256 amount) external  view  returns (bool);
    
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
    function getShareholderLimit(uint256 tokenId) external view returns (uint256);
    function getShareholderCount(uint256 tokenId) external view returns (uint256);
    function getShareholderCountByCountry(uint256 tokenId, uint16 country) external view returns (uint256);
    function getShareholdingMinimum(uint256 tokenId) external view returns (uint256);
    function getFrozenShares(address account, uint256 tokenId) external view returns (uint256);
    
}