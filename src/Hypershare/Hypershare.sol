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
    uint256 totalTokens;

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
		_compliance = IHypershareCompliance(compliance);
        // Event
        
		_registry = IHypershareRegistry(registry);
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
        _registry.toggleAddressFrozenAll(newWallet, _registry.checkFrozenAll(lostWallet));
    
        // For all tokens 
        for (uint256 id = 0; id < totalTokens; id++) {
            
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
            require(_compliance.checkCanTransferBatch(to, from, ids, amounts), "Accounts is not elligible to recieve shares.");
        if (address(_registry) != address(0))
            require(_registry.checkCanTransferBatch(to, from, ids, amounts), "Exceeds holder transfer frozen");
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
			require(_registry.batchTransferred(from, to, ids, amounts), "Could not update shareregistry with transfer");
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
        _registry.mint(account, id, amount);  

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
        _registry.burn(account, id, amount);

        // Event
    }

    //////////////////////////////////////////////
    // CREATE NEW TOKEN
    //////////////////////////////////////////////

    // Create token
    function newToken()
        public
        onlyOwner
    {
        totalTokens++;
        // #TODO
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
    }

	// Set registry
	function setRegistry(
        address registry
    )
        public
        onlyOwner
    {
        _registry = IHypershareRegistry(registry);
    }

}