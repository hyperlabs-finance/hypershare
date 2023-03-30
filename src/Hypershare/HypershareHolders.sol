// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import './Utils/Checkpoint.sol';
import '../Interface/IHypershareHolders.sol';
import 'openzeppelin-contracts/contracts/access/Ownable.sol';

// Calls
import '../Interface/IHyperbaseIdentityRegistry.sol';
import '../Interface/IHypershare.sol';

contract HypershareHolders is IHypershareHolders, Checkpoint, Ownable  {

    ////////////////
    // INTERFACES
    ////////////////

    IHypershare _share;
    IHyperbaseIdentityRegistry _identities;

    ////////////////
    // STATES
    ////////////////
	
    // Mapping from token ID to the addresses of all shareholders
    mapping(uint256 => address[]) public _shareholders;

    // Mapping from token ID to the index of each shareholder in the array `_shareholders`
    mapping(uint256 => mapping(address => uint256)) public _shareholderIndices;

    // Mapping from token ID to the amount of _shareholders per country
    mapping(uint256 => mapping(uint16 => uint256)) public _shareholderCountries;

    // Mapping from token ID to the limit on the amount of shareholders for this token, when transfering between holders
    mapping(uint256 => uint256) public _shareholderLimitTransfer;
    
    // Mapping from token ID to the hard limit on the amount of shareholders for this token i.e. 1000 for US companies
    mapping(uint256 => uint256) public _shareholderLimitIssuer;

    // Mapping from token ID to minimum share holding, transfers that result in holdings that fall bellow the mininmum will fail 
    mapping(uint256 => uint256) public _shareholdingMinimum;
    
    // Mapping from token ID to non-fractional bool, transfers that result in fractional holdings will fail
    mapping(uint256 => bool) public _shareholdingNonFractional;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        address share,
        address identities
    ) {
        _share = IHypershare(share);
        // Event 
        
        _identities = IHyperbaseIdentityRegistry(identities);   
        // Event
    }
        
    ////////////////
    // MODIFIERS
    ////////////////
    
    modifier onlyShare() {
        require(msg.sender == _share);
        _;
    }

    //////////////////////////////////////////////
    // TRANSFER FUNCTIONS
    //////////////////////////////////////////////

    // Transferred batch
    function batchTransferred(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        public
        onlyShare
    {
		// Sanity checks 
		require(ids.length == amounts.length, "Ids and amounts do not match");
        for (uint256 i = 0; i < ids.length; i++) {
            transferred(from, to, ids[i], amounts[i]);
        }
    } 

    // Update the cap table on transfer
    function transferred(
        address from,
        address to,
        uint256 id,
        uint256 amount
    )
        public
        onlyShare
    {
        _checkpoint(from, to, id, amount);
        updateShareholders(to, id);
        pruneShareholders(from, id);
    }

    //////////////////////////////////////////////
    // CAP TABLE
    //////////////////////////////////////////////

    // Add a new shareholder to shareholders
    function updateShareholders(
        address account,
        uint256 id
    )
        public
    {
        if (_shareholderIndices[id][account] == 0) {
            _shareholders[id].push(account);
            _shareholderIndices[id][account] = _shareholders[id].length;
            _shareholderCountries[id][_identities.getCountryByAddress(account)]++;
        }
    }

    // Rebuilds the shareholder directory
    function pruneShareholders(
        address account,
        uint256 id
    )
        public
    {
        // Sanity checks
        require(_shareholderIndices[id][account] != 0, "Shareholder does not exist");
        
        // If shareholder still has shares then return
        if (_share.balanceOf(account, id) > 0) {
            return;
        }
        // Else trim the indicies
        uint256 holderIndex = _shareholderIndices[id][account] - 1;
        uint256 lastIndex = _shareholders[id].length - 1;
        address lastHolder = _shareholders[id][lastIndex];
        _shareholders[id][holderIndex] = lastHolder;
        _shareholderIndices[id][lastHolder] = _shareholderIndices[id][account];
        _shareholders[id].pop();
        _shareholderIndices[id][account] = 0;
        _shareholderCountries[id][_identities.getCountryByAddress(account)]--;
    }
	
    // Update the cap table on mint
    function created(
        address to,
        uint256 id,
        uint256 amount
    )
        public
        onlyShare
    {
        require(amount > 0, "No token created");
        _checkpoint(address(0), to, id, amount);
        updateShareholders(to, id);
    }

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////

    function checkCanTransferBatch(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        public 
        view 
        returns (bool)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            checkTransferWithinLimit(ids[i]);
        }
        return true;
    }

    // Checks that the transfer amount does not exceed the current transfer limit
    function checkTransferWithinLimit(
        uint256 id
    )
        public
        view
        returns (bool)
    {
        if (msg.sender == owner()) {
            require((_shareholders[id].length + 1) < getShareholderLimitIssuer(id), "Transfer exceeds the shareholder limit");
        }
        else {
            require((_shareholders[id].length + 1) < getShareholderLimitTransfer(id), "Transfer exceeds the shareholder limit");
        }
        // #TODO _shareholdingMinimum
        // #TODO _shareholdingNonFractional
        return true;
    }

    // Return bool that modulus of the transfer amount is equal to one (with the standard eighteen decimal places) 
    function checkIsNonFractional(
        uint256 amount,
        uint256 id
    )
        public
        view
        returns (bool)
    {
        if (_shareholdingNonFractional[id]) {
            if (amount % 10**18 == 0) return true;
            else return false;  
        }
        else return true;
    }

    //////////////////////////////////////////////
    // NON FRACTIONAL
    //////////////////////////////////////////////

    // Sets the holder limit as required for share purpose for transferees
    function setShareholderLimitTransfer(
        uint256 holderLimit,
        uint256 id
    )
        public
        onlyOwner
    {
        // Set holder limit
        _shareholderLimitTransfer[id] = holderLimit;

        // Event
        emit HolderLimitSetTransfer(holderLimit, id);
    }
    
    // Sets the holder limit as required for share purpose for issuer
    function setShareholderLimitIssuer(
        uint256 holderLimit,
        uint256 id
    )
        public
        onlyOwner
    {
        // Set holder limit
        _shareholderLimitIssuer[id] = holderLimit;

        // Event
        emit HolderLimitSetIssuer(holderLimit, id);
    }

    // Sets the minimum shareholding on transfers
    function setShareholdingMinimum(
        uint256 id,
        uint256 minimumAmount
    )
        public
        onlyOwner
    {
        // Set minimum
        _shareholdingMinimum[id] = minimumAmount;

        // Event
        emit MinimumShareholdingSet(id, minimumAmount);
    }

    // WARNING! This is extremely hard to reverse
    // Toggle transfers that are not modulus zero e18
    function setNonFractional(
        uint256 id
    )
        public
        onlyOwner 
    {
        if (!_shareholdingNonFractional[id]) {
            
            // Set fractionality
            _shareholdingNonFractional[id] = true;

            // Event
            emit NonFractional(msg.sender, id);
        }
        else if (_shareholdingNonFractional[id]) {
            
            // Set fractionality
            _shareholdingNonFractional[id] = false;

            // Event
            emit Fractional(msg.sender, id);
        }
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    // 
    function getHolderAt(
        uint256 index,
        uint256 id
    )
        public
        view
        returns (address)
    {
        require(index < _shareholders[id].length, "Shareholder doesn't exist");
        return _shareholders[id][index];
    }

    // Get for the issuer (overrides the others)
    function getShareholderLimitIssuer(
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        return _shareholderLimitIssuer[id];
    }

    // Returns the shareholder for investor transfers
    function getShareholderLimitTransfer(
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        return _shareholderLimitTransfer[id];
    }

    // Return the number of shareholders by country
    function getShareholderCountByCountry(
        uint256 id,
        uint16 country
    )
        public
        view
        returns (uint256)
    {
        return _shareholderCountries[id][country];
    }

    // Return the number of shareholders
    function getShareholderCount(
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        return _shareholders[id].length;
    }






    function getPriorShares(
        address account,
        uint256 id,
        uint256 timestamp
    )
        public
        view
        returns (uint256)
    {
        require(block.timestamp <= timestamp, ""); // #TODO

        uint256 nCheckpoints = _numCheckpoints[account][id];

        if (nCheckpoints == 0) return 0;

        // Won't underflow because decrement only occurs if positive `nCheckpoints`.
        unchecked {
            uint256 prevCheckpoint = nCheckpoints - 1;
            
            if (
                _checkpoints[account][id][prevCheckpoint].fromTimestamp <=
                timestamp
            ) return _checkpoints[account][id][prevCheckpoint].shares;

            if (_checkpoints[account][id][0].fromTimestamp > timestamp) return 0;

            uint256 lower;

            uint256 upper = prevCheckpoint;

            while (upper > lower) {
                uint256 center = upper - (upper - lower) / 2;

                Checkpoint memory cp = _checkpoints[account][id][center];

                if (cp.fromTimestamp == timestamp) {
                    return cp.shares;
                } else if (cp.fromTimestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }

            return _checkpoints[account][id][lower].shares;
        }
    }
    
    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    function setShare(

    )
        public 
        onlyOwner
    {
        
    }

}