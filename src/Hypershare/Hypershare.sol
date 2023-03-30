// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inheriting
import '../Interface/IHypershare.sol';
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

// Calling interfaces
import '../Interface/IHypershareCompliance.sol';
import '../Interface/IHypershareHoldersFrozen.sol';
import '../Interface/IHypershareHolders.sol';
import '../Interface/IHypershareHoldersDelegates.sol';

contract Hypershare is IHypershare, ERC1155, ERC1155Pausable, Ownable {

    ////////////////
    // INTERFACES
    ////////////////

    IHypershareHoldersFrozen public _frozen;
    IHypershareCompliance public _claimsRequired;
    IHypershareHolders public _holders;
    IHypershareHoldersDelegates public _delegates;

    ////////////////
    // STATE
    ////////////////

    uint256 totalTokens;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
		string memory uri_,
        
        address frozen,
        address claimsRequired,
        address holders,
        address delegates 
    )
        // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
        ERC1155(uri_)
    {
		_frozen = IHypershareHoldersFrozen(frozen);
        // Event
        
		_claimsRequired = IHypershareCompliance(claimsRequired);
        // Event
        
		_holders = IHypershareHolders(holders);
        // Event
        
		_delegates = IHypershareHoldersDelegates(delegates);
        // Event
    }

    //////////////////////////////////////////////
    // TRANSFERS
    //////////////////////////////////////////////

	// Pre validate token transfer
	function checkTransferIsValid(
        address from,
        address to,
        uint256 id,
        uint256 amount
    )
        public
        returns (bool)
    {
		address operator = _msgSender();

        uint256[] memory ids = new uint256[](1);
        ids[0] = id;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        _beforeTokenTransfer(operator, from, to, ids, amounts, "");
		return true;
	}
	
	// Forced transferfrom
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
        _frozen.toggleAddressFrozenAll(newWallet, _frozen.checkFrozenAll(lostWallet));
    
        // For all tokens 
        for (uint256 id = 0; id < totalTokens; id++) {
            
            // If user has balance for tokens
            if (balanceOf(lostWallet, id) > 0) {

                // Transfer tokens from old account to new one
                forcedTransferFrom(lostWallet, newWallet, id, balanceOf(lostWallet, id), data);

                // Freeze partial shares
                uint256 frozenShares = _frozen.getFrozenShares(lostWallet, id);
                if (frozenShares > 0) {
                    _frozen.freezeShares(newWallet, id, frozenShares);
                }
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
        if (address(_claimsRequired) != address(0))
            require(_claimsRequired.checkCanTransferBatch(to, from, ids, amounts), "Accounts is not elligible to recieve shares.");
        if (address(_frozen) != address(0))
            require(_frozen.checkCanTransferBatch(to, from, ids, amounts), "Violates transfer limitations");
        if (address(_holders) != address(0))
            require(_holders.checkCanTransferBatch(to, from, ids, amounts), "Exceeds holder transfer frozen");
		return true;
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
        if (address(_frozen) != address(0))
			require(_frozen.batchTransferred(from, to, ids, amounts), "Could not update transfer frozen with transfer");
        if (address(_holders) != address(0))
			require(_holders.batchTransferred(from, to, ids, amounts), "Could not update shareholders with transfer");
        if (address(_delegates) != address(0))
			require(_delegates.batchTransferred(from, to, ids, amounts), "Could not update delegates with transfer");
	}

    //////////////////////////////////////////////
    // MINT AND BURN 
    //////////////////////////////////////////////

    // Mint tokens
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        onlyOwner
    {
        // Burn
        _mint(account, id, amount, data);

        // Updates
        _holders.created(account, id, amount);  

        // Event
    }

    // Burn tokens
    function burn(
        address account,
        uint256 id,
        uint256 amount
    )
        public
        onlyOwner
    {
        // Burn
        _burn(account, id, amount);

        // Updates
        _frozen.updateUnfrozenShares(account, id, amount); 
        _holders.pruneShareholders(account, id);  

        // Event
    }

    //////////////////////////////////////////////
    // CREATE TOKEN
    //////////////////////////////////////////////

    // Create token
    function newToken()
        public
        onlyOwner
    {
        totalTokens++;
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    // Set claims required
    function setClaimsRequired(
        address claimsRequired
    ) 
        public 
        onlyOwner
    {
        _claimsRequired = IHypershareCompliance(claimsRequired);
    }

    // Set _frozen
    function setFrozen(
        address frozen
    )
        public
        onlyOwner 
    {
        _frozen = IHypershareHoldersFrozen(frozen);
    }

	// Set holders
	function setHolders(
        address holders
    )
        public
        onlyOwner
    {
        _holders = IHypershareHolders(holders);
    }

	// Set delegates
	function setDelegates(
        address delegates
    )
        public
        onlyOwner
    {
        _delegates = IHypershareHoldersDelegates(delegates);
    }
	
}