// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract IHypershareScrip is IERC20 {
	
  	////////////////
    // ERRORS
    ////////////////

    // Token transfer invalid
    error TransferInvalid();

  	////////////////
    // EVENTS
    ////////////////

    // User has wrapped erc-1155 share tokens for erc-20 scrip tokens
    event WrappedTokens(address indexed account, uint256 amount);

    // User has unwrapped er20 scrip tokens for erc-1155 share tokens
    event UnwrappedTokens(address indexed account, uint256 amount);	

    //////////////////////////////////////////////
    // WRAP | UNWRAP
    //////////////////////////////////////////////
    
    // Deposit erc-1155 hyperhshare tokens into the contract and recieve minted erc-20 scrip tokens for use in defi
    function wrapTokens(address account, uint256 amount) public;

    // Burn erc-20 and recieve the underlying hypershare tokens
    function unWrapTokens(address account,  uint256 amount) public;

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    // Returns the address of the corresponding hypershare contract
    function getHypershare() public view virtual returns (address);

    // Returns the token id for this wrapper token. Each wrapper is locked to a single token id
    function getTokenId() public view virtual returns (uint256);

    // Returns the metadata uri for this wrapper token
    function uri() public view virtual returns (string memory);

}