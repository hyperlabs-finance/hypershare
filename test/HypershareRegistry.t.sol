// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "./utils/Utils.sol";

import "../src/Hypershare/HypershareRegistry.sol";

contract HypershareRegistryTest is Test {
    
    // Utils
    Utils public _utils;

    // Compliance
    HypershareRegistry public _registry;

    // Shareholders
    uint256 _noShareholders = 4;
    address[] public _shareholders;

    // Claim topics
    enum Schema {
        Certified,
        Accredited,
        SelfCertified
    }

    // Set up
    function setUp() public {

        // Get utils
        _utils = new Utils();

        // Create testing payees
        _shareholders = _utils.createUsers(_noShareholders);

        // Compliance 
		_registry = new HypershareRegistry(address(this), address(1));

    }


    //////////////////////////////////////////////
    // NEW TOKEN 
    //////////////////////////////////////////////
    
    function testNewToken() public {

        uint256 tokenId = 1;
        uint256 shareholderLimit = 100;
        uint256 shareholdingMinimum = 5 ether;
        bool shareholdingNonDivisible = true;

		_registry.newToken(tokenId, shareholderLimit, shareholdingMinimum, shareholdingNonDivisible);

		getShareholderLimit(tokenId);

		getShareholdingMinimum(tokenId);
	}

}