// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';

interface IHypershare is IERC1155 {

    ////////////////
    // ERRORS
    ////////////////

    // Transfer to the zero address
    error TransferToZeroAddress();

    // Insufficient balance for transfer
    error InsufficientTokens();

    // Accounts and amounts are not equal
    error UnequalAccountsAmmounts();

    // Exceeds holder transfer frozen
    error TransferInelligible();

    // Could not update share registry with transfer
    error CouldNotUpdateShareholders();
    
    // Accounts is not elligible to recieve shares.
    error RecieverInelligible();

    // Cannot mint to zero address
    error MintToZeroAddress();
    
    // Cannot mint to zero tokens
    error MintZeroTokens();

    ////////////////
    // EVENTS
    ////////////////
    
    // Added or updated the shareholder registry
    event UpdatedHypershareRegistry(address indexed registry);  

    // Added or updated the compliance claims contract
    event UpdatedHypershareCompliance(address indexed compliance);  
    
    // Successful or transfer or shares to new investor wallet
    event RecoverySuccess(address indexed lostWallet, address indexed newWallet);

    // New share type creation
    event NewToken(uint256 indexed id, uint256 shareholderLimit, uint256 shareholdingMinimum, bool shareholdingNonDivisible);

    // Share issuance
    event MintTokens(address indexed account, uint256 indexed id, uint256 amount, bytes indexed data);

    // Shares burned
    event BurnTokens(address indexed account, uint256 indexed id, uint256 amount, bytes indexed data);
    
    //////////////////////////////////////////////
    // TRANSFERS
    //////////////////////////////////////////////

    // Pre-validates the elligibility of a share transfer via token balances and compliance
    function checkTransferIsValid(address from, address to, uint256 id, uint256 amount, bytes memory data) external returns (bool);

    // Owner function to force a bathc of share transfers between two parties    
    function forcedBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    
    // Owner function to force a share transfer between two parties    
    function forcedTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    // Owner function transfer the shares and state of a lost wallet to a replacement wallet
    function recover(address lostWallet, address newWallet, bytes memory data) external returns (bool);
    
    //////////////////////////////////////////////
    // MINT AND BURN 
    //////////////////////////////////////////////

    // Mints shares from a group of shareholders. Not to be confused with mintBatch as only takes single token id.
    function mintGroup(address[] memory accounts, uint256 id, uint256[] memory amounts, bytes memory data) external;
    
    // Burns shares from a group of shareholders. Not to be confused with mintBatch as only takes single token id.
    function burnGroup(address[] memory accounts, uint256 id, uint256[] memory amounts, bytes memory data) external;

    // Mints shares to account
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    // Burns shares from account
    function burn(address account, uint256 id, uint256 amount, bytes memory data) external;

    //////////////////////////////////////////////
    // CREATE NEW TOKEN
    //////////////////////////////////////////////

    // Owner function to create a new share type. Increments token count and updates the registry.
    function newToken(uint256 shareholderLimit, uint256 shareholdingMinimum, bool shareholdingNonDivisible) external returns (uint256);

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    // Update the address of the compliance claims required contract
    function setCompliance(address compliance) external;

    // Update the address of the shareholder registry. 
	function setRegistry(address registry) external;

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    // Returns the total token count. Token ids are incremental so current count is the most recent token
    function getTotalTokens() external view returns (uint256);

}