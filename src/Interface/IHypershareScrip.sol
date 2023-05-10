// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IHypershareScrip is IERC20 {
	
  	////////////////
    // ERRORS
    ////////////////

    /**
     * @dev Token transfer invalid.
     */
    error TransferInvalid();

    /**
     * @dev Burn amount exceeds allowance.
     */
    error BurnExceedAllowance();

  	////////////////
    // EVENTS
    ////////////////

    /**
     * @dev User has wrapped erc-1155 share tokens for erc-20 scrip tokens.
     */
    event WrappedTokens(address indexed account, uint256 amount);

    /**
     * @dev User has unwrapped er20 scrip tokens for erc-1155 share tokens.
     */
    event UnwrappedTokens(address indexed account, uint256 amount);	

    //////////////////////////////////////////////
    // WRAP | UNWRAP
    //////////////////////////////////////////////
    
    function wrapTokens(address account, uint256 amount) external;
    function unWrapTokens(address account,  uint256 amount) external;

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    function getHypershare() external view returns (address);
    function getTokenId() external view returns (uint256);
    function uri() external view returns (string memory);

}