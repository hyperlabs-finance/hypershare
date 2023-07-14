// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import './Hypercore.sol';
import '../interface/IHypercoreDelegates.sol';

/**

    HypercoreDelegates keeps a record of delegation for voting.

 */

contract HypercoreDelegates is Hypercore, IHypercoreDelegates  {

  	////////////////
    // STATE
    ////////////////

    mapping(address => mapping(uint256 => address)) internal _delegates;

    mapping(address => mapping(uint256 => uint256)) public numCheckpoints;

    mapping(address => mapping(uint256 => mapping(uint256 => Checkpoint))) public checkpoints;

    struct Checkpoint {
        uint40 fromTimestamp;
        uint216 votes;
    }
    
    //////////////////////////////////////////////
    // HYPERCORE CALL
    //////////////////////////////////////////////

    function callHypercore(
        bytes calldata hypercoreData
    )
        public
        // returns (bytes calldata returnData)
    {
        (, address from, address to, uint256 id, uint256 amount, bytes memory data) = abi.decode(hypercoreData, (address, address, address, uint256, uint256, bytes));

        _moveDelegates(getDelegates(from, id), getDelegates(to, id), id, amount);

        // returnData = hypercoreData; // #TODO

        emit HypercoreCalled(hypercoreData);
    }

    //////////////////////////////////////////////
    // DELEGATE
    //////////////////////////////////////////////

    function delegateTo(
        address delegatee,
        uint256 id
    )
        public
        payable
        virtual
    {
        address currentDelegate = getDelegates(msg.sender, id);

        _delegates[msg.sender][id] = delegatee;

        _moveDelegates(
            currentDelegate,
            delegatee,
            id,
            balanceOf[msg.sender][id]
        );

        // Emit event
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
        virtual
        returns (address)
    {
        address current = _delegates[account][id];

        return current == address(0) ? account : current;
    }

    function getCurrentVotes(
        address account,
        uint256 id
    )
        public
        view
        virtual
        returns (uint256)
    {
        // Won't underflow because decrement only occurs if positive `nCheckpoints`.
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account][id];

            return
                nCheckpoints != 0
                    ? checkpoints[account][id][nCheckpoints - 1].votes
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
        virtual
        returns (uint256)
    {
        if (block.timestamp <= timestamp)
            revert Undetermined();

        uint256 nCheckpoints = numCheckpoints[account][id];

        if (nCheckpoints == 0)
            return 0;

        uint256 prevCheckpoint = nCheckpoints - 1;
        
        if (checkpoints[account][id][prevCheckpoint].fromTimestamp <= timestamp)
            return checkpoints[account][id][prevCheckpoint].votes;

        if (checkpoints[account][id][0].fromTimestamp > timestamp)
            return 0;

        uint256 lower;
        uint256 upper = prevCheckpoint;

        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2;

            Checkpoint memory cp = checkpoints[account][id][center];

            if (cp.fromTimestamp == timestamp)
                return cp.votes;
            else if (cp.fromTimestamp < timestamp)
                lower = center;
            else
                upper = center - 1;
        }

        return
            checkpoints[account][id][lower].votes;
    }

    //////////////////////////////////////////////
    // INTERNAL FUNCTIONS
    //////////////////////////////////////////////

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 id,
        uint256 amount
    )
        internal
        virtual
    {
        if (srcRep != dstRep && amount != 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep][id];

                uint256 srcRepOld;

                srcRepOld = srcRepNum != 0
                    ? checkpoints[srcRep][id][srcRepNum - 1].votes
                    : 0;

                _writeCheckpoint(
                    srcRep,
                    id,
                    srcRepNum,
                    srcRepOld,
                    srcRepOld - amount
                );
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep][id];

                uint256 dstRepOld;

                dstRepOld = dstRepNum != 0
                    ? checkpoints[dstRep][id][dstRepNum - 1].votes
                    : 0;
            
                _writeCheckpoint(
                    dstRep,
                    id,
                    dstRepNum,
                    dstRepOld,
                    dstRepOld + amount
                );
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint256 id,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal virtual {

        if (nCheckpoints != 0 && checkpoints[delegatee][id][nCheckpoints - 1].fromTimestamp == block.timestamp) {
            checkpoints[delegatee][id][nCheckpoints - 1].votes = _safeCastTo216(newVotes);
        } else {
            checkpoints[delegatee][id][nCheckpoints] = Checkpoint(_safeCastTo40(block.timestamp), _safeCastTo216(newVotes));

            // Won't realistically overflow.
            ++numCheckpoints[delegatee][id];
        }

        emit DelegateVotesChanged(delegatee, id, oldVotes, newVotes);
    }

    function _safeCastTo40(uint256 x) internal pure virtual returns (uint40 y) {
        if (x >= (1 << 40)) revert Overflow();

        y = uint40(x);
    }

    function _safeCastTo216(uint256 x)
        internal
        pure
        virtual
        returns (uint216 y)
    {
        if (x >= (1 << 216)) revert Overflow();

        y = uint216(x);
    }

}