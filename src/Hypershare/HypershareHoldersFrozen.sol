// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import './Utils/Checkpoint.sol';
import 'openzeppelin-contracts/contracts/access/Ownable.sol';
import '.././Interface/IHypershareHoldersFrozen.sol';

// Calling
import '.././Interface/IHyperbaseIdentityRegistry.sol';
import '.././Interface/IHypershare.sol';

contract HypershareHoldersFrozen is IHypershareHoldersFrozen, Ownable  {

    ////////////////
    // INTERFACES
    ////////////////

    // the token on which this share contract is applied
    IHypershare public _share;

    ////////////////
    // STATES
    ////////////////

    // Mapping from user address to bool for frozen y/n across all tokens
    mapping(address => bool) public _frozenAll;

    // Mapping from token ID to accounts address to bool for frozen y/n
    mapping(uint256 => mapping(address => bool)) public _frozenAccounts;

    // Mapping from token ID to address to address to uint amount of shares that are frozen
	mapping(uint256 => mapping(address => uint256)) public _frozenShares;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        address share
    ){
        _share = IHypershare(share);
        // Event
    }
    
    ////////////////
    // MODIFIERS
    ////////////////

    modifier onlyShare() {
        require(msg.sender == address(_share), "Only token contract can call this function");
        _;
    }

    modifier onlyShareOrOwner() {
        require(msg.sender == address(_share) || msg.sender == owner(), "Only token contract can call this function");
        _;
    }

    //////////////////////////////////////////////
    // TRANSFER FUNCTIONS
    //////////////////////////////////////////////

    // Transferred batch
    function batchTransferred(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        public
        onlyShare
    {
		// Sanity checks 
		require(ids.length == amounts.length, "Ids and amounts do not match");
        for (uint256 i = 0; i < ids.length; i++) {
            transferred(from, to, ids[i], amounts[i]);
        }
    } 

    // Update the cap table on transfer
    function transferred(
        address from,
        address to,
        uint256 id,
        uint256 amount
    )
        public
        onlyShare
    {
        updateUnfrozenShares(from, id, amount);
    }

    //////////////////////////////////////////////
    // FREEZE | UNFREEZE
    //////////////////////////////////////////////

    //  
    function toggleAddressFrozenAll(
        address account,
        bool freeze
    )
        public
        onlyShareOrOwner 
    {
        // Mapping from user address to bool for frozen y/n across all tokens
        _frozenAll[account] = freeze;

        // Events
        emit AddressFrozen(account, freeze, msg.sender);
    }

    // Set an address to frozen
    function toggleAddressFrozen(
        address account,
        uint256 id,
        bool freeze
    )
        public
        onlyShareOrOwner 
    {
        _frozenAccounts[id][account] = freeze;

        // Event
        
    }

    // Set a batch of addresses to frozen
    function batchToggleAddressFrozen(
        address[] memory accounts,
        uint256[] memory ids,
        bool[] memory freeze
    )
        public
        onlyShareOrOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            toggleAddressFrozen(accounts[i], ids[i], freeze[i]);
        }
    }
    
    // Freeze a portion of shares for a batch of accounts
    function batchFreezeShares(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        public
    {
        require((accounts.length == ids.length) && (ids.length == amounts.length), "ERC1155: accounts, ids and amounts length mismatch");   
        for (uint256 i = 0; i < accounts.length; i++) {
            freezeShares(accounts[i], ids[i], amounts[i]);
        }
    }

    // Freeze a portion of shares for a single account
    function freezeShares(
        address account,
        uint256 id,
        uint256 amount
    )
        public
        onlyShareOrOwner
    {
        require(checkIsNonFractional(amount, id), "share transfers must be non-fractional");
        uint256 balance = _share.balanceOf(account, id);
        require(balance >= _frozenShares[id][account] + amount, "Amount exceeds available balance");
        _frozenShares[id][account] = _frozenShares[id][account] + (amount);
        emit SharesFrozen(account, amount);
    }

    // Update the unfrozen balance that is available to transfer post transfer
    function updateUnfrozenShares(
        address from,
        uint256 id,
        uint256 amount
    )
        public
    {
        uint256 freeBalance = _share.balanceOf(from, id) - (_frozenShares[id][from]);
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - (freeBalance);
            _frozenShares[id][from] = _frozenShares[id][from] - (tokensToUnfreeze);
            emit SharesUnfrozen(from, tokensToUnfreeze);
        }
    }

    //////////////////////////////////////////////
    // CHECKS (Returns bool)
    //////////////////////////////////////////////

    function checkCanTransferBatch(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        public 
        view 
        returns (bool)
    {
        require((ids.length == amounts.length), "ERC1155: ids and amounts length mismatch");
        for (uint256 i = 0; i < ids.length; i++) {
            checkCanTransfer(from, to, ids[i], amounts[i]);
        }
        return true;
    }

    // Return bool if the transfer passes share
    function checkCanTransfer(
        address to,
        address from,
        uint256 id,
        uint256 amount
    )
        public
        view
        returns (bool)
    {
        require(checkIsNotFrozenAllTransfer(from, to), "Wallet is frozen");
        require(checkIsNotFrozenAccountsTransfer(id, from, to), "Wallet is frozen");
        require(checkIsNotFrozenSharesTransfer(amount, id, from), "Insufficient Balance");

        return true;
    }
    
    // Check is not frozen for all
    function checkIsNotFrozenAllTransfer(
        address from,
        address to
    )
        public
        view
        returns (bool)
    {
        if (!_frozenAll[to] && !_frozenAll[from]) return true;  
        else return false;  
    }
    
    // Return bool address and tokens are not frozen for token id
    function checkIsNotFrozenAccountsTransfer(
        uint256 id,
        address from,
        address to
    )
        public
        view
        returns (bool)
    {
        if (!_frozenAccounts[id][to] && !_frozenAccounts[id][from]) return true;  
        else return false;  
    }

    // 
    function checkIsNotFrozenSharesTransfer(
        uint256 amount,
        uint256 id,
        address from
    )
        public
        view
        returns (bool)

    {
        if (amount <= (_share.balanceOf(from, id) - _frozenShares[id][from])) return true;  
        else return false;  
    }

    // Return frozen all
    function checkFrozenAll(   
        address account
    )
        public
        view
        returns (bool)
    {
        return _frozenAll[account];
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    // Returns the minimum shareholding
    function getMinimumShareholding(
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        return _shareholdingMinimum[id];
    }

    // Return frozen shares 
    function getFrozenShares(
        address account,
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        return _frozenShares[id][account];
    }

    // Return frozen accounts 
    function getFrozenAccounts(
        address account,
        uint256 id
    )
        public
        view
        returns (bool)
    {
        return _frozenAccounts[id][account];
    }
   
}