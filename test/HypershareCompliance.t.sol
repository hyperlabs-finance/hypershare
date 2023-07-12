// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "./utils/Utils.sol";

import "../src/Hypershare/HypershareCompliance.sol";

contract HypershareComplianceTest is Test {
    
    // Utils
    Utils public _utils;

    // Compliance
    HypershareCompliance public _compliance;

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
		_compliance = new HypershareCompliance(address(101));
    }

    //////////////////////////////////////////////
    // ADD | REMOVE CLAIM TOPICS
    //////////////////////////////////////////////

	function testAddClaimTopic() public {

        uint256 noTokens = 4;
        uint256 noClaims = 3;

        // For tokenss
        for (uint8 i = 0; i < noTokens; i++) {

            // Add topics 
            for (uint8 ii = 0; ii < noClaims; ii++)
        		_compliance.addClaimTopic(i, ii);

            // Get required topics 
            uint256[] memory claimsRequired = _compliance.getClaimTopicsRequired(i);

            assertTrue(claimsRequired.length == noClaims, "Claims required and claims added no match");

            // Compare topics 
            for (uint8 ii = 0; ii < noClaims; ii++)
                 assertTrue(claimsRequired[ii] == ii, "Topics do not match");
        }
	}

	function testRemoveClaimTopic() public {

        uint256 tokenId = 1;
        uint256 noClaims = 3;
    
        // Add topics 
        for (uint8 i = 0; i < noClaims; i++)
            _compliance.addClaimTopic(tokenId, i);
        
        // Get required topics 
        uint256[] memory claimsRequired = _compliance.getClaimTopicsRequired(tokenId);

        assertTrue(claimsRequired.length == noClaims, "Claims required and claims added no match");

        // Compare topics 
        for (uint8 ii = 0; ii < noClaims; ii++) {

            uint256 currentTopic = ii; 

            assertTrue(claimsRequired[ii] == currentTopic, "Topics do not match");

            _compliance.removeClaimTopic(tokenId, currentTopic);

            uint256[] memory claimsRequiredNew = _compliance.getClaimTopicsRequired(tokenId);

            for (uint8 iii = 0; iii < claimsRequiredNew.length; iii++)
                assertTrue(claimsRequiredNew[iii] != currentTopic, "Topics has not bee removed");

        }
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    function testSetClaimRegistry() public {

        address currentClaimReg = _compliance.getClaimRegistry();

        _compliance.setClaimRegistry(address(202));

        address newClaimReg = _compliance.getClaimRegistry();

        assertTrue(currentClaimReg != newClaimReg && newClaimReg == address(202), "Claims match");
        
    }

    function testSetWhitelistedAll() public {
        
        bool prevWhitelisted = _compliance.checkWhitelistedAll(address(202));

        assertTrue(prevWhitelisted == false, "Address is already whitelisted");

        _compliance.setWhitelistedAll(address(202), true);

        bool trueWhitelisted = _compliance.checkWhitelistedAll(address(202));
        
        assertTrue(trueWhitelisted == true, "Address is already whitelisted");

        _compliance.setWhitelistedAll(address(202), false);

        bool falseWhitelisted = _compliance.checkWhitelistedAll(address(202));
        
        assertTrue(falseWhitelisted == false, "Address is already whitelisted");
    }

    function testSetWhitelistedTokenId() public {

        uint256 tokenId = 1001;

        bool prevWhitelisted = _compliance.checkWhitelistedTokenId(tokenId, address(202));

        assertTrue(prevWhitelisted == false, "Address is already whitelisted");

        _compliance.setWhitelistedTokenId(tokenId, address(202), true);

        bool trueWhitelisted = _compliance.checkWhitelistedTokenId(tokenId, address(202));

        assertTrue(trueWhitelisted == true, "Address is already whitelisted");

        _compliance.setWhitelistedTokenId(tokenId, address(202), false);

        bool falseWhitelisted = _compliance.checkWhitelistedTokenId(tokenId, address(202));

        assertTrue(falseWhitelisted == false, "Address is already whitelisted");
        
    }


    // #TODO, with HB

    // testCheckCanTransferBatch

}