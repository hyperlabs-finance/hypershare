// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import '../Interface/IHypershare.sol';

contract Hyperwrap is ERC20, ERC1155Holder {

    ////////////////
    // CONTRACT
    ////////////////
    
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
        string memory uri
    )
        ERC20(name_, symbol_)
    {
        _id = id;
        _uri = uri;
        _share = IHypershare(share);
    }

    //////////////////////////////////////////////
    // METADATA
    //////////////////////////////////////////////

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri() public view virtual override returns (string memory) {
        return _uri;
    }

    function tokenId() public view virtual override returns (string memory) {
        return _id;
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
        _share.safeTransferFrom(account, address(this), _id, amount, "" );
        
        // Mint scrip
        _mint(account, amount);

        // Event
    }

    // Withdraw tokens and burn scrip
    function unWrapTokens(
        address account, 
        uint256 amount
    )
        public
    {
        // Require _share can transfer
        require(_share.checkTransferIsValid(address(this), account, _id, amount), "Token transfer invalid");
        
        // Handle unwrap if done by third party
        if (msg.sender != account) {
            uint _allowance =  allowance(account, msg.sender);
            require(_allowance > amount, "ERC20: burn amount exceeds allowance");
            uint256 decreasedAllowance =  _allowance - amount; 
            _approve(account, msg.sender, decreasedAllowance);
        }
        
        // Burn the scrip
        _burn(account, amount);
        
        // Return _share
        _share.safeTransferFrom(address(this), account, _id, amount, "" );

        // Event
    }
}