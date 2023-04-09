// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import './Utils/Checkpoint.sol';
import '../Interface/IHypershareRegistry.sol';
import 'openzeppelin-contracts/contracts/access/Ownable.sol';

// Calls
import '../Interface/IHyperbaseIdentityRegistry.sol';
import '../Interface/IHypershare.sol';

// #TODO https://eips.ethereum.org/EIPS/eip-5805

contract HypershareRegistry is IHypershareRegistry, Checkpoint, Ownable  {

    ////////////////
    // INTERFACES
    ////////////////

    // The share contract instance
    IHypershare _share;

    // The Hypershare identity reg
    IHyperbaseIdentityRegistry _identities;

    ////////////////
    // STATES
    ////////////////
	
    // SHAREHOLDERS
    
    // Mapping from token ID to the addresses of all shareholders
    mapping(uint256 => address[]) public _shareholders;

    // Mapping from token ID to the index of each shareholder in the array `_shareholders`
    mapping(uint256 => mapping(address => uint256)) public _shareholderIndices;

    // Mapping from token ID to the amount of _shareholders per country
    mapping(uint256 => mapping(uint16 => uint256)) public _shareholderCountries;

    // Mapping from token ID to the limit on the amount of shareholders for this token, when transfering between holders
    mapping(uint256 => uint256) public _shareholderLimit;
    
    // Mapping from token ID to minimum share holding, transfers that result in holdings that fall bellow the mininmum will fail 
    mapping(uint256 => uint256) public _shareholdingMinimum;
    
    // Mapping from token ID to non-fractional bool, transfers that result in fractional holdings will fail
    mapping(uint256 => bool) public _shareholdingNonFractional;

    // DELEGATES

    // Mapping from holder to mapping from token ID to delegate address 
    mapping(address => mapping(uint256 => address)) internal _delegates;    

    // FROZEN

    // Mapping from user address to bool for frozen y/n across all tokens
    mapping(address => bool) public _frozenAll;

    // Mapping from token ID to user address to bool for frozen y/n
    mapping(uint256 => mapping(address => bool)) public _frozenAccounts;

    // Mapping from token ID to mapping from user address to uint amount of shares frozen
	mapping(uint256 => mapping(address => uint256)) public _frozenShares;

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
        require(msg.sender == address(_share));
        _;
    }

    modifier onlyShareOrOwner() {
        require(msg.sender == address(_share) || msg.sender == owner(), "HypershareRegistry: Only token contract can call this function");
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
        returns (bool)
    {
		// Sanity checks 
		require(ids.length == amounts.length, "HypershareRegistry: Ids and amounts do not match");
        for (uint256 i = 0; i < ids.length; i++) {
            require(transferred(from, to, ids[i], amounts[i]), "HypershareRegistry: Could not transfer");
        }
        return true;
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
        returns (bool)
    {
        _checkpoint(_delegates[from][id], _delegates[to][id], id, amount);

        updateShareholders(to, id);
        pruneShareholders(from, id);
        updateUnfrozenShares(from, id, amount);

        return true;
    }

    //////////////////////////////////////////////
    // NEW TOKEN 
    //////////////////////////////////////////////
    
    function newToken(
        uint256 id,
        uint256 shareholderLimit,
        uint256 shareholdingMinimum,
        bool shareholdingNonFractional
    )
        public
        onlyShareOrOwner
    {
        setShareholderLimit(shareholderLimit, id);   
        setShareholdingMinimum(id, shareholdingMinimum);
        setNonFractional(id);
    }
    
    //////////////////////////////////////////////
    // MINT | BURN 
    //////////////////////////////////////////////    

    // Update the cap table on mint
    function mint(
        address to,
        uint256 id,
        uint256 amount
    )
        public
        onlyShare
    {
        require(amount > 0, "HypershareRegistry: No token created");
        updateShareholders(to, id);
    }
    
    // Burn tokens
    function burn(
        address account,
        uint256 id,
        uint256 amount
    )
        public
        onlyShare
    {
        updateUnfrozenShares(account, id, amount); 
        pruneShareholders(account, id);  

        // Event
    }

    //////////////////////////////////////////////
    // SHAREHOLDERS
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

            // #TODO: link this
            // _shareholderCountries[id][_identities.getCountryByAddress(account)]++;
        }
    }

    // Rebuilds the shareholder directory
    function pruneShareholders(
        address from,
        uint256 id
    )
        public
    {
        if (from != address(0) && _shareholderIndices[id][from] != 0) {
            
            // If shareholder still has shares
            if (_share.balanceOf(from, id) > 0) {
                return;
            }
            // Else trim the indicies
            uint256 holderIndex = _shareholderIndices[id][from] - 1;
            uint256 lastIndex = _shareholders[id].length - 1;
            address lastHolder = _shareholders[id][lastIndex];
            _shareholders[id][holderIndex] = lastHolder;
            _shareholderIndices[id][lastHolder] = _shareholderIndices[id][from];
            _shareholders[id].pop();
            _shareholderIndices[id][from] = 0;
            _shareholderCountries[id][_identities.getCountryByAddress(from)]--;

        }
    }

    //////////////////////////////////////////////
    // DELEGATE
    //////////////////////////////////////////////

    // Delegates voting power to an address
    function delegateTo(
        address from,
        address delegatee,
        uint256 id
    )
        external
        payable
        // #TODO
    {
        address currentDelegate = _delegates[from][id] ;

        _delegates[from][id] = delegatee;

        // Move delegates
        _checkpoint(
            currentDelegate,
            delegatee,
            id,
            _share.balanceOf(from, id)
        );

        // Event
        emit DelegateChanged(from, currentDelegate, delegatee, id);
    }

    //////////////////////////////////////////////
    // FREEZE | UNFREEZE
    //////////////////////////////////////////////

    //  
    function toggleAddressFrozenAll(
        address account,
        bool freeze
    )
        public
        onlyShareOrOwner 
    {
        // Mapping from user address to bool for frozen y/n across all tokens
        _frozenAll[account] = freeze;

        // Events
        emit AddressFrozen(account, freeze, msg.sender);
    }

    // Set an address to frozen
    function toggleAddressFrozen(
        address account,
        uint256 id,
        bool freeze
    )
        public
        onlyShareOrOwner 
    {
        _frozenAccounts[id][account] = freeze;

        // Event
        
    }

    // Set a batch of addresses to frozen
    function batchToggleAddressFrozen(
        address[] memory accounts,
        uint256[] memory ids,
        bool[] memory freeze
    )
        public
        onlyShareOrOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            toggleAddressFrozen(accounts[i], ids[i], freeze[i]);
        }
    }
    
    // Freeze a portion of shares for a batch of accounts
    function batchFreezeShares(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        public
    {
        require((accounts.length == ids.length) && (ids.length == amounts.length), "HypershareRegistry: ERC1155: accounts, ids and amounts length mismatch");   
        for (uint256 i = 0; i < accounts.length; i++) {
            freezeShares(accounts[i], ids[i], amounts[i]);
        }
    }

    // Freeze a portion of shares for a single account
    function freezeShares(
        address account,
        uint256 id,
        uint256 amount
    )
        public
        onlyShareOrOwner
    {
        uint256 balance = _share.balanceOf(account, id);
        require(balance >= _frozenShares[id][account] + amount, "HypershareRegistry: Amount exceeds available balance");
        _frozenShares[id][account] = _frozenShares[id][account] + (amount);
        emit SharesFrozen(account, amount);
    }

    // Update the unfrozen balance that is available to transfer post transfer
    function updateUnfrozenShares(
        address from,
        uint256 id,
        uint256 amount
    )
        public
    {
        if (from != address(0)) {
            uint256 freeBalance = _share.balanceOf(from, id) - (_frozenShares[id][from]);
            if (amount > freeBalance) {
                uint256 tokensToUnfreeze = amount - (freeBalance);
                _frozenShares[id][from] = _frozenShares[id][from] - (tokensToUnfreeze);
                emit SharesUnfrozen(from, tokensToUnfreeze);
            }
        }
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
            checkCanTransfer(from, to, ids[i], amounts[i]);
        }
        return true;
    }
    
    // Return bool if the transfer passes share
    function checkCanTransfer(
        address to,
        address from,
        uint256 id,
        uint256 amount
    )
        public
        view
        returns (bool)
    {
        require(checkIsNotFrozenAllTransfer(from, to), "HypershareRegistry: User is frozen");
        require(checkIsNotFrozenAccountsTransfer(id, from, to), "HypershareRegistry: Wallet is frozen");
        require(checkIsNotFrozenSharesTransfer(amount, id, from), "HypershareRegistry: Insufficient unfrozen Balance");
        require(checkIsWithinShareholderLimit(id), "HypershareRegistry: Transfer exceeds shareholder limit");
        require(checkIsAboveMinimumShareholdingTransfer(to, from, id, amount), "HypershareRegistry: Transfer results in shareholdings below minimum");
        require(checkIsNonFractionalTransfer(to, from, id, amount), "HypershareRegistry: Transfer results in fractional shares");

        return true;
    }

    // Checks that the transfer amount does not exceed the current max shareholders
    function checkIsWithinShareholderLimit(
        uint256 id
    )
        public
        view
        returns (bool)
    {
        if (_shareholderLimit[id] < _shareholders[id].length + 1)
            return true;
        else 
            return false;
    }

    // #TODO desc
    function checkIsAboveMinimumShareholdingTransfer(
        address to,
        address from,
        uint256 id,
        uint256 amount
    )
        public
        view
        returns (bool)
    {   
        if (from != address(0) && to != address(0)) 
            if (checkIsAboveMinimumShareholding(id, _share.balanceOf(to, id) - amount) && checkIsAboveMinimumShareholding(id, _share.balanceOf(from, id) + amount))
                return true;    
            else
                return false;
        else if (from == address(0) && to != address(0))
            if (checkIsAboveMinimumShareholding(id, _share.balanceOf(to, id) + amount))
                return true;
            else
                return false;
        else if (from != address(0) && to == address(0))
            if (checkIsAboveMinimumShareholding(id, _share.balanceOf(from, id) - amount))
                return true;
            else
                return false;
        else 
            return false;
    }

    // #TODO desc
    function checkIsNonFractionalTransfer(
        address to,
        address from,
        uint256 id,
        uint256 amount
    )
        public
        view
        returns (bool)
    {   

        if (_shareholdingNonFractional[id]) {
            if (from != address(0) && to != address(0)) 
                if (checkIsNonFractional(_share.balanceOf(to, id) - amount) && checkIsNonFractional(_share.balanceOf(from, id) + amount))
                    return true;
                else
                    return false;    
            else if (from == address(0) && to != address(0))
                if (checkIsNonFractional(_share.balanceOf(to, id) + amount))
                    return true;
                else
                    return false;
            else if (from != address(0) && to == address(0))
                if (checkIsNonFractional(_share.balanceOf(from, id) - amount))
                    return true;
                else
                    return false;
            else 
                return false;
        }
        else
            return true;   
    }

    // Check is not frozen for all
    function checkIsNotFrozenAllTransfer(
        address from,
        address to
    )
        public
        view
        returns (bool)
    {
        if (!_frozenAll[to] && !_frozenAll[from])
            return true;  
        else 
            return false;  
    }
    
    // Return bool address and tokens are not frozen for token id
    function checkIsNotFrozenAccountsTransfer(
        uint256 id,
        address from,
        address to
    )
        public
        view
        returns (bool)
    {
        if (!_frozenAccounts[id][to] && !_frozenAccounts[id][from])
            return true;  
        else
            return false;  
    }

    // #TODO desc
    function checkIsNotFrozenSharesTransfer(
        uint256 amount,
        uint256 id,
        address from
    )
        public
        view
        returns (bool)

    {
        if (from != address(0)) {
            if (amount <= (_share.balanceOf(from, id) - _frozenShares[id][from]))
                return true;  
            else
                return false;  
        }
        else 
            return true; 
    }

    // Return frozen all
    function checkFrozenAll(   
        address account
    )
        public
        view
        returns (bool)
    {
        return _frozenAll[account];
    }

    // Return bool that modulus of the transfer amount is equal to one (with the standard eighteen decimal places) 
    function checkIsNonFractional(
        uint256 amount
    )
        public
        pure
        returns (bool)
    {
        if (amount % 10**18 == 0)
            return true;
        else    
            return false;
    }

    // #TODO desc
    function checkIsAboveMinimumShareholding(
        uint256 id,
        uint256 amount
    )
        public
        view
        returns (bool)
    {
        if (_shareholdingMinimum[id] <= amount)
            return true;   
        else
            return false;
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    // #TODO: desc
    function setShare(
        address share
    )
        public 
        onlyShareOrOwner
    {
        _share = IHypershare(share);
    }

    // Sets the holder limit as required for share purpose for transferees
    function setShareholderLimit(
        uint256 holderLimit,
        uint256 id
    )
        public
        onlyShareOrOwner
    {
        // Set holder limit
        _shareholderLimit[id] = holderLimit;

        // Event
        emit HolderLimitSetTransfer(holderLimit, id);
    }
    
    // Sets the minimum shareholding on transfers
    function setShareholdingMinimum(
        uint256 id,
        uint256 minimumAmount
    )
        public
        onlyShareOrOwner
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
        onlyShareOrOwner 
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

    // SHAREHOLDERS

    // #TODO desc
    function getHolderAt(
        uint256 index,
        uint256 id
    )
        public
        view
        returns (address)
    {
        require(index < _shareholders[id].length, "HypershareRegistry: Shareholder doesn't exist");
        return _shareholders[id][index];
    }

    // Returns the shareholder for investor transfers
    function getShareholderLimit(
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        return _shareholderLimit[id];
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

    // Returns the minimum shareholding
    function getShareholdingMinimum(
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        return _shareholdingMinimum[id];
    }

// Returns bool y/n share type is non-fractional 
    function getNonFractional(
        uint256 id
    )
        public
        view
        returns (bool)
    {
        return _shareholdingNonFractional[id];
    }

    // DELEGATES

    // #TODO desc
    function getDelegates(
        address account,
        uint256 id
    )
        public
        view
        returns (address)
    {
        address current = _delegates[account][id];

        return
            current == address(0) 
                ? account 
                : current;
    }
    
    // #TODO desc
    function getCurrentVotes(
        address account,
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        // Won't underflow because decrement only occurs if positive `nCheckpoints`.
        unchecked {
            uint256 nCheckpoints = _numCheckpoints[account][id];

            return
                nCheckpoints != 0
                    ? _checkpoints[account][id][nCheckpoints - 1].shares
                    : 0;
        }
    }

    // #TODO desc
    function getPriorVotes(
        address account,
        uint256 id,
        uint256 timestamp
    )
        public
        view
        returns (uint256)
    {
        require(block.timestamp <= timestamp, "HypershareRegistry: "); // #TODO

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

    // FROZEN
    
    // Return frozen shares 
    function getFrozenShares(
        address account,
        uint256 id
    )
        public
        view
        returns (uint256)
    {
        return _frozenShares[id][account];
    }

    // Return frozen accounts 
    function getFrozenAccounts(
        address account,
        uint256 id
    )
        public
        view
        returns (bool)
    {
        return _frozenAccounts[id][account];
    }
    
}