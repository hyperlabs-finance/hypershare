// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHypershareCompliance {

  	////////////////
    // ERRORS
    ////////////////

    // Claim topic already exists
    error TopicExists();
    
  	////////////////
    // EVENTS
    ////////////////

    // Add or update the claim registry
    event UpdatedClaimRegistry(address claimRegistry);
    
    // Added a new claim topic
    event AddedClaimTopic(uint256 indexed claimTopic, uint256 indexed id);

    // Removed a claim topic
    event RemovedClaimTopic(uint256 indexed claimTopic, uint256 indexed id);

    //////////////////////////////////////////////
    // ADD | REMOVE CLAIM TOPICS
    //////////////////////////////////////////////

    // Adds a new claim topic that will be enforced for the token. All token recipients must have this claim unless exempt
    function addClaimTopic(uint256 claimTopic, uint256 id) external;

    // Removes a claim topic that will be enforced for the token
    function removeClaimTopic(uint256 claimTopic, uint256 id) external;

    //////////////////////////////////////////////
    // ADD | REMOVE WHITELIST
    //////////////////////////////////////////////

    // Add to addresses that are exempt from required claim topics
    function addToWhitelist(address account) external;

    // Remove address from exempt addresses
    function removeFromWhitelist(address account) external;
    
    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    // Set the claim registry 
    function setClaimRegistry(address claims) external;

    //////////////////////////////////////////////
    // CHECKS
    //////////////////////////////////////////////
    
    // Check the elligibility of a batch transfer
    function checkCanTransferBatch(address from, address to, uint256[] memory ids, uint256[] memory amounts) external view returns (bool);

    // Checks the elligibility of a reciever by iterating through the required claims and ensure that they have them
    function checkRecieverIsElligible(address account, uint256 id) external view returns (bool);

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    // Returns the required claims of an elligible reciever by the token id 
    function getClaimTopicsRequired(uint256 id) external view returns (uint256[] memory);
    
}