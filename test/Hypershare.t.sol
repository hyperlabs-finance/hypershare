// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "./utils/Utils.sol";

import "../src/Hypershare/Hypershare.sol";
import "../src/Hypershare/HypershareRegistry.sol";

contract HypershareTest is Test {
    
    Hypershare public _hypershare;
    HypershareRegistry public _registry;
    
    Utils public _utils;
    
    uint256 _noShareholders = 4;
    
    address[] public _shareholders;
    uint256[] public _shares;

    function setUp() public {

        // Get utils
        _utils = new Utils();

        // Create testing payees
        _shareholders = _utils.createUsers(_noShareholders);

        // For number of payees give each a share of 1
        for (uint256 i = 0; i < _shareholders.length; i++)
            _shares.push(100e18); // 100 shares each

        // Set up contracts
        _hypershare = new Hypershare(
            "https://token-uri.com",
            address(0),
            address(0)
        ); 

        _registry = new HypershareRegistry(
            address(_hypershare),
            address(0)
        );

	    _hypershare.setRegistry(address(_registry));

    }

    function testNewToken() public {
        
        uint256 startingTokens = _hypershare.getTotalTokens();

        uint256 _maxNoShareholders = 10;
        uint256 _minimumShareholding = 5e18;
        bool _shareholdingNonFractional = true;
        
        _hypershare.newToken(
            _maxNoShareholders,
		    _minimumShareholding,
            _shareholdingNonFractional
	    );

        uint256 id = startingTokens + 1;

        assertTrue(_hypershare.getTotalTokens() == id);
        assertTrue(_registry.getShareholderLimit(id) == _maxNoShareholders);
        assertTrue(_registry.getShareholdingMinimum(id) == _minimumShareholding);
        assertTrue(_registry.getNonFractional(id) == _shareholdingNonFractional);

    }
    
    function testMintGroup() public {

        assertTrue(_shareholders.length == _shares.length);

        uint256 id = _hypershare.getTotalTokens();
                
        _hypershare.mintGroup(
            _shareholders,
            id,
            _shares,
            bytes("TX")
        );

        // assertTrue(_hypershare.balanceOf(_shareholders[i], id));

        // for (uint256 i = 0; i < _shareholders.length; i++)
        //     assertTrue(_hypershare.balanceOf(_shareholders[i], id) == _shares[i], "Incorrect shares");

    }
    

/*



    function testSafeTransferFrom() public {

        uint256 startBalance = _hypershare.balanceOf(_shareholders[1], 0);

        vm.prank(_shareholders[0]);

        _hypershare.safeTransferFrom(
            _shareholders[0],
            _shareholders[1],
            0,
            10e18,
            bytes("TX")
        );

        assertTrue((startBalance + 10e18) == _hypershare.balanceOf(_shareholders[1], 0));
    } 
*/

}