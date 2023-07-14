// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

import './interfaces/IHypercore.sol';

contract HypershareCoreManager {
    
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

    //////////////////////////////////////////////
    // HYPERCORE FUNCTIONS
    //////////////////////////////////////////////
     
    /**
     * @dev 
     * @param hypercore
     * @param hypercoreData
     */
    function _setHypercore(
        address hypercore, 
        bytes calldata hypercoreData
    )
        internal
    {

        /**
        
            for (uint256 i; i < prop.accounts.length; i++) {
                if (prop.amounts[i] != 0) 
                    hypercores[prop.accounts[i]] = !hypercores[prop.accounts[i]];
            
                if (prop.payloads[i].length != 0) IHypercore(prop.accounts[i])
                    .setHypercore(prop.payloads[i]);
            }
        
         */

    }

    /**
     * @dev 
     * @param hypercore
     * @param hypercoreData
     */
    function _callHypercores(
        address hypercore, 
        bytes calldata hypercoreData
    )
        internal
    {
        // #TODO
        for (uint 8 i = 0; i < hypercores.length; i++)
            // Validate that hypercore needs calling
                // Encode data fields 
                // _callHypercore with data
                
                // ??
                // Get return values (target, returnData)
                // If target, 
                    // _callHypercore with returnData
    }

    /**
     * @dev 
     * @param hypercore
     * @param hypercoreData
     */
    function _callHypercore(
        address hypercore, 
        bytes calldata hypercoreData
    )
        internal
    {
        // Ensure Hypercore returns bool true in from mapping of Hypercores
        if (!hypercores[hypercore] && !hypercores[msg.sender])
            revert NotHypercore();
        
        (returnData) = IHypercore(hypercore).callHypercore{value: msg.value}(operator, from, to, ids, amounts, data, hypercoreData);
        
    }


}