// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHyperbaseClaimVerifiersRegistry {

    event TrustedVerifierAdded(address indexed verifier, uint256[] claimTopics);
    event TrustedVerifierRemoved(address indexed verifier);
    event ClaimTopicsUpdated(address indexed verifier, uint256[] claimTopics);

    function addTrustedVerifier(address verifier, uint256[] calldata trustedTopics) external;
    function removeTrustedVerifier(address verifier) external;
    function updateVerifierClaimTopics(address verifier, uint256[] calldata trustedTopics) external;
    function checkIsVerifier(address verifier) external view returns (bool);
    function checkIsVerifierTrustedTopic(address verifier, uint256 topic) external view returns (bool);

}