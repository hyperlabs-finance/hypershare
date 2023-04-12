// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import '../Interface/IHypershare.sol';
import '../Interface/IHypershareScrip.sol';

contract HypershareScrip is IHypershareScrip, ERC20, ERC1155Holder {

    ////////////////
    // CONTRACT
    ////////////////
    
    // The corresponding hypershare contract
    IHypershare public _share;

    ////////////////
    // STATE
    ////////////////

    // Share token id in the share contract
    uint256 public _id;

    // Metadata uri for legal contract 
	string public _uri;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        IHypershare share,
        uint256 id,
        string memory name_,
        string memory symbol_,
        string memory uri_
    )
        ERC20(name_, symbol_)
    {
        _id = id;
        _uri = uri_;
        _share = IHypershare(share);
    }

    //////////////////////////////////////////////
    // WRAP | UNWRAP
    //////////////////////////////////////////////
    
    // Deposit tokens and mint scrip
    function wrapTokens(
        address account,
        uint256 amount
    )
        public
    {
        // Handle deposit of ERC1155 tokens
        _share.safeTransferFrom(account, address(this), _id, amount, "");
        
        // Mint scrip
        _mint(account, amount);

        // Event
        emit WrappedTokens(account, amount);
    }

    // Withdraw tokens and burn scrip
    function unWrapTokens(
        address account, 
        uint256 amount
    )
        public
    {
        // Require _share can transfer
        if (!_share.checkTransferIsValid(address(this), account, _id, amount, ""))
            revert TransferInvalid();
        
        // Handle unwrap if done by third party
        if (msg.sender != account) {
            uint _allowance =  allowance(account, msg.sender);
            if (_allowance < amount) 
                revert BurnExceedAllowance();
            uint256 decreasedAllowance =  _allowance - amount; 
            _approve(account, msg.sender, decreasedAllowance);
        }
        
        // Burn the scrip
        _burn(account, amount);
        
        // Return _share
        _share.safeTransferFrom(address(this), account, _id, amount, "" );

        // Event
        emit UnwrappedTokens(account, amount);
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    // Returns the address of the corresponding hypershare contract
    function getHypershare()
        public
        view
        returns (address)
    {
        return address(_share);
    }

    // Returns the token id for this wrapper token. Each wrapper is locked to a single token id
    function getTokenId()
        public
        view
        returns (uint256)
    {
        return _id;
    }

    // Returns the metadata uri for this wrapper token
    function uri()
        public
        view
        returns (string memory)
    {
        return _uri;
    }
}