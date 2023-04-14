// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import '../Interface/IHypershareRegistry.sol';
import 'openzeppelin-contracts/contracts/access/Ownable.sol';

// Calls
import '../Interface/IHyperbaseIdentityRegistry.sol';
import '../Interface/IHypershare.sol';

// #TODO Refactor shareholder limits for total across share types and intra-share limits + issuer total limits + issuer intra-share limit

contract HypershareRegistry is IHypershareRegistry, Ownable  {

    ////////////////
    // INTERFACES
    ////////////////

    // The share contract instance
    IHypershare _share;

    // The Hypershare identity reg
    IHyperbaseIdentityRegistry _identity;

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
    mapping(uint256 => uint256) public _shareholderLimit;
    
    // Mapping from token ID to minimum share holding, transfers that result in holdings that fall bellow the mininmum will fail 
    mapping(uint256 => uint256) public _shareholdingMinimum;
    
    // Mapping from token ID to non-divisible bool, transfers that result in divisible holdings will fail
    mapping(uint256 => bool) public _shareholdingNonDivisible;

    // Mapping from account address to bool for frozen y/n across all tokens
    mapping(address => bool) public _frozenAll;

    // Mapping from token ID to account address to bool for frozen y/n
    mapping(uint256 => mapping(address => bool)) public _frozenShareType;

    // Mapping from token ID to mapping from account address to uint amount of shares frozen
	mapping(uint256 => mapping(address => uint256)) public _frozenShares;

    ////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        address share,
        address identities
    ) {
        setShare(share);
        setIdentities(identities);   
    }
        
    ////////////////
    // MODIFIERS
    ////////////////
    
    // Ensure that only the hypershare contract can call this function
    modifier onlyShare() {
        if (msg.sender == address(_share))
            revert OnlyShareContract();
        _;
    }

    // Ensure that only hypershare or owner can call this function 
    modifier onlyShareOrOwner() {
        if (msg.sender == address(_share) || msg.sender == owner())
            revert OnlyShareContractOrOwner();
        _;
    }

    // Ensure that ids and amounts are equal
    modifier equalIdsAmounts(
        uint256[] memory ids,
        uint256[] memory amounts
    ) {
        if (ids.length != amounts.length)
           revert UnequalAmountsIds();    
        _;
    }

    // Ensure that ids, accounts and amounts are equal
    modifier equalIdsAccountsAmounts(
        uint256[] memory ids,
        address[] memory accounts,
        uint256[] memory amounts
    ) {
        if (accounts.length != ids.length && ids.length != amounts.length)
            revert UnequalAccountsAmountsIds();   
        _;
    }

    //  Ensure the account has sufficient unfrozen shares
    modifier sufficientUnfrozenShares(
        uint256 id,
        address account,
        uint256 amount
    ) {
        if (_share.balanceOf(account, id) <= (_frozenShares[id][account] + amount))
            revert ExceedsUnfrozenBalance();
        _;
    }

    // Ensure that the new shareholder limit is not less than the current amount of shareholders
    modifier notLessThanHolders(
        uint256 holderLimit,
        uint256 id
    ) {
        if (holderLimit < _shareholders[id].length)
            revert LimitLessThanCurrentShareholders();
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
        equalIdsAmounts(ids, amounts)
        returns (bool)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            if (!transferred(from, to, ids[i], amounts[i]))
                revert TransferFailed();
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
        bool shareholdingNonDivisible
    )
        public
        onlyShareOrOwner
    {
        setShareholderLimit(shareholderLimit, id);   
        setShareholdingMinimum(id, shareholdingMinimum);
        setNonDivisible(id);
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
        updateShareholders(to, id);
    }
    
    // Update the cap table on burn
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
    }

    //////////////////////////////////////////////
    // UPDATES
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
            _shareholderCountries[id][_identity.getCountryByAddress(account)]++;
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
            _shareholderCountries[id][_identity.getCountryByAddress(from)]--;

        }
    }

    // Update the unfrozen balance that is available to transfer post transfer
    function updateUnfrozenShares(
        address from,
        uint256 id,
        uint256 amount
    )
        internal
    {
        if (from != address(0)) {
            uint256 freeBalance = _share.balanceOf(from, id) - (_frozenShares[id][from]);
            if (amount > freeBalance) {
                uint256 tokensToUnfreeze = amount - (freeBalance);
                _frozenShares[id][from] = _frozenShares[id][from] - (tokensToUnfreeze);
                emit SharesUnfrozen(id, from, tokensToUnfreeze);
            }
        }
    }

    //////////////////////////////////////////////
    // FREEZE | UNFREEZE
    //////////////////////////////////////////////

    // Set a batch of addresses to frozen all
    function batchSetFrozenAll(
        address[] memory accounts,
        bool[] memory freeze
    )
        public
        onlyShareOrOwner 
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            setFrozenAll(accounts[i], freeze[i]);
        }
    }

    // Freeze all interactions on an account
    function setFrozenAll(
        address account,
        bool freeze
    )
        public
        onlyShareOrOwner 
    {
        // Mapping from account address to bool for frozen y/n across all tokens
        _frozenAll[account] = freeze;

        // Events
        emit UpdateFrozenAll(account, freeze);
    }

    // Set a batch of addresses to frozen
    function batchSetFrozenShareType(
        uint256[] memory ids,
        address[] memory accounts,
        bool[] memory freeze
    )
        public
        onlyShareOrOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            setFrozenShareType(ids[i], accounts[i], freeze[i]);
        }
    }
    
    // Set an address to frozen
    function setFrozenShareType(
        uint256 id,
        address account,
        bool freeze
    )
        public
        onlyShareOrOwner 
    {
        _frozenShareType[id][account] = freeze;

        // Event
        emit UpdateFrozenShareType(id, account, freeze);
    }

    // Freeze a portion of shares for a batch of accounts
    function batchFreezeShares(
        uint256[] memory ids,
        address[] memory accounts,
        uint256[] memory amounts
    )
        public
        equalIdsAccountsAmounts(ids, accounts, amounts)
    {
        for (uint256 i = 0; i < accounts.length; i++)
            freezeShares(ids[i], accounts[i], amounts[i]);
    }

    // Freeze a portion of shares for a single account
    function freezeShares(
        uint256 id,
        address account,
        uint256 amount
    )
        public
        onlyShareOrOwner
        sufficientUnfrozenShares(id, account, amount)
    {
        _frozenShares[id][account] = _frozenShares[id][account] + (amount);
        emit SharesFrozen(id, account, amount);
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
    
    // Return bool if the transfer passes
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
        if (!checkIsNotFrozenAllTransfer(from, to))
            revert AccountFrozen();

        if (!checkIsNotFrozenShareTypeTransfer(id, from, to))
            revert FrozenSharesAccount();

        if (!checkIsNotFrozenSharesTransfer(amount, id, from))
            revert ExceedsUnfrozenBalance();

        if (!checkIsWithinShareholderLimit(id))
            revert ExceedsMaximumShareholders();

        if (!checkIsAboveMinimumShareholdingTransfer(to, from, id, amount))
            revert BelowMinimumShareholding();

        if (!checkIsNonDivisibleTransfer(to, from, id, amount))
            revert ShareDivision();

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
        // Standard transfer
        if (from != address(0) && to != address(0)) 
            if (checkIsAboveMinimumShareholding(id, _share.balanceOf(to, id) - amount) && checkIsAboveMinimumShareholding(id, _share.balanceOf(from, id) + amount))
                return true;    
            else
                return false;
        // Mint
        else if (from == address(0) && to != address(0))
            if (checkIsAboveMinimumShareholding(id, _share.balanceOf(to, id) + amount))
                return true;
            else
                return false;
        // Burn
        else if (from != address(0) && to == address(0))
            if (checkIsAboveMinimumShareholding(id, _share.balanceOf(from, id) - amount))
                return true;
            else
                return false;
        else 
            return false;
    }

    // #TODO desc
    function checkIsNonDivisibleTransfer(
        address to,
        address from,
        uint256 id,
        uint256 amount
    )
        public
        view
        returns (bool)
    {   
        // If enforcing non-divisisibility
        if (_shareholdingNonDivisible[id]) {
            // Standard transfer
            if (from != address(0) && to != address(0)) 
                if (checkIsNonDivisible(_share.balanceOf(to, id) - amount) && checkIsNonDivisible(_share.balanceOf(from, id) + amount))
                    return true;
                else
                    return false;    
            // Mint
            else if (from == address(0) && to != address(0))
                if (checkIsNonDivisible(_share.balanceOf(to, id) + amount))
                    return true;
                else
                    return false;
            // Burn
            else if (from != address(0) && to == address(0))
                if (checkIsNonDivisible(_share.balanceOf(from, id) - amount))
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
    function checkIsNotFrozenShareTypeTransfer(
        uint256 id,
        address from,
        address to
    )
        public
        view
        returns (bool)
    {
        if (!_frozenShareType[id][to] && !_frozenShareType[id][from])
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
    function checkIsNonDivisible(
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

    // Checks value exceeds minimum shareholding
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

    // Sets the hypershare contract
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

    // Sets the identity registry contract
    function setIdentities(
        address identity
    )
        public 
        onlyShareOrOwner
    {
        _identity = IHyperbaseIdentityRegistry(identity);

        // Event
        emit UpdatedHyperbaseIdentityregistry(identity);
    }

    // Sets the holder limit
    function setShareholderLimit(
        uint256 holderLimit,
        uint256 id
    )
        public
        onlyShareOrOwner
        notLessThanHolders(holderLimit, id)
    {
        // Set holder limit
        _shareholderLimit[id] = holderLimit;

        // Event
        emit ShareholderLimitSet(id, holderLimit);
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
    // Set transfers that are not modulus zero e18
    function setNonDivisible(
        uint256 id
    )
        public
        onlyShareOrOwner 
    {
        if (!_shareholdingNonDivisible[id]) {
            
            // Set divisibleity
            _shareholdingNonDivisible[id] = true;

            // Event
            emit NonDivisible(id, true);
        }
        else if (_shareholdingNonDivisible[id]) {
            
            // Set divisibleity
            _shareholdingNonDivisible[id] = false;

            // Event
            emit NonDivisible(id, false);
        }
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    // Gets address of shareholder by index
    function getHolderAt(
        uint256 index,
        uint256 id
    )
        public
        view
        returns (address)
    {
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

    // Returns bool y/n share type is non-divisible 
    function getNonDivisible(
        uint256 id
    )
        public
        view
        returns (bool)
    {
        return _shareholdingNonDivisible[id];
    }

    // Returns frozen shares of an account
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
   
}