// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';

interface IHypershare is IERC1155 {

    ////////////////
    // ERRORS
    ////////////////

    /**
     * @dev Transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * @dev Insufficient balance for transfer.
     */
    error InsufficientTokens();

    /**
     * @dev Accounts and amounts are not equal.
     */
    error UnequalAccountsAmounts();

    /**
     * @dev Exceeds holder transfer frozen.
     */
    error TransferInelligible();

    /**
     * @dev Could not update share registry with transfer.
     */
    error CouldNotUpdateShareholders();
    
    /**
     * @dev Account is not elligible to receive shares.
     */
    error RecieverInelligible();

    /**
     * @dev Cannot mint to zero address.
     */
    error MintToZeroAddress();
    
    /**
     * @dev Cannot mint to zero tokens.
     */
    error MintZeroTokens();

    ////////////////
    // EVENTS
    ////////////////
    
    /**
     * @dev New share type created.
     */
    event createToken(uint256 indexed id, uint256 shareholderLimit, uint256 shareholdingMinimum, bool shareholdingNonDivisible);
    
    /**
     * @dev New shares issued.
     */
    event MintTokens(address indexed account, uint256 indexed id, uint256 amount, bytes indexed data);
    
    /**
     * @dev Shares burned.
     */
    event BurnTokens(address indexed account, uint256 indexed id, uint256 amount, bytes indexed data);

    //////////////////////////////////////////////
    // CREATE NEW TOKEN
    //////////////////////////////////////////////

    function createToken(uint256 shareholderLimit, uint256 shareholdingMinimum, bool shareholdingNonDivisible) external returns (uint256);

    //////////////////////////////////////////////
    // TRANSFERS
    //////////////////////////////////////////////

    function checkTransferIsValid(address from, address to, uint256 id, uint256 amount, bytes memory data) external returns (bool);
    function forcedBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    function forcedTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function recover(address lostWallet, address newWallet, bytes memory data) external returns (bool);

    //////////////////////////////////////////////
    // MINT AND BURN 
    //////////////////////////////////////////////

    function mintGroup(address[] memory accounts, uint256 id, uint256[] memory amounts, bytes memory data) external;
    function burnGroup(address[] memory accounts, uint256 id, uint256[] memory amounts, bytes memory data) external;
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address account, uint256 id, uint256 amount, bytes memory data) external;

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    function setCompliance(address compliance) external;
	function setRegistry(address registry) external;

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    function getTotalTokens() external view returns (uint256);

}