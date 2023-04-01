// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';

interface IHypershare is IERC1155 {
    
    event ComplianceLimitHolderAdded(address indexed complianceHolderLimit);
    event ComplianceClaimsRequiredAdded(address indexed complianceClaimsRequired);
    event IdentityRegistryAdded(address indexed identityRegistry);  
    event RecoverySuccess(address lostWallet, address newWallet);

    function checkTransferIsValid(address from, address to, uint256 id, uint256 amount) external returns (bool);
    
    function forcedTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function forcedBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    
    function recover(address lostWallet, address newWallet, bytes memory data) external returns (bool);
    
    function setCompliance(address compliance) external;
	function setRegistry(address registry) external;

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address account, uint256 id, uint256 amount) external;

}