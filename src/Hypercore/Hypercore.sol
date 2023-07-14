// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

// Inherited
import 'openzeppelin-contracts/contracts/access/Ownable.sol';

// Interfaces
import '../interface/IHypershare.sol';

/**

	TODO, reduce this to a generalised extension interface inhereted by all Hypercores.

 */

contract Hypercore is IHypercore, Ownable {

    ////////////////
    // INTERFACES
    ////////////////

    /**
     * @dev The share contract instance.
     */ 
    IHypershare _share;

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
        setShare(msg.sender); 
        
        (/* fields, fields, fields */) = abi.decode(hypercoreData, (/* fields, fields, fields */));
        
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

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    /**
     * @dev Sets the hypershare contract.
     * @param share The address of the Hypershare contract.
     */
    function setShare(
        address share
    )
        public 
        onlyShareOrOwner
    {
        _share = IHypershare(share);

        // Event
        emit UpdatedHypershare(share);
    }
    
}