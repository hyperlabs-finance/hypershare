// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "./utils/Utils.sol";

import "../src/Hypershare/HypercoreRegistry.sol";

contract HypercoreRegistryTest is Test {
    
    // Utils
    Utils public _utils;

    // Compliance
    HypercoreRegistry public _registry;

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
		_registry = new HypercoreRegistry(address(this), address(1));

    }


    //////////////////////////////////////////////
    // NEW TOKEN 
    //////////////////////////////////////////////
    
    function testcreateToken() public {

        uint256 tokenId = 1;
        uint256 shareholderLimit = 100;
        uint256 shareholdingMinimum = 5 ether;
        bool shareholdingNonDivisible = true;

		_registry.createToken(tokenId, shareholderLimit, shareholdingMinimum, shareholdingNonDivisible);

        uint256 newShareholderLimit = _registry.getShareholderLimit(tokenId);
		uint256 newShareholdingMinimum = _registry.getShareholdingMinimum(tokenId);
		bool newShareholdingNonDivisible = _registry.checkNonDivisible(tokenId);

		assertTrue(shareholderLimit == newShareholderLimit, "Shareholder limit mismatch");
		assertTrue(shareholdingMinimum == newShareholdingMinimum, "Shareholding minimum mismatch");
		assertTrue(shareholdingNonDivisible == newShareholdingNonDivisible, "Nondivisibible mismatch");
	}

}