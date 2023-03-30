// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHypershareHoldersDelegates {

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate, uint256 id);
    event DelegateVotesChanged(address indexed delegate, uint256 indexed id, uint256 previousBalance, uint256 newBalance);
    
    function transferred(address from, address to, uint256 id, uint256 amount) external;
    function batchTransferred(address from, address to, uint256[] memory ids, uint256[] memory amounts) external;
    
	function delegateTo(address delegatee, uint256 id) external payable;
	function moveDelegates(address srcRep, address dstRep, uint256 id, uint256 amount) external;

    function getDelegates(address account, uint256 id) external view returns (address);
    function getCurrentVotes(address account, uint256 id) external view returns (uint256);
    function getPriorVotes(address account, uint256 id, uint256 timestamp) external view returns (uint256);
	
}