// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import './Utils/Checkpoint.sol';

import '../Interface/IHypershare.sol';
import '../Interface/IHypershareHoldersDelegates.sol';

contract HypershareHoldersDelegates is IHypershareHoldersDelegates, Checkpoint {

    ////////////////
    // INTERFACES
    ////////////////

    // the token on which this share contract is applied
    IHypershare public _share;

    ////////////////
    // STATE
    ////////////////

    // Mapping from holder address to token ID to delegate address 
    mapping(address => mapping(uint256 => address)) internal _delegates;
    
    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        address share
    ) {
        _share = IHypershare(share);
        // Event
    }
    
    ////////////////
    // MODIFIERS
    ////////////////

    modifier onlyShare() {
        require(msg.sender == address(_share));
        _;
    }

    //////////////////////////////////////////////
    // TRANSFER FUNCTIONS
    //////////////////////////////////////////////

    // Update the delegates for a batch
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

    // Update the delegates on transfer
    function transferred(
        address from,
        address to,
        uint256 id,
        uint256 amount
    )
        public
        onlyShare
    {
        _checkpoint(_delegates[from][id], _delegates[to][id], id, amount);
    }

    //////////////////////////////////////////////
    // DELEGATION FUNCTIONS
    //////////////////////////////////////////////

    // Delegates voting power to an address
    function delegateTo(
        address delegatee,
        uint256 id
    )
        external
        payable
    {
        address currentDelegate = _delegates[msg.sender][id] ;

        _delegates[msg.sender][id] = delegatee;

        // Move delegates
        _checkpoint(
            currentDelegate,
            delegatee,
            id,
            _share.balanceOf(msg.sender, id)
        );

        // Event
        emit DelegateChanged(msg.sender, currentDelegate, delegatee, id);
    }

        
    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    function getDelegates(
        address account,
        uint256 id
    )
        public
        view
        returns (address)
    {
        address current = _delegates[account][id];

        return
            current == address(0) 
                ? account 
                : current;
    }
    
    function getCurrentVotes(
        address account,
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        // Won't underflow because decrement only occurs if positive `nCheckpoints`.
        unchecked {
            uint256 nCheckpoints = _numCheckpoints[account][id];

            return
                nCheckpoints != 0
                    ? _checkpoints[account][id][nCheckpoints - 1].shares
                    : 0;
        }
    }

    function getPriorVotes(
        address account,
        uint256 id,
        uint256 timestamp
    )
        public
        view
        returns (uint256)
    {
        require(block.timestamp <= timestamp, ""); // #TODO

        uint256 nCheckpoints = _numCheckpoints[account][id];

        if (nCheckpoints == 0) return 0;

        // Won't underflow because decrement only occurs if positive `nCheckpoints`.
        unchecked {
            uint256 prevCheckpoint = nCheckpoints - 1;
            
            if (
                _checkpoints[account][id][prevCheckpoint].fromTimestamp <=
                timestamp
            ) return _checkpoints[account][id][prevCheckpoint].shares;

            if (_checkpoints[account][id][0].fromTimestamp > timestamp) return 0;

            uint256 lower;

            uint256 upper = prevCheckpoint;

            while (upper > lower) {
                uint256 center = upper - (upper - lower) / 2;

                Checkpoint memory cp = _checkpoints[account][id][center];

                if (cp.fromTimestamp == timestamp) {
                    return cp.shares;
                } else if (cp.fromTimestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }

            return _checkpoints[account][id][lower].shares;
        }
    }
    
    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    function setShare(

    )
        public 
        onlyOwner
    {
        
    }

}