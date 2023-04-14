// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inheriting
import '../Interface/IHypershare.sol';
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

// Calling interfaces
import '../Interface/IHypershareCompliance.sol';
import '../Interface/IHypershareRegistry.sol';

// #TODO: burn and reissue

contract Hypershare is IHypershare, ERC1155, ERC1155Pausable, Ownable {

    ////////////////
    // INTERFACES
    ////////////////

    // The compliance claims checker
    IHypershareCompliance public _compliance;

    // External registry of shareholders, delegates and frozen accounts / shares
    IHypershareRegistry public _registry;

    ////////////////
    // STATE
    ////////////////

    // Total tokens, incremented value used for token id
    uint256 _totalTokens;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
		string memory uri_,
        address compliance,
        address registry
    )
        // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
        ERC1155(uri_)
    {
        // Set compliance
        setCompliance(compliance);

    	// Set registry
	    setRegistry(registry);
    }

    ////////////////
    // MODIFIERS
    ////////////////

    modifier transferToZeroAddress(address to) {
        if (to == address(0))
            revert TransferToZeroAddress();
        _;
    }

    modifier sufficientTokens(
        address from,
        uint256 id,
        uint256 amount
    ) {
        if (from != address(0))
            if (balanceOf(from, id) <= amount)
                revert InsufficientTokens();
        _;
    } 

    modifier equalAccountsAmmounts(
        address[] memory accounts,
        uint256[] memory amounts
    ) {
        if (accounts.length != amounts.length)
            revert UnequalAccountsAmmounts();
        _;
    }

    modifier mintToZeroAddress(address account) {
        if (account == address(0))
            revert MintToZeroAddress();
        _;
    }

    modifier mintZeroTokens(uint256 amount) {
        if (amount == 0)
            revert MintZeroTokens();
        _;
    }

    //////////////////////////////////////////////
    // TRANSFERS
    //////////////////////////////////////////////

	// Pre validate token transfer
	function checkTransferIsValid(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        transferToZeroAddress(to)
        sufficientTokens(from, id, amount)
        returns (bool)
    {
        uint256[] memory ids = new uint256[](1);
        ids[0] = id;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        _beforeTokenTransfer(_msgSender(), from, to, ids, amounts, data);

		return true;
	}
	
	// Forced batch transfer from
    function forcedBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
		public
		virtual
		override 
		onlyOwner
	{
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

	// Forced transfer from
	function forcedTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
	)
		public
		virtual
		override 
		onlyOwner
	{
		_safeTransferFrom(from, to, id, amount, data);
	}

	// Recover tokens 
	function recover(
        address lostWallet,
        address newWallet,
        bytes memory data
    )
        external
        onlyOwner 
        returns (bool)
    {
        _registry.setFrozenAll(newWallet, _registry.checkFrozenAll(lostWallet));
    
        // For all tokens 
        for (uint256 id = 0; id < _totalTokens; id++) {
            
            // If user has balance for tokens
            if (balanceOf(lostWallet, id) > 0) {

                // Transfer tokens from old account to new one
                forcedTransferFrom(lostWallet, newWallet, id, balanceOf(lostWallet, id), data);

                // Freeze partial shares
                uint256 frozenShares = _registry.getFrozenShares(lostWallet, id);

                // If has frozen shares freeze on new account
                if (frozenShares > 0) 
                    _registry.freezeShares(id, newWallet, frozenShares);
                
            }
        }
        
        // Event
        emit RecoverySuccess(lostWallet, newWallet);

        return true;
    }

    //////////////////////////////////////////////
    // HOOKS
    //////////////////////////////////////////////

	// Before transfer hook
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
		internal
		override(ERC1155, ERC1155Pausable)
	{
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        
        if (address(_compliance) != address(0))
            if (!_compliance.checkCanTransferBatch(to, from, ids, amounts))
                revert RecieverInelligible();

        if (address(_registry) != address(0))
            if (!_registry.checkCanTransferBatch(to, from, ids, amounts))
                revert TransferInelligible();
	}

	// After transfer hook
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
		internal
		override(ERC1155)
	{
        if (address(_registry) != address(0))
            if (!_registry.batchTransferred(from, to, ids, amounts))
                revert CouldNotUpdateShareholders();
	}

    //////////////////////////////////////////////
    // MINT AND BURN 
    //////////////////////////////////////////////

    // Mint shares to a group
    function mintGroup(
        address[] memory accounts,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        onlyOwner
        equalAccountsAmmounts(accounts, amounts)
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            mint(accounts[i], id, amounts[i], data);
        }
    }
    
    // Mint shares
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        onlyOwner
        mintToZeroAddress(account)
        mintZeroTokens(amount)
    {
        // Burn
        _mint(account, id, amount, data);

        // Updates
        _registry.mint(account, id, amount);  

        // Event
        emit MintTokens(account, id, amount, data);
    }

    // Burn shares from a group
    function burnGroup(
        address[] memory accounts,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        onlyOwner
        equalAccountsAmmounts(accounts, amounts)
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            burn(accounts[i], id, amounts[i], data );
        }
    }

    // Burn shares
    function burn(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        onlyOwner
    {
        // Burn
        _burn(account, id, amount);

        // Updates
        _registry.burn(account, id, amount);

        // Event
        emit BurnTokens(account, id, amount, data);
    }

    //////////////////////////////////////////////
    // CREATE NEW TOKEN
    //////////////////////////////////////////////

    // Create token
    function newToken(
        uint256 shareholderLimit,
        uint256 shareholdingMinimum,
        bool shareholdingNonDivisible
    )
        public
        onlyOwner
        returns (uint256)
    {
        _totalTokens++;

        _registry.newToken(_totalTokens, shareholderLimit, shareholdingMinimum, shareholdingNonDivisible);

        emit NewToken(_totalTokens, shareholderLimit, shareholdingMinimum, shareholdingNonDivisible);

        return _totalTokens;
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    // Set compliance
    function setCompliance(
        address compliance
    ) 
        public 
        onlyOwner
    {
        _compliance = IHypershareCompliance(compliance);
        
        emit UpdatedHypershareCompliance(compliance);  
    }

	// Set registry
	function setRegistry(
        address registry
    )
        public
        onlyOwner
    {
        _registry = IHypershareRegistry(registry);
        
        emit UpdatedHypershareRegistry(registry);  
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    // Get total tokesn
    function getTotalTokens()
        public
        view 
        returns (uint256)
    {
        return _totalTokens;
    }

}