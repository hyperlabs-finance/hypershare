// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import './Hypercore.sol';
import '../interface/IHypercoreFreeze.sol';

/**

    HypercoreFreeze enforces transfer restrictions around frozen share contracts, 
    share classes, users, etc.

 */

contract HypercoreFreeze is Hypercore, IHypercoreFreeze  {

    ////////////////
    // STATES
    ////////////////
    
    /**
     * Bool frozen y/n all transactions across all tokens.
     */
    bool private _frozen;

    /**
     * Mapping from account address to bool for frozen y/n across all tokens.
     */
    mapping(address => bool) public _frozenByAccount;

    /**
     * Mapping from token ID to account address to bool for frozen y/n.
     */
    mapping(uint256 => mapping(address => bool)) public _frozenByAccountByToken;

    /**
     * Mapping from token ID to mapping from account address to uint amount of shares frozen.
     */
	mapping(uint256 => mapping(address => uint256)) public _frozenSharesByAccountByToken;

    ////////////////
    // MODIFIERS
    ////////////////
    
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
        if (_share.balanceOf(account, tokenId) <= (_frozenSharesByAccountByToken[tokenId][account] + amount))
            revert ExceedsUnfrozenBalance();
        _;
    }

    //////////////////////////////////////////////
    // TRANSFER FUNCTIONS
    //////////////////////////////////////////////

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
        returns (bool)
    {
        updateUnfrozenShares(from, tokenId, amount);
        return true;
    }

    //////////////////////////////////////////////
    // UPDATES
    //////////////////////////////////////////////

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
            uint256 freeBalance = _share.balanceOf(account, tokenId) - (_frozenSharesByAccountByToken[tokenId][account]);
            if (amount > freeBalance) {
                uint256 tokensToUnfreeze = amount - (freeBalance);
                _frozenSharesByAccountByToken[tokenId][account] = _frozenSharesByAccountByToken[tokenId][account] - (tokensToUnfreeze);
                emit SharesUnfrozen(tokenId, account, tokensToUnfreeze);
            }
        }
    }

    //////////////////////////////////////////////
    // FREEZE | UNFREEZE
    //////////////////////////////////////////////
 
    /**
     * @dev Freeze all transactions across all tokens.
     * @param freeze The booleans as to if the account should be frozen.
     */
    function setFrozen(
        bool freeze
    )
        public
    {
        // Mapping from account address to bool for frozen y/n across all tokens
        _frozen = freeze;

        // Events
        emit UpdateFrozen(freeze);
    }

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
    {
        // Mapping from account address to bool for frozen y/n across all tokens
        _frozenByAccount[account] = freeze;

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
    {
        _frozenByAccountByToken[tokenId][account] = freeze;

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
        sufficientUnfrozenShares(tokenId, account, amount)
    {
        _frozenSharesByAccountByToken[tokenId][account] = _frozenSharesByAccountByToken[tokenId][account] + (amount);

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
        if (checkFrozen())
            revert Frozen();

        if (!checkNotFrozenAllTransfer(from, to))
            revert AccountFrozen();

        if (!checkNotFrozenTokenIdTransfer(from, to, tokenId))
            revert FrozenSharesAccount();

        if (!checkNotFrozenSharesTransfer(from, tokenId, amount))
            revert ExceedsUnfrozenBalance();

        return true;
    }

    /**
     * @dev Returns true if the contract is frozen, and false otherwise.
     */
    function checkFrozen()
        public
        view
        virtual
        returns (bool)
    {
        return _frozen;
    }

    /**
     * @dev Returns boolean as to if the transfer does not result in taking actions from a frozen account.
     * @param from The transfering address. 
     * @param to The receiving address. 
     */
    function checkNotFrozenAllTransfer(
        address from,
        address to
    )
        public
        view
        returns (bool)
    {
        if (!_frozenByAccount[to] && !_frozenByAccount[from])
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
    function checkNotFrozenTokenIdTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        public
        view
        returns (bool)
    {
        if (!_frozenByAccountByToken[tokenId][to] && !_frozenByAccountByToken[tokenId][from])
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
    function checkNotFrozenSharesTransfer(
        address from,
        uint256 tokenId,
        uint256 amount
    )
        public
        view
        returns (bool)

    {
        if (from != address(0)) {
            if (amount <= (_share.balanceOf(from, tokenId) - _frozenSharesByAccountByToken[tokenId][from]))
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
        return _frozenByAccount[account];
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

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
        return _frozenSharesByAccountByToken[tokenId][account];
    }
   
}