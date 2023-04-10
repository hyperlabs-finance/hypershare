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
        returns (bool)
    {
        require(to != address(0), TransferToZeroAddress());

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, InsufficientShares());

		address operator = _msgSender();

        uint256[] memory ids = new uint256[](1);
        ids[0] = id;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

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
        _registry.toggleAddressFrozenAll(newWallet, _registry.checkFrozenAll(lostWallet));
    
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
                    _registry.freezeShares(newWallet, id, frozenShares);
                
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
            require(_compliance.checkCanTransferBatch(to, from, ids, amounts), RecieverInelligible());
        if (address(_registry) != address(0))
            require(_registry.checkCanTransferBatch(to, from, ids, amounts), TransferInelligible());
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
			require(_registry.batchTransferred(from, to, ids, amounts), CouldNotUpdateShareholders());
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
    {
        require(accounts.length == amounts.length, UnequalAccountsAmmounts());
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
    {
        // Sanity checks
        require(account != address(0), MintToZeroAddress());
        require(amount != 0, MintZeroTokens());
        
        // Burn
        _mint(account, id, amount, data);

        // Updates
        _registry.mint(account, id, amount);  

        // Event
        emit SharesIsssued(account, id, amount, data);
    }

    // Burn shares from a group
    function burnGroup(
        address[] memory accounts,
        uint256 id,
        uint256[] memory amounts
    )
        public
        onlyOwner
    {
        require(accounts.length == amounts.length, UnequalAccountsAmmounts());
        for (uint256 i = 0; i < accounts.length; i++) {
            burn(accounts[i], id, amounts[i]);
        }
    }

    // Burn shares
    function burn(
        address account,
        uint256 id,
        uint256 amount,
        bytes32 memory data
    )
        public
        onlyOwner
    {
        // Burn
        _burn(account, id, amount);

        // Updates
        _registry.burn(account, id, amount);

        // Event
        emit SharesBurned(account, id, amount, data);
    }

    // #TODO burn and reissue

    //////////////////////////////////////////////
    // CREATE NEW TOKEN
    //////////////////////////////////////////////

    // Create token
    function newToken(
        uint256 shareholderLimit,
        uint256 shareholdingMinimum,
        bool shareholdingNonFractional
    )
        public
        onlyOwner
        returns (uint256)
    {
        _totalTokens++;

        _registry.newToken(_totalTokens, shareholderLimit, shareholdingMinimum, shareholdingNonFractional);

        emit NewShareCreated(_totalTokens, shareholderLimit, shareholdingMinimum, shareholdingNonFractional);

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
        
        emit HypershareComplianceUpdated(compliance);  
    }

	// Set registry
	function setRegistry(
        address registry
    )
        public
        onlyOwner
    {
        _registry = IHypershareRegistry(registry);
        
        emit HypershareRegistryUpdated(registry);  
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