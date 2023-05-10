// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import '../interface/IHypershareRegistry.sol';
import 'openzeppelin-contracts/contracts/access/Ownable.sol';

// Interfaces
import '../interface/IHyperbaseIdentityRegistry.sol';
import '../interface/IHypershare.sol';

/**

    HypershareRegistry keeps an on-chain record of the shareholders of its corresponding Hypershare
    contract. It then uses this record to enforce limit-based compliance checks, such as ensuring
    that a share transfer does not result in too many shareholders, fractional shareholdings or 
    that a shareholder has not been frozen by the owner-operator.

 */

contract HypershareRegistry is IHypershareRegistry, Ownable  {

    ////////////////
    // INTERFACES
    ////////////////

    /**
     * @dev The share contract instance.
     */ 
    IHypershare _share;

    /**
     * @dev The Hypershare identity registry.
     */ 
    IHyperbaseIdentityRegistry _identity;

    ////////////////
    // STATES
    ////////////////
	
    /**
     * Mapping from token ID to the addresses of all shareholders.
     */
    mapping(uint256 => address[]) public _shareholders;

    /**
     * Mapping from token ID to the index of each shareholder in the array `_shareholders`.
     */
    mapping(uint256 => mapping(address => uint256)) public _shareholderIndices;

    /**
     * Mapping from token ID to the amount of _shareholders per country.
     */
    mapping(uint256 => mapping(uint16 => uint256)) public _shareholderCountries;

    /**
     * Mapping from token ID to the limit on the amount of shareholders for this token, when transfering 
     * between holders.
     */
    mapping(uint256 => uint256) public _shareholderLimit;
    
    /**
     * Mapping from token ID to minimum share holding, transfers that result in holdings that fall bellow 
     * the mininmum will fail.
     */
    mapping(uint256 => uint256) public _shareholdingMinimum;
    
    /**
     * Mapping from token ID to non-divisible bool, transfers that result in divisible holdings will fail.
     */
    mapping(uint256 => bool) public _shareholdingNonDivisible;

    /**
     * Mapping from account address to bool for frozen y/n across all tokens.
     */
    mapping(address => bool) public _frozenAll;

    /**
     * Mapping from token ID to account address to bool for frozen y/n.
     */
    mapping(uint256 => mapping(address => bool)) public _frozenTokenId;

    /**
     * Mapping from token ID to mapping from account address to uint amount of shares frozen.
     */
	mapping(uint256 => mapping(address => uint256)) public _frozenShares;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        address share,
        address identities
    ) {
        setShare(share);
        setIdentities(identities);   
    }
        
    ////////////////
    // MODIFIERS
    ////////////////
    
    /**
     * @dev Ensures that only the hypershare contract can call this function.
     */
    modifier onlyShare() {
        if (msg.sender == address(_share))
            revert OnlyShareContract();
        _;
    }

    /**
     * @dev Ensures that only hypershare or owner can call this function.
     */
    modifier onlyShareOrOwner() {
        if (msg.sender == address(_share) || msg.sender == owner())
            revert OnlyShareContractOrOwner();
        _;
    }

    /**
     * @dev Ensures that ids and amounts are equal.
     * @param tokenIds An array of the token IDs.
     * @param amounts An array of the integer amounts.
     */
    modifier equalIdsAmounts(
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) {
        if (tokenIds.length != amounts.length)
           revert UnequalAmountsIds();    
        _;
    }

    /**
     * @dev Ensures that tokenIds, accounts and amounts are equal.
     * @param tokenIds An array of the token IDs. 
     * @param accounts An array of user addresses.
     * @param amounts An array of the integer amounts.
     */
    modifier equalIdsAccountsAmounts(
        uint256[] memory tokenIds,
        address[] memory accounts,
        uint256[] memory amounts
    ) {
        if (accounts.length != tokenIds.length && tokenIds.length != amounts.length)
            revert UnequalAccountsAmountsIds();   
        _;
    }

    /**
     * @dev Ensures that accounts and freeze are equal.
     * @param accounts An array of user addresses to freeze/unfreeze.
     * @param freeze An array of boolean as to if the account should be frozen. 
     */
    modifier equalAccountsFreeze(
        address[] memory accounts,
        bool[] memory freeze
    ) {
        if (accounts.length != freeze.length)
            revert UnequalAccountsFreeze();
        _;
    }

    /**
     * @dev Ensures that token IDs, accounts and freeze are equal. 
     * @param tokenIds An array of the token IDs to freeze/unfreeze users for. 
     * @param accounts An array of user addresses to freeze/unfreeze.
     * @param freeze An array of boolean as to if the account should be frozen. 
     */
    modifier equalTokensAccountsFreeze(
        uint256[] memory tokenIds,
        address[] memory accounts,
        bool[] memory freeze
    ) {
        if (tokenIds.length != accounts.length || accounts.length != freeze.length)
            revert UnequalTokensAccountsFreeze();
        _;
    }

    /**
     * @dev Ensures the account has sufficient unfrozen shares.
     * @param tokenId The token IDs for the transaction. 
     * @param account The user receiving addresskens to.
     * @param amount The integer amounts for the transfer.
     */
    modifier sufficientUnfrozenShares(
        uint256 tokenId,
        address account,
        uint256 amount
    ) {
        if (_share.balanceOf(account, tokenId) <= (_frozenShares[tokenId][account] + amount))
            revert ExceedsUnfrozenBalance();
        _;
    }

    /**
     * @dev Ensures that the new shareholder limit is not less than the current amount of shareholders.
     * @param holderLimit The maximum number of shareholders per token ID.
     * @param tokenId The token to enforce the holder limit on.
     */
    modifier notLessThanHolders(
        uint256 tokenId,
        uint256 holderLimit
    ) {
        if (holderLimit < _shareholders[tokenId].length)
            revert LimitLessThanCurrentShareholders();
        _;
    }

    //////////////////////////////////////////////
    // TRANSFER FUNCTIONS
    //////////////////////////////////////////////

    /**
     * @dev Updates the shareholder registry to reflect a batch of transfers.
     * @param from The sending address. 
     * @param to The receiving address.
     * @param tokenIds An array of token IDs to transfer between the addresses.
     * @param amounts An array of integer amounts for each token ID transfer in the batch.
     */
    function batchTransferred(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    )
        public
        onlyShare
        equalIdsAmounts(tokenIds, amounts)
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIds.length; i++)
            if (!transferred(from, to, tokenIds[i], amounts[i]))
                revert TransferFailed();
    
        return true;
    } 

    /**
     * @dev Updates the shareholder registry to reflect a share transfer.
     * @param from The sending address. 
     * @param to The receiving address.
     * @param tokenId The token ID for the token to be transfered.
     * @param amount The integer amount of tokens to be transfered.
     */
    function transferred(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        public
        onlyShare
        returns (bool)
    {
        updateShareholders(to, tokenId);
        pruneShareholders(from, tokenId);
        updateUnfrozenShares(from, tokenId, amount);

        return true;
    }

    //////////////////////////////////////////////
    // NEW TOKEN 
    //////////////////////////////////////////////
    
    /**
     * @dev Bundles all the setters needed for token configuration into a single function for token creation.
     * @param tokenId The token ID of the newly created token.
     * @param shareholderLimit The maximum number of shareholders for the newly created token.
     * @param shareholdingMinimum The minimum amount of shares per shareholder for the token.
     * @param shareholdingNonDivisible boolean as to if share transfers can result in fractional shares. 
     */
    function newToken(
        uint256 tokenId,
        uint256 shareholderLimit,
        uint256 shareholdingMinimum,
        bool shareholdingNonDivisible
    )
        public
        onlyShareOrOwner
    {
        setShareholderLimit(tokenId, shareholderLimit);   
        setShareholdingMinimum(tokenId, shareholdingMinimum);
        setNonDivisible(tokenId, shareholdingNonDivisible);
    }
    
    //////////////////////////////////////////////
    // MINT | BURN 
    //////////////////////////////////////////////

    /**
     * @dev Bundles update functions into a single function for minting.
     * @param to The address tokens are being minted to.
     * @param tokenId The token ID of the minted tokens.
     * @param amount The amount of tokens being minted to the address.
     */
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    )
        public
        onlyShare
    {
        updateShareholders(to, tokenId);
    }
    
    /**
     * @dev Bundles update functions into a single function for burning.
     * @param account The account to burn tokens from. 
     * @param tokenId The ID of the token that is being burnt.
     * @param amount The amount of tokens being burnt from the address.
     */
    function burn(
        address account,
        uint256 tokenId,
        uint256 amount
    )
        public
        onlyShare
    {
        updateUnfrozenShares(account, tokenId, amount); 
        pruneShareholders(account, tokenId);  
    }

    //////////////////////////////////////////////
    // UPDATES
    //////////////////////////////////////////////

    /**
     * @dev Adds a new shareholder and corresponding details to the shareholder registry.
     * @param account The address of the account to either add or update in the shareholder registry.
     * @param tokenId The token ID to add or update for the user. 
     */
    function updateShareholders(
        address account,
        uint256 tokenId
    )
        public
    {
        if (_shareholderIndices[tokenId][account] == 0) {
            _shareholders[tokenId].push(account);
            _shareholderIndices[tokenId][account] = _shareholders[tokenId].length;
            _shareholderCountries[tokenId][_identity.getCountryByAddress(account)]++;
        }
    }

    /**
     * @dev Rebuilds the shareholder registry and trims any shareholders who no longer have shares.
     * @param from The address of the user to remove from the shareholder registry.
     * @param tokenId The token ID in to prune the shareholder from.
     */
    function pruneShareholders(
        address from,
        uint256 tokenId
    )
        public
    {
        if (from != address(0) && _shareholderIndices[tokenId][from] != 0) {
            
            // If shareholder still has shares
            if (_share.balanceOf(from, tokenId) > 0)
                return;
        
            // Else trim the indicies
            uint256 holderIndex = _shareholderIndices[tokenId][from] - 1;
            uint256 lastIndex = _shareholders[tokenId].length - 1;
            address lastHolder = _shareholders[tokenId][lastIndex];
            _shareholders[tokenId][holderIndex] = lastHolder;
            _shareholderIndices[tokenId][lastHolder] = _shareholderIndices[tokenId][from];
            _shareholders[tokenId].pop();
            _shareholderIndices[tokenId][from] = 0;
            _shareholderCountries[tokenId][_identity.getCountryByAddress(from)]--;

        }
    }

    /**
     * @dev Update the unfrozen balance that is available to transfer post transfer.
     * @param account The account to freeze or unfreezen tokens on.
     * @param tokenId The ID of the token to freeze or unfreeze.
     * @param amount The amount of tokens to freeze or unfreeze.
     */
    function updateUnfrozenShares(
        address account,
        uint256 tokenId,
        uint256 amount
    )
        internal
    {
        if (account != address(0)) {
            uint256 freeBalance = _share.balanceOf(account, tokenId) - (_frozenShares[tokenId][account]);
            if (amount > freeBalance) {
                uint256 tokensToUnfreeze = amount - (freeBalance);
                _frozenShares[tokenId][account] = _frozenShares[tokenId][account] - (tokensToUnfreeze);
                emit SharesUnfrozen(tokenId, account, tokensToUnfreeze);
            }
        }
    }

    //////////////////////////////////////////////
    // FREEZE | UNFREEZE
    //////////////////////////////////////////////

    /**
     * @dev Set a batch of addresses to frozen across all tokens.
     * @param accounts An array of accounts to freeze/unfreeze.
     * @param freeze An array of booleans as to if the account should be frozen.
     */
    function batchSetFrozenAll(
        address[] memory accounts,
        bool[] memory freeze
    )
        public
        onlyShareOrOwner 
        equalAccountsFreeze(accounts, freeze)
    {
        for (uint256 i = 0; i < accounts.length; i++)
            setFrozenAll(accounts[i], freeze[i]);
    }

    /**
     * @dev Freeze a single account across all tokens.
     * @param account The account to freeze/unfreeze for all interactions.
     * @param freeze The booleans as to if the account should be frozen.
     */
    function setFrozenAll(
        address account,
        bool freeze
    )
        public
        onlyShareOrOwner 
    {
        // Mapping from account address to bool for frozen y/n across all tokens
        _frozenAll[account] = freeze;

        // Events
        emit UpdateFrozenAll(account, freeze);
    }

    /**
     * @dev Freeze a batch of accounts from taking actions on a specific share type.
     * @param tokenIds An array of the token IDs to freeze/unfreeze users for. 
     * @param accounts An array of user addresses to freeze/unfreeze.
     * @param freeze An array of booleans as to if the account should be frozen. 
     */
    function batchSetFrozenTokenId(
        uint256[] memory tokenIds,
        address[] memory accounts,
        bool[] memory freeze
    )
        public
        onlyShareOrOwner
        equalTokensAccountsFreeze(tokenIds, accounts, freeze)
    {
        for (uint256 i = 0; i < accounts.length; i++)
            setFrozenTokenId(tokenIds[i], accounts[i], freeze[i]);
    }
    
    /**
     * @dev Freeze all actions for an account of a specific share type.
     * @param tokenId The token ID to set account frozen/unfrozen.
     * @param account The user address to freeze/unfreeze.
     * @param freeze The boolean as to if the account should be frozen.
     */
    function setFrozenTokenId(
        uint256 tokenId,
        address account,
        bool freeze
    )
        public
        onlyShareOrOwner 
    {
        _frozenTokenId[tokenId][account] = freeze;

        // Event
        emit UpdateFrozenTokenId(tokenId, account, freeze);
    }

    /**
     * @dev Freeze a portion of shares for a batch of accounts.
     * @param tokenIds An array of the token IDs. 
     * @param accounts An array of user addresses.
     * @param amounts An array of the integer amounts of shares to be frozen for each address.
     */
    function batchFreezeShares(
        uint256[] memory tokenIds,
        address[] memory accounts,
        uint256[] memory amounts
    )
        public
        equalIdsAccountsAmounts(tokenIds, accounts, amounts)
    {
        for (uint256 i = 0; i < accounts.length; i++)
            freezeShares(tokenIds[i], accounts[i], amounts[i]);
    }

    /**
     * @dev Freeze a specific amount of shares on an account.
     * @param tokenId The token ID to freeze tokens for.
     * @param account The account to freeze tokens for.
     * @param amount The amount of tokens to freeze.
     */
    function freezeShares(
        uint256 tokenId,
        address account,
        uint256 amount
    )
        public
        onlyShareOrOwner
        sufficientUnfrozenShares(tokenId, account, amount)
    {
        _frozenShares[tokenId][account] = _frozenShares[tokenId][account] + (amount);

        // Event
        emit SharesFrozen(tokenId, account, amount);
    }

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    /**
     * @dev Returns boolean as to if a batch of transfers are viable and do not violate any transfer limits.
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param tokenIds An array of token IDs for the tokens to transfer.
     * @param amounts An array of integer amounts for each of the token IDs in the token transfer.
     */
    function checkCanTransferBatch(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    )
        public 
        view 
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIds.length; i++)
            checkCanTransfer(from, to, tokenIds[i], amounts[i]);
    
        return true;
    }
    
    /**
     * @dev Returns boolean as to if a transfer is viable and does not violate any transfer limits.
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param tokenId The ID of the token to transfer.
     * @param amount The amount of tokens to transfer.
     */
    function checkCanTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        public
        view
        returns (bool)
    {
        if (!checkIsNotFrozenAllTransfer(from, to))
            revert AccountFrozen();

        if (!checkIsNotFrozenTokenIdTransfer(from, to, tokenId))
            revert FrozenSharesAccount();

        if (!checkIsNotFrozenSharesTransfer(from, tokenId, amount))
            revert ExceedsUnfrozenBalance();

        if (!checkIsWithinShareholderLimit(tokenId))
            revert ExceedsMaximumShareholders();

        if (!checkIsAboveMinimumShareholdingTransfer(from, to, tokenId, amount))
            revert BelowMinimumShareholding();

        if (!checkIsNonDivisibleTransfer(from, to, tokenId, amount))
            revert ShareDivision();

        return true;
    }

    /**
     * @dev Returns boolean as to if the transfer does not create an amount of shareholders that exceeds
     * the shareholder limit.
     *
     * @param tokenId Token ID to check the shareholder limit against.
     */
    function checkIsWithinShareholderLimit(
        uint256 tokenId
    )
        public
        view
        returns (bool)
    {
        if (_shareholderLimit[tokenId] < _shareholders[tokenId].length + 1)
            return true;
        else 
            return false;
    }

    /**
     * @dev Returns boolean as to if the transfer does not result in shareholdings that fall below the minimum
     * shareholding per investor for the share type. 
     *
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param tokenId The ID of the token to transfer.
     * @param amount The amount of tokens to transfer
     */
    function checkIsAboveMinimumShareholdingTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        public
        view
        returns (bool)
    {   
        // Standard transfer
        if (from != address(0) && to != address(0)) 
            if (checkIsAboveMinimumShareholding(tokenId, _share.balanceOf(to, tokenId) - amount) && checkIsAboveMinimumShareholding(tokenId, _share.balanceOf(from, tokenId) + amount))
                return true;    
        // Mint
        else if (from == address(0) && to != address(0))
            if (checkIsAboveMinimumShareholding(tokenId, _share.balanceOf(to, tokenId) + amount))
                return true;
        // Burn
        else if (from != address(0) && to == address(0))
            if (checkIsAboveMinimumShareholding(tokenId, _share.balanceOf(from, tokenId) - amount))
                return true;
                
        return false;
    }

    /**
     * @dev Returns boolean as to if the transfer does not result in non-divisible shares if non-divisibility
     * is are enforced on the share type.
     *
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param tokenId The ID of the token to transfer.
     * @param amount The amount of tokens to transfer
     */
    function checkIsNonDivisibleTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        public
        view
        returns (bool)
    {   
        // If enforcing non-divisisibility
        if (_shareholdingNonDivisible[tokenId]) {
            // Standard transfer
            if (from != address(0) && to != address(0)) 
                if (checkIsNonDivisible(_share.balanceOf(to, tokenId) - amount) && checkIsNonDivisible(_share.balanceOf(from, tokenId) + amount))
                    return true;
                else
                    return false;    
            // Mint
            else if (from == address(0) && to != address(0))
                if (checkIsNonDivisible(_share.balanceOf(to, tokenId) + amount))
                    return true;
                else
                    return false;
            // Burn
            else if (from != address(0) && to == address(0))
                if (checkIsNonDivisible(_share.balanceOf(from, tokenId) - amount))
                    return true;
                else
                    return false;
            else 
                return false;
        }
        else
            return true;   
    }

    /**
     * @dev Returns boolean as to if the transfer does not result in taking actions from a frozen account.
     * @param from The transfering address. 
     * @param to The receiving address. 
     */
    function checkIsNotFrozenAllTransfer(
        address from,
        address to
    )
        public
        view
        returns (bool)
    {
        if (!_frozenAll[to] && !_frozenAll[from])
            return true;  
        else 
            return false;  
    }
    
    /**
     * @dev Returns boolean as to if the transfer does not result in taking actions from accounts where
     * the share type is frozen.
     *
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param tokenId The ID of the token to transfer.
     */
    function checkIsNotFrozenTokenIdTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        public
        view
        returns (bool)
    {
        if (!_frozenTokenId[tokenId][to] && !_frozenTokenId[tokenId][from])
            return true;  
        else
            return false;  
    }

    /**
     * @dev Returns boolean as to if the transfer attemp to transfer frozen shares.
     * @param from The transfering address. 
     * @param tokenId The ID of the token to transfer.
     * @param amount The amount of tokens to transfer
     */
    function checkIsNotFrozenSharesTransfer(
        address from,
        uint256 tokenId,
        uint256 amount
    )
        public
        view
        returns (bool)

    {
        if (from != address(0)) {
            if (amount <= (_share.balanceOf(from, tokenId) - _frozenShares[tokenId][from]))
                return true;  
            else
                return false;  
        }
        else 
            return true; 
    }

    /**
     * @dev Returns boolean as to if the account has been frozen across all tokens.
     * @param account The account address to check frozen status on. 
     */
    function checkFrozenAll(   
        address account
    )
        public
        view
        returns (bool)
    {
        return _frozenAll[account];
    }

    /**
     * @dev Returns boolean as to if the modulus of the transfer amount is equal to one (with the standard
     * eighteen decimal places).
     *
     * @param amount The amount of tokens to transfer
     */
    function checkIsNonDivisible(
        uint256 amount
    )
        public
        pure
        returns (bool)
    {
        if (amount % 10**18 == 0)
            return true;
        else    
            return false;
    }

    /**
     * @dev Returns boolean as to if the amount exceeds the minimum shareholding for the token.
     * @param tokenId The ID of the token to transfer.
     * @param amount The amount of tokens to transfer
     */
    function checkIsAboveMinimumShareholding(
        uint256 tokenId,
        uint256 amount
    )
        public
        view
        returns (bool)
    {
        if (_shareholdingMinimum[tokenId] <= amount)
            return true;   
        else
            return false;
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    /**
     * @dev Sets the hypershare contract.
     * @param share The address of the Hypershare contract.
     */
    function setShare(
        address share
    )
        public 
        onlyShareOrOwner
    {
        _share = IHypershare(share);

        // Event
        emit UpdatedHypershare(share);
    }

    /**
     * @dev Sets the identity registry contract.
     * @param identity The address of the HyperbaseIdentityRegsitry contract.
     */
    function setIdentities(
        address identity
    )
        public 
        onlyShareOrOwner
    {
        _identity = IHyperbaseIdentityRegistry(identity);

        // Event
        emit UpdatedHyperbaseIdentityregistry(identity);
    }

    /**
     * @dev Sets the maximum shareholder limit.
     * @param tokenId The token ID to set the holder limit on.
     * @param holderLimit The maximum number of shareholders.
     */
    function setShareholderLimit(
        uint256 tokenId, 
        uint256 holderLimit
    )
        public
        onlyShareOrOwner
        notLessThanHolders(tokenId, holderLimit)
    {
        // Set holder limit
        _shareholderLimit[tokenId] = holderLimit;

        // Event
        emit ShareholderLimitSet(tokenId, holderLimit);
    }
    
    /**
     * @dev Sets the minimum shareholding on transfers.
     * @param tokenId The token ID to set the minimum shareholding on.
     * @param minimumAmount The minimum amount of shares per shareholder.
     */
    function setShareholdingMinimum(
        uint256 tokenId,
        uint256 minimumAmount
    )
        public
        onlyShareOrOwner
    {
        // Set minimum
        _shareholdingMinimum[tokenId] = minimumAmount;

        // Event
        emit MinimumShareholdingSet(tokenId, minimumAmount);
    }

    /** 
     * @dev Set transfers that are not modulus zero e18. WARNING! It is extremely hard to reverse once it has been set to false.
     * @param tokenId The token ID to set the divisibility status on.
     * @param nonDivisible The boolean as to if the share type is divisible.
     */
    function setNonDivisible(
        uint256 tokenId,
        bool nonDivisible
    )
        public
        onlyShareOrOwner 
    {
        // Set divisibleity
        _shareholdingNonDivisible[tokenId] = nonDivisible;

        // Event
        emit NonDivisible(tokenId, nonDivisible);
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    /**
     * @dev Returns the address of shareholder by index.
     * @param tokenId The token ID to query.
     * @param index The shareholder index.
     */
    function getHolderAt(
        uint256 tokenId,
        uint256 index
    )
        public
        view
        returns (address)
    {
        return _shareholders[tokenId][index];
    }

    /**
     * @dev Returns the shareholder limit for investor transfers.
     * @param tokenId The token ID to query.
     */
    function getShareholderLimit(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        return _shareholderLimit[tokenId];
    }

    /**
     * @dev Returns the number of shareholders by country.
     * @param tokenId The token ID to query.
     * @param country The country to return number of shareholders for.
     */
    function getShareholderCountByCountry(
        uint256 tokenId,
        uint16 country
    )
        public
        view
        returns (uint256)
    {
        return _shareholderCountries[tokenId][country];
    }

    /**
     * @dev Returns the number of shareholders.
     * @param tokenId The token ID to query.
     */
    function getShareholderCount(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        return _shareholders[tokenId].length;
    }

    /**
     * @dev Returns the minimum shareholding.
     * @param tokenId The token ID to query.
     */
    function getShareholdingMinimum(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        return _shareholdingMinimum[tokenId];
    }

    /**
     * @dev Returns bool y/n share type is non-divisible. 
     * @param tokenId The token ID to query.
     */
    function getNonDivisible(
        uint256 tokenId
    )
        public
        view
        returns (bool)
    {
        return _shareholdingNonDivisible[tokenId];
    }

    /**
     * @dev Returns frozen shares of an account.
     * @param account The account to return number of frozen shares for.
     * @param tokenId The token ID to query.
     */
    function getFrozenShares(
        address account,
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        return _frozenShares[tokenId][account];
    }
   
}