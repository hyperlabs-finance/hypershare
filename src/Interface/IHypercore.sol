// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

interface IHypercore {

    ////////////////
    // EVENTS
    ////////////////

    event HypercoreSet(bytes hypercoreData);

    event HypercoreCalled(bytes hypercoreData);

    ////////////////
    // ERRORS
    ////////////////

    error NoArrayParity();

    //////////////////////////////////////////////
    // HYPERCORE FUNCTIONS
    //////////////////////////////////////////////

    function setHypercore(bytes calldata hypercoreData) external;

    function callHypercore(bytes calldata hypercoreData) external;
}