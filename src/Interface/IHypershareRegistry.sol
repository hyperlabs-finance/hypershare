
pragma solidity ^0.8.6;

interface IHypershareRegistry {

  	////////////////
    // ERRORS
    ////////////////

    // Only callable by the Hypershare contract
    error OnlyShareContract();
    
    // Only callable by the Hypershare contract or the Owner
    error OnlyShareContractOrOwner();
    
    // Ids and amounts do not match
    error UnequalAmountsIds();

    // Could not transfer
    error TransferFailed();

    // Accounts, ids and amounts length mismatch
    error UnequalAccountsAmountsIds();

    // Amount exceeds available balance
    error ExceedsUnfrozenBalance();

    // Account is frozen
    error AccountFrozen();  

    // Share type is frozen on this account
    error FrozenSharesAccount();

    // Transfer exceeds shareholder limit
    error ExceedsMaximumShareholders();

    // Transfer results in shareholdings below minimum
    error BelowMinimumShareholding();

    // Transfer results in divisible shares
    error ShareDivision();

    // Shareholder doesn't exist
    error ShareholderNotExist();

    // Update to shareholder limit is less than the current amount of shareholders
    limitLessThanCurrentShareholders()

  	////////////////
    // EVENTS
    ////////////////

    // Change to divisible status of share
    event NonDivisible(uint256 indexed token, bool indexed nonDivisible);

    // The maximum number of shareholders has been updated
    event ShareholderLimitSet(uint256 holderLimit, uint256 id);

    // The minimum amount of shares per shareholder
    event MinimumShareholdingSet(uint256 id, uint256 minimumAmount);
    
    // The account has been frozen or unfrozen
    event UpdateFrozenAll(address indexed account, bool indexed freeze);

    // All transfers of share type have been frozen or unfrozen on account
    event UpdateFrozenShareType(address indexed account, uint256 indexed id, bool indexed freeze);

    // An amount of shares have been frozen on the account
    event SharesFrozen(address indexed account, uint256 indexed id, uint256 amount);

    // An amount of shares have been unfrozen on the account
    event SharesUnfrozen(address indexed account, uint256 indexed id, uint256 amount);

    //////////////////////////////////////////////
    // TRANSFER FUNCTIONS
    //////////////////////////////////////////////

    // Updates the shareholder registry to reflect a batch of transfers
    function batchTransferred(address from, address to, uint256[] memory ids, uint256[] memory amounts) external returns (bool);

    // Updates the shareholder registry to reflect a share transfer
    function transferred(address from, address to, uint256 id, uint256 amount) external returns (bool);
    
    //////////////////////////////////////////////
    // NEW TOKEN 
    //////////////////////////////////////////////
    
    // Bundles all the setters needed for token configuration into a single function for token creation
    function newToken(uint256 id, uint256 shareholderLimit, uint256 shareholdingMinimum, bool shareholdingNonDivisible) external;

    //////////////////////////////////////////////
    // MINT | BURN 
    //////////////////////////////////////////////

    // Bundles update functions into a single function for minting
    function mint(address to, uint256 id, uint256 amount) external;

    // Bundles update functions into a single function for burning
    function burn(address account, uint256 id, uint256 amount) external;
    
    //////////////////////////////////////////////
    // UPDATES
    //////////////////////////////////////////////

    // Adds a new shareholder and correpsonding details to the shareholder registry
    function updateShareholders(address account, uint256 id) external;

    // Rebuilds the shareholder registry and trims any shareholders who no longer have shares
    function pruneShareholders(address account, uint256 id) external;
    
    //////////////////////////////////////////////
    // FREEZE | UNFREEZE
    //////////////////////////////////////////////
    
    // Freeze a batch of accounts across all tokens
    function batchSetFrozenAll(address[] memory accounts, bool[] memory freeze) external;

    // Freeze a single account across all tokens
    function setFrozenAll(address account, bool freeze) external;
    
    // Freeze a batch of accounts from taking actions on a specific share type 
    function batchSetFrozenShareType(address[] memory accounts, uint256[] memory ids, bool[] memory freeze) external;

    // Freeze all actions for an account of a specific share type
    function setFrozenShareType(address account, uint256 id, bool freeze) external;

    // Freeze a specific amount of shares for a batch of accounts
    function batchFreezeShares(address[] memory accounts, uint256[] memory ids, uint256[] memory amounts) external;

    // Freeze a specific amount of share on an account
    function freezeShares(address account, uint256 id, uint256 amount) external;

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    // Check a batch of transfers are viable
    function checkCanTransferBatch(address from, address to, uint256[] memory ids, uint256[] memory amounts) external view returns (bool);

    // Check a transfer is viable and does not violate and transfer limitations
    function checkCanTransfer(address to, address from, uint256 id, uint256 amount) external view returns (bool);

    // Check that the transfer does not create an amount of shareholders that exceeds the shareholder limit
    function checkIsWithinShareholderLimit(uint256 id) external view returns (bool);

    // Check that the transfer does not result in shareholdings that fall below the minimum shareholding per investor for the share type 
    function checkIsAboveMinimumShareholdingTransfer(address to, address from, uint256 id, uint256 amount) external view returns (bool);

    // Check that the transfer does not in share divisions if the non-divisible shares are enforced on the share type
    function checkIsNonDivisibleTransfer(address to, address from, uint256 id, uint256 amount) external view returns (bool);

    // Check that the transfer does not result in taking actions from frozen accounts
    function checkIsNotFrozenAllTransfer(address from, address to) external view returns (bool);

    // Check that the transfer does not result in taking actions from accounts where the share type is frozen
    function checkIsNotFrozenShareTypeTransfer(uint256 id, address from, address to) external view returns (bool);

    // Check that the transfer does not transfer shares that are frozen
    function checkIsNotFrozenSharesTransfer(uint256 amount, uint256 id, address from) external view returns (bool);

    // Check if an account is frozen 
    function checkFrozenAll(address account) external view returns (bool);

    // Check share amount is a modulus of 1e18 
    function checkIsNonDivisible(uint256 amount) external pure returns (bool);

    // Check if an amount exceeds the minimum shareholding for a token
    function checkIsAboveMinimumShareholding(uint256 id, uint256 amount) external  view  returns (bool);
    
    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    // Sets the hypershare contract
    function setShare(address share) external;

    // Sets the maximum number of shareholders
    function setShareholderLimit(uint256 holderLimit, uint256 id) external;

    // Sets the minimum shareholding on transfers
    function setShareholdingMinimum(uint256 id, uint256 minimumAmount) external;

    // Toggle transfers that are not modulus zero e18
    function setNonDivisible(uint256 id) external;
    
    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    // Returns the address of a shareholder by their index in the shareholder registry
    function getHolderAt(uint256 index, uint256 id) external view returns (address);

    // Returns the maximum number of shareholders by token id
    function getShareholderLimit(uint256 id) external view returns (uint256);

    // Returns the current number of shareholders by token id
    function getShareholderCount(uint256 id) external view returns (uint256);

    // Returns the current number of shareholders by country
    function getShareholderCountByCountry(uint256 id, uint16 country) external view returns (uint256);

    // Returns the minimum shareholding for by token id
    function getShareholdingMinimum(uint256 id) external view returns (uint256);

    // Returns whether the token is non divisible or not by token id
    function getNonDivisible(uint256 id) external view returns (bool);

}