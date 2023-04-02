// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHyperbaseClaimRegistry {

    event ClaimRequested(bytes32 claimId, uint256 topic, uint256 scheme, address issuer, address subject, bytes signature, bytes data, string uri);
    event ClaimAdded(bytes32 claimId, uint256 topic, uint256 scheme, address issuer, address subject, bytes signature, bytes data, string uri);
    event ClaimRemoved(bytes32 claimId, uint256 topic, uint256 scheme, address issuer, address subject, bytes signature, bytes data, string uri);
    event ClaimChanged(bytes32 claimId, uint256 topic, uint256 scheme, address issuer, address subject, bytes signature, bytes data, string uri);

    event TrustedVerifierAdded(address indexed verifier, uint256[] claimTopics);
    event TrustedVerifierRemoved(address indexed verifier);
    event ClaimTopicsUpdated(address indexed verifier, uint256[] claimTopics);

    function addTrustedVerifier(address verifier, uint256[] calldata trustedTopics) external;
    function removeTrustedVerifier(address verifier) external;
    function updateVerifierClaimTopics(address verifier, uint256[] calldata trustedTopics) external;

    function addClaim(uint256 topic, uint256 scheme, address issuer, address subject, bytes memory signature, bytes memory data, string memory uri) external returns (bytes32 claimRequestId);
    function removeClaim(bytes32 claimId, address subject) external returns (bool success);
    function getClaim(bytes32 claimId, address subject) external view returns (uint256, uint256, address, bytes memory, bytes memory, string memory);
    function getClaimIdsByTopic(address subject, uint256 topic) external view returns(bytes32[] memory claimIds);
    function revokeClaim(bytes32 claimId, address subject) external returns(bool);
    function getRecoveredAddress(bytes memory sig, bytes32 dataHash) external pure returns (address addr);
    
    function checkIsVerifier(address verifier) external view returns (bool);
    function checkIsVerifierTrustedTopic(address verifier, uint256 topic) external view returns (bool);
    function checkIsClaimValidById(address subject, bytes32 claimId) external view returns (bool claimValid);
    function checkIsClaimValid(address subject, uint256 topic, bytes memory sig, bytes memory data) external view returns (bool claimValid);
    function checkIsClaimRevoked(bytes memory sig) external view returns (bool);
}