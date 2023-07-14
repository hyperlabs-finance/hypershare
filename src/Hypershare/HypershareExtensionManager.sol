// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

import './interfaces/IHypercore.sol';

contract HypershareHypercoreManager {
    
    ////////////////
    // EVENTS
    ////////////////

    // #TODO Hypecore added
    // #TODO Hypecore removed

    ////////////////
    // ERRORS
    ////////////////

    error InitCallFail();

    error Sponsored();

    error NotHypercore();

    ////////////////
    // STATE
    ////////////////

    mapping(address => bool) public hypercores;

    address[] public hypercoreBeforeCall;
    address[] public hypercoreAfterCall;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    function init(
        address[] memory hypercores_,
        bytes[] memory hypercoresData_
    )
        public
        payable
    {
        // Ensure hypercore array parity
        if (hypercores_.length != hypercoresData_.length)
            revert NoArrayParity();

        // If has hypercores
        if (hypercores_.length != 0) {
            for (uint8 i = 0; i < hypercores_.length; i++) {
                hypercores[hypercores_[i]] = true;

                if (hypercoresData_[i].length != 0) {
                    (bool success, ) = hypercores_[i].call(hypercoresData_[i]);

                    // If init failed 
                    if (!success)
                        revert InitCallFail();
                }
            }
        }
    }

}