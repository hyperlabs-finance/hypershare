// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "./utils/Utils.sol";

import "../src/Hypershare/Hypershare.sol";
import "../src/Hypershare/HypershareRegistry.sol";

// #TODO: Write static tests and then make dynamic

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

        generateShareholdersAndShares(); // #TODO: Make dynamic

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

    function generateShareholdersAndShares() public {

        // Create testing payees
        _shareholders = _utils.createUsers(_noShareholders);

        // For number of payees give each a share of 1
        for (uint256 i = 0; i < _noShareholders; i++)
            _shares.push(100 ether);

    }

    function testNewToken() public {
        
        uint256 startingTokens = _hypershare.getTotalTokens();

        uint256 _maxNoShareholders = 5;
        uint256 _minimumShareholding = 5 ether;
        bool _shareholdingNonFractional = true;
        
        _hypershare.newToken(
            _maxNoShareholders,
		    _minimumShareholding,
            _shareholdingNonFractional
	    );

        uint256 id = startingTokens + 1;

        assertTrue(_hypershare.getTotalTokens() == id, "testNewToken: incorrect token id");
        assertTrue(_registry.getShareholderLimit(id) == _maxNoShareholders, "testNewToken: incorrect: _maxNoShareholders");
        assertTrue(_registry.getShareholdingMinimum(id) == _minimumShareholding, "testNewToken: incorrect: _minimumShareholding");
        // assertTrue(_registry.checkNonFractional(id) == _shareholdingNonFractional, "testNewToken: incorrect: _shareholdingNonFractional");

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

        for (uint256 i = 0; i < _shareholders.length; i++)
            assertTrue(_hypershare.balanceOf(_shareholders[i], id) == _shares[i] && _shares[i] != 0, "testMintGroup: incorrect shares");

    }
    
    function testSafeTransferFrom() public {

        testMintGroup();

        uint256 startBalance = _hypershare.balanceOf(_shareholders[1], 0);

        vm.prank(_shareholders[0]);
        
        _hypershare.safeTransferFrom(
            _shareholders[0],
            _shareholders[1],
            0,
            10 ether,
            bytes("TX")
        );
        
        assertTrue((startBalance + 10 ether) == _hypershare.balanceOf(_shareholders[1], 0), "testSafeTransferFrom: incorrect balance after transfer");
    } 

    function testSafeTransferFrom_failFromAddressFrozenAll() public {

        testMintGroup();

        _registry.setFrozenAll(_shareholders[0], true);

        uint256 startBalance = _hypershare.balanceOf(_shareholders[1], 0);

        vm.prank(_shareholders[0]);
        
        vm.expectRevert(bytes("HypershareRegistry: Account is frozen"));

        _hypershare.safeTransferFrom(
            _shareholders[0],
            _shareholders[1],
            0,
            10 ether,
            bytes("TX")
        );

    } 

    function testSafeTransferFrom_failFromAddressFrozen() public {

        testMintGroup();

        _registry.setFrozenShareType(_hypershare.getTotalTokens(), _shareholders[0], true);

        uint256 startBalance = _hypershare.balanceOf(_shareholders[1], 0);

        vm.prank(_shareholders[0]);
        
        vm.expectRevert(bytes("HypershareRegistry: Share type is frozen on this account"));
        
        _hypershare.safeTransferFrom(
            _shareholders[0],
            _shareholders[1],
            0,
            10 ether,
            bytes("TX")
        );
    }

    function testSafeTransferFrom_failFrozenShares() public {
        
        testMintGroup();
        
        uint256 startBalance = _hypershare.balanceOf(_shareholders[1], 0);

        console.log(startBalance);
        
        _registry.freezeShares(
            _shareholders[0],
            _hypershare.getTotalTokens(),
            10 ether
        );

        vm.prank(_shareholders[0]);
        
        _hypershare.safeTransferFrom(
            _shareholders[0],
            _shareholders[1],
            0,
            80 ether,
            bytes("TX")
        );
        
        assertTrue((startBalance + 80 ether) == _hypershare.balanceOf(_shareholders[1], 0), "testSafeTransferFrom: incorrect balance after transfer");
        
        // _hypershare.safeTransferFrom(
        //     _shareholders[0],
        //     _shareholders[1],
        //     0,
        //     10e18,
        //     bytes("TX")
        // );

    }

    function testSafeTransferFrom_failMaximumShareholders() public {
        
        _noShareholders = 10;
        
        generateShareholdersAndShares();

        console.log(_shareholders.length);
        console.log(_shares.length);

        
    }

    /*
    
        require(checkIsNotFrozenSharesTransfer(amount, id, from), "HypershareRegistry: Insufficient unfrozen Balance");
        require(checkIsWithinShareholderLimit(id), "HypershareRegistry: Transfer exceeds shareholder limit");
        require(checkIsAboveMinimumShareholdingTransfer(to, from, id, amount), "HypershareRegistry: Transfer results in shareholdings below minimum");
        require(checkIsNonFractionalTransfer(to, from, id, amount), "HypershareRegistry: Transfer results in fractional shares");

    */
}