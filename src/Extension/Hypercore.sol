// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

/**

	TODO, reduce this to a generalised extension interface inhereted by all Hypercores.

 */

contract Hypercore is IHypercore {

    //////////////////////////////////////////////
    // HYPERCORE FUNCTIONS
    //////////////////////////////////////////////

    function setHypercore(
        bytes calldata hypercoreData
    )
        public
        nonReentrant
        virtual
    {
        () = abi.decode(hypercoreData, ());
        
        emit HypercoreSet(hypercoreData);
    }

    function callHypercore(
        bytes calldata hypercoreData
    )
        public
        returns (bytes calldata returnData)
    {
        () = abi.decode(hypercoreData, ());

        // Function stuff

        returnData = hypercoreData; // #TODO

        emit HypercoreCalled(hypercoreData);
    }

}