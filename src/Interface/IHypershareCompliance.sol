// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHypershareCompliance {

  	////////////////
    // ERRORS
    ////////////////

    /**
     * @dev Claim topic already exists.
     */
    error TopicExists();
    
  	////////////////
    // EVENTS
    ////////////////

    /**
     * @dev Add or update the claim registry.
     */
    event UpdatedClaimRegistry(address claimRegistry);
    
    /**
     * @dev Added a new claim topic.
     */
    event AddedClaimTopic(uint256 indexed tokenId, uint256 indexed claimTopic);

    /**
     * @dev Removed a claim topic.
     */
    event RemovedClaimTopic(uint256 indexed tokenId, uint256 indexed claimTopic);

    //////////////////////////////////////////////
    // ADD | REMOVE CLAIM TOPICS
    //////////////////////////////////////////////

    function addClaimTopic(uint256 tokenId, uint256 claimTopic) external;
    function removeClaimTopic(uint256 tokenId, uint256 claimTopic) external;

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    function setClaimRegistry(address claims) external;
    function setWhitelistedAll(address account, bool whitelisted) external;
    function setWhitelistedTokenId(uint256 tokenId, address account, bool whitelisted) external;

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////
    
    function checkCanTransferBatch(address from, address to, uint256[] memory ids, uint256[] memory amounts) external view returns (bool);
    function checkRecieverIsElligible(uint256 tokenId, address account) external view returns (bool);
    function checkIsWhitelistedAll(address account) external view returns (bool);
    function checkIsWhitelistedTokenId(uint256 tokenId, address account) external view returns (bool);

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    function getClaimTopicsRequired(uint256 tokenId) external view returns (uint256[] memory);
    
}