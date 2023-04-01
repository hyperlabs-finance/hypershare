// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

contract Checkpoint {

    ////////////////
    // STATE
    ////////////////

    struct Checkpoint {
        uint40 fromTimestamp;
        uint216 shares;
    }

    // Mapping from delegate address to 
    mapping(address => mapping(uint256 => mapping(uint256 => Checkpoint))) public _checkpoints;

    // Mapping from delegate address to 
    mapping(address => mapping(uint256 => uint256)) public _numCheckpoints;

    //////////////////////////////////////////////
    // CHECKPOINT FUNCTIONS
    //////////////////////////////////////////////

    function _checkpoint(
        address srcRep,
        address dstRep,
        uint256 id,
        uint256 amount
    )
        internal
    {
        if (srcRep != dstRep && amount != 0) {
            
            if (srcRep != address(0)) {
                
                uint256 srcRepNum = _numCheckpoints[srcRep][id];

                uint256 srcRepOld;

                // Won't underflow because decrement only occurs if positive `srcRepNum`.
                unchecked {
                    srcRepOld = srcRepNum != 0
                        ? _checkpoints[srcRep][id][srcRepNum - 1].shares
                        : 0;
                }

                _writeCheckpoint(
                    srcRep,
                    id,
                    srcRepNum,
                    srcRepOld,
                    srcRepOld - amount
                );
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = _numCheckpoints[dstRep][id];

                uint256 dstRepOld;

                // Won't underflow because decrement only occurs if positive `dstRepNum`.
                unchecked {
                    dstRepOld = dstRepNum != 0
                        ? _checkpoints[dstRep][id][dstRepNum - 1].shares
                        : 0;
                }

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
        uint256 oldShares,
        uint256 newShares
    )
        internal
    {
        // Won't underflow because decrement only occurs if positive `nCheckpoints`.
        unchecked {
            if (
                nCheckpoints != 0 &&
                _checkpoints[delegatee][id][nCheckpoints - 1].fromTimestamp ==
                block.timestamp
            ) {
                _checkpoints[delegatee][id][nCheckpoints - 1]
                    .shares = uint216(newShares);
            } else {
                _checkpoints[delegatee][id][nCheckpoints] = Checkpoint(
                    uint40(block.timestamp),
                    uint216(newShares)
                );

                // Won't realistically overflow.
                ++_numCheckpoints[delegatee][id];
            }
        }
	}

}