// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inheriting
import '../interface/IHypershare.sol';
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

// Interfaces
import '../interface/IHypercoreCompliance.sol';
import '../interface/IHypercoreRegistry.sol';

/**

    Hypershare is an ERC1155 based tokenised equity contract. It provides all the functions
    traditionally associated with an ERC1155 token contract, plus additional issuer controls
    designed (and legally required in some jurisdictions) to support for equity shares. These
    features include forced transfers and share recovery in the event that a shareholder has 
    lost access to their wallet.

 */

contract Hypershare is IHypershare, ERC1155, ERC1155Pausable, Ownable {

    ////////////////
    // STATE
    ////////////////

    /**
     * @dev Total tokens, incremented value used to get the most recent/next token ID.
     */
    uint256 _totalTokens;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(string memory uri_) ERC1155(uri_) {}

    ////////////////
    // MODIFIERS
    ////////////////

    /**
     * @dev Prevents token transfers to the zero address.
     * @param to The receiving address.
     */
    modifier transferToZeroAddress(
        address to
    ) {
        if (to == address(0))
            revert TransferToZeroAddress();
        _;
    }

    /**
     * @dev Ensures the sender has sufficient tokens for a token transfer.
     * @param from The transfering address. 
     * @param id The id of the token transfer.
     * @param amount The amount of tokens to transfer.
     */
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

    /**
     * @dev Ensures that the array of accounts and amounts are of equal length.
     * @param accounts An array of user addresses.
     * @param amounts An array of the integer amounts.
     */
    modifier equalAccountsAmounts(
        address[] memory accounts,
        uint256[] memory amounts
    ) {
        if (accounts.length != amounts.length)
            revert UnequalAccountsAmounts();
        _;
    }

    /**
     * @dev Ensures that mint amount is non-zero.
     * @param amount The amount of token transfer.
     */
    modifier mintZeroTokens(
        uint256 amount
    ) {
        if (amount == 0)
            revert MintZeroTokens();
        _;
    }

    //////////////////////////////////////////////
    // CREATE NEW TOKEN
    //////////////////////////////////////////////

    /** 
     * @dev Returns the total token count where token IDs are incremental values.
     */
    function getTotalTokens()
        public
        view 
        returns (uint256)
    {
        return _totalTokens;
    }

    /**
     * @dev Create a new token by incrementing token ID and initizializing in the compliance contracts.
     * @param 
     */
    function createToken(
        address[] memory hypercores_,
        bytes[] memory hypercoresData_
    )
        public
        onlyOwner
        returns (uint256)
    {
        // Ensure hypercore array parity
        if (hypercores_.length != hypercoresData_.length)
            revert NoArrayParity();

        // Increment tokens
        _totalTokens++;
        
        // If has hypercores
        if (hypercores_.length != 0) {
            for (uint8 i = 0; i < hypercores_.length; i++) {

                // #TODO, this needs to be partioned based on token id
                
                hypercores[hypercores_[i]] = true;

                if (hypercoresData_[i].length != 0) {
                    (bool success, ) = hypercores_[i].call(hypercoresData_[i]);

                    // If init failed 
                    if (!success)
                        revert InitCallFail();
                }

            }
        }

        // Event
        emit createToken(_totalTokens, shareholderLimit, shareholdingMinimum, shareholdingNonDivisible);

        return _totalTokens;
    }

    //////////////////////////////////////////////
    // TRANSFERS
    //////////////////////////////////////////////
	
    /** 
     * @dev Owner-operator function to force a batch transfer from an address. May be used to burn
     * and reissue if the share terms are updated.
     *
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param ids An array of token IDs for the token transfer.
     * @param amounts An array of integer amounts for each token in the token transfer.
     * @param data Optional data field to include in events.
     */
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

    /** 
     * @dev Owner-operator function used to force a transfer from an address. Typically used in the
     * case of share recovery.
     *
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param id The id of the token transfer.
     * @param amount The amount of tokens to transfer.
     * @param data Optional data field to include in events.
     */
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

    //////////////////////////////////////////////
    // MINT AND BURN 
    //////////////////////////////////////////////

    /**
     * @dev Mint shares to a group of receiving addresses. 
     * @param accounts An array of the recieving accounts.
     * @param id The token ID to mint.
     * @param amounts An array of the amount to mint to each receiver.
     * @param data Optional data field to include in events.
     */
    function mintGroup(
        address[] memory accounts,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        onlyOwner
        equalAccountsAmounts(accounts, amounts)
    {
        for (uint256 i = 0; i < accounts.length; i++)
            mint(accounts[i], id, amounts[i], data);
    }
    
    /**
     * @dev Mint shares to a receiving address. 
     * @param account The receiving address.
     * @param id The token ID to mint.
     * @param amount The amount of shares to mint to the receiver.
     * @param data Optional data field to include in events.
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        onlyOwner
        transferToZeroAddress(account)
        mintZeroTokens(amount)
    {
        // Mint
        _mint(account, id, amount, data);

        // Event
        emit MintTokens(account, id, amount, data);
    }

    /**
     * @dev Burn shares from a group of shareholder addresses. 
     * @param accounts An array of the accounts to burn shares from.
     * @param id The token ID to burn.
     * @param amounts An array of the amounts of shares to burn from each account.
     * @param data Optional data field to include in events.
     */
    function burnGroup(
        address[] memory accounts,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        onlyOwner
        equalAccountsAmounts(accounts, amounts)
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            burn(accounts[i], id, amounts[i], data );
        }
    }

    /**
     * @dev Burn shares from a shareholder address. 
     * @param account The account shares are being burnt from.
     * @param id The token ID to mint to receiver.
     * @param amount The amount of tokens to burn from the account.
     * @param data Optional data field to include in events.
     */
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

        // Event
        emit BurnTokens(account, id, amount, data);
    }

    //////////////////////////////////////////////
    // HOOKS
    //////////////////////////////////////////////

    /**
     * @dev Pre validate the token transfer to ensure that the actual transfer will not fail under
       the same conditions. 
     *
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param id The id of the token transfer.
     * @param amount The amount of tokens to transfer.
     * @param data Optional data field to include in events.
     */
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

    /**
     * @dev ERC-1155 before transfer hook. Used to pre-validate the transfer with the Hypercores. 
     * @param operator The address of the contract owner/operator.
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param ids An array of token IDs for the token transfer.
     * @param amounts An array of integer amounts for each of the token IDs in the token transfer.
     * @param data Optional data field to include in events.
     */
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
        
        // #TODO
        for (uint 8 i = 0; i < hypercores.length; i++)
            // Validate that hypercore needs calling
                // Encode data fields 
                // _callHypercore with data
                
                // ??
                // Get return values (target, returnData)
                // If target, 
                    // _callHypercore with returnData
	}

    /**
     * @dev ERC-1155 after transfer hook. Used to update the shareholder registry to reflect the transfer. 
     * @param operator The address of the contract owner/operator.
     * @param from The transfering address. 
     * @param to The receiving address. 
     * @param ids An array of token IDs for the token transfer.
     * @param amounts An array of integer amounts for each of the token IDs in the token transfer.
     * @param data Optional data field to include in events.
     */
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
        
        // #TODO 
        for (uint 8 i = 0; i < hypercores.length; i++)
            // Validate that hypercore needs calling
                // Encode data fields 
                // _callHypercore with data
                
                // ??
                // Get return values (target, returnData)
                // If target, 
                    // _callHypercore with returnData
	}
    
    //////////////////////////////////////////////
    // HYPERCORE FUNCTIONS
    //////////////////////////////////////////////
     
    /**
     * @dev 
     * @param hypercore
     * @param hypercoreData
     */
    function _setHypercore(
        address hypercore, 
        bytes calldata hypercoreData
    )
        internal
    {

        /**
        
            for (uint256 i; i < prop.accounts.length; i++) {
                if (prop.amounts[i] != 0) 
                    hypercores[prop.accounts[i]] = !hypercores[prop.accounts[i]];
            
                if (prop.payloads[i].length != 0) IHypercore(prop.accounts[i])
                    .setHypercore(prop.payloads[i]);
            }
        
         */

    }

    /**
     * @dev 
     * @param hypercore
     * @param hypercoreData
     */
    function _callHypercore(
        address hypercore, 
        bytes calldata hypercoreData
    )
        internal
    {
        // Ensure Hypercore returns bool true in from mapping of Hypercores
        if (!hypercores[hypercore] && !hypercores[msg.sender])
            revert NotHypercore();
        
        (returnData) = IHypercore(hypercore).callHypercore{value: msg.value}(operator, from, to, ids, amounts, data, hypercoreData);
        
    }


}