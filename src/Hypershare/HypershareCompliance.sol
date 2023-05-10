// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import 'openzeppelin-contracts/contracts/access/Ownable.sol';
import '.././interface/IHypershareCompliance.sol';

// Interfaces
import '.././interface/IHyperbaseClaimRegistry.sol';

/**

    HypershareCompliance works in tandem with Hypershare and the HyperbaseClaimRegistry. 
    HypershareCompliance records what attributes an prospective shareholder must have in order to
    receive shares. These attributes are known as claims. When a share transfer is initiated the 
    HypershareCompliance contract iterates through the neccesary claims, comparing them against
    the claims held by the prospective shareholder in the HyperbaseClaimRegistry. 

 */

contract HypershareCompliance is IHypershareCompliance, Ownable {

  	////////////////
    // INTERFACES
    ////////////////

    /**
     * @dev Claims reg contract.
     */
    IHyperbaseClaimRegistry private _claimRegistry;

  	////////////////
    // STATE
    ////////////////

    /**
     * @dev Mapping from token ID to claims topics that will be required to receive shares.
     */
    mapping(uint256 => uint256[]) private _claimTopicsRequired;
    
    /**
     * @dev Mapping from user address to bool exemption status for all tokens.
     */
    mapping(address => bool) private _whitelistedAll;
    
    /**
     * @dev Mapping from token ID to user address to bool exemption status.
     */
    mapping(uint256 => mapping(address => bool)) public _whitelistedTokenId;

  	////////////////
    // CONSTRUCTOR
    ////////////////

    constructor(
        address claims
    ) {
        setClaimRegistry(claims);
    }

  	////////////////
    // MODIFIER
    ////////////////

    /**
     * @dev Ensure the claim topic does not already exist.
     * @param tokenId The token ID to add the topic on.
     * @param claimTopic The claim topic to query.
     */
    modifier topicNotExists(
        uint256 tokenId, 
        uint256 claimTopic
    ) {
        for (uint256 i = 0; i < _claimTopicsRequired[tokenId].length; i++)
            if (_claimTopicsRequired[tokenId][i] == claimTopic)
                revert TopicExists();
        _;
    }

    //////////////////////////////////////////////
    // ADD | REMOVE CLAIM TOPICS
    //////////////////////////////////////////////

    /**
     * @dev Adds a new claim topic that will be enforced for the token. All token recipients must have this
     * claim unless exempt via whitelist.
     *
     * @param tokenId The token ID to enforce the new topic on.
     * @param claimTopic The claim topic to be enforced.
     */
    function addClaimTopic(
        uint256 tokenId, 
        uint256 claimTopic
    )
        public
        onlyOwner
        topicNotExists(tokenId, claimTopic)
    {
        // Add topic 
        _claimTopicsRequired[tokenId].push(claimTopic);

        // Event
        emit AddedClaimTopic(tokenId, claimTopic);
    }

    /**
     * @dev Remove one of the claim topics required for holders to receive shares.
     * @param tokenId The token ID to enforce on.
     * @param claimTopic The claim topic to be enforced.
     */
    function removeClaimTopic(
        uint256 tokenId, 
        uint256 claimTopic
    )
        public
        onlyOwner
    {
        // Iterate through and remove the topic
        for (uint256 i = 0; i < _claimTopicsRequired[tokenId].length; i++)
            if (_claimTopicsRequired[tokenId][i] == claimTopic) {
                _claimTopicsRequired[tokenId][i] = _claimTopicsRequired[tokenId][_claimTopicsRequired[tokenId].length - 1];
                _claimTopicsRequired[tokenId].pop();
                emit RemovedClaimTopic(tokenId, claimTopic);
                break;
            }
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    /**
     * @dev Sets the address of the central claims registry.
     * @param claimRegistry The address of the new claims registry. 
     */
    function setClaimRegistry(
        address claimRegistry
    )
        public
        onlyOwner
    {
        _claimRegistry = IHyperbaseClaimRegistry(claimRegistry);
        emit UpdatedClaimRegistry(claimRegistry);
    }
    
    /**
     * @dev Sets boolean if an address is whitelisted for all.
     * @param account To add or remove whitelisted status from.
     * @param whitelisted Boolean as to if the account should be exempt.
     */
    function setWhitelistedAll(
        address account, 
        bool whitelisted
    )
        external
        onlyOwner
    {
        _whitelistedAll[account] = whitelisted;
    }

    /**
     * @dev Sets boolean if an address is whitelisted for a particular token.
     * @param tokenId The id of the token to add or remove whitelisted status for the user.
     * @param account To add or remove whitelisted status from.
     * @param whitelisted Boolean as to if the account should be exempt.
     */
    function setWhitelistedTokenId(
        uint256 tokenId, 
        address account,
        bool whitelisted
    )
        external
        onlyOwner
    {
        _whitelistedTokenId[tokenId][account] = whitelisted;
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    /**
     * @dev Returns the address of central claims registry.
     */
    function getClaimRegistry()
        external
        view
        returns (address)
    {
        return address(_claimRegistry);
    }

    /**
     * @dev Returns an array of the required claim topics for the token.
     * @param tokenId The token ID to return claims for.
     */
    function getClaimTopicsRequired(
        uint256 tokenId
    )
        external
        view
        returns (uint256[] memory)
    {
        return _claimTopicsRequired[tokenId];
    }
    
    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////
    
    /**
     * @dev Returns boolean as to the elligibility of batch transfer.
     * @param from Address to transfer from.
     * @param to Address to transfer tokens to.
     * @param tokenIds An array of the token IDs that are being transfered.
     * @param amounts The specific quantities of tokens that are being transfered per token ID.
     */
    function checkCanTransferBatch(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    )
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIds.length; i++)
            if (!checkRecieverIsElligible(tokenIds[i], to))
                return false;
        return true;
    }

    /**
     * @dev Returns boolean as to the elligibility of a receiver by iterating through the required
     * claims and ensuring that the receiver has them in claim registry (unless the user is exempt).
     *
     * @param tokenId The id of the token to check receiver elligibility on.
     * @param account The address of the account to check elligibility on.
     */
    function checkRecieverIsElligible(
        uint256 tokenId, 
        address account
    )
        public
        view
        returns (bool)
    {
        // Sanity checks
        if (account == address(0))
            return false;

        // If no claims required or exempt return true
        if (_claimTopicsRequired[tokenId].length == 0 || _whitelistedAll[account] || _whitelistedTokenId[tokenId][account])
            return true;

        else {
            // Iterate through required claims
            for (uint256 i = 0; i < _claimTopicsRequired[tokenId].length; i++) {

                // Get claim ids by the topic of the required claim
                bytes32[] memory claimIds = _claimRegistry.getClaimIdsByTopic(account, _claimTopicsRequired[tokenId][i]);
                
                // If the subject does not have any claims corresponding to the required topics
                if (claimIds.length == 0)
                    return false;
                
                // Iterate through claims by tokenId and check validity
                for (uint256 ii = 0; ii < claimIds.length; ii++)
                    if (!_claimRegistry.checkIsClaimValidById(account, claimIds[ii]))
                        return false;
            }
            return true;
        }
    }

    /** 
     * @dev Returns boolean as to if the user is in question has whitelisted status for all tokens.
     * @param account The account of the user to query.
     */
    function checkIsWhitelistedAll(
        address account
    )
        public
        view
        returns (bool)
    {
        return _whitelistedAll[account];
    }

    /** 
     * @dev Returns boolean as to if the user is question has whitelisted status for a specific token.
     * @param tokenId The token to check for whitelisted status on. 
     * @param account The account of the user to query.
     */
    function checkIsWhitelistedTokenId(
        uint256 tokenId, 
        address account
    )
        public
        view
        returns (bool)
    {
        return _whitelistedTokenId[tokenId][account];
    }
}