// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHypershareCompliance {

    event claimRegistrySet(address claimRegistry_);
    event claimTopicAdded(uint256 indexed claimTopic, uint256 indexed id);
    event claimTopicRemoved(uint256 indexed claimTopic, uint256 indexed id);

    function addClaimTopic(uint256 claimTopic, uint256 id) external;
    function removeClaimTopic(uint256 claimTopic, uint256 id) external;
    function getClaimTopicsRequired(uint256 id) external view returns (uint256[] memory);

    function checkRecieverIsElligible(address account, uint256 id) external view returns (bool);
    function checkCanTransferBatch(address from, address to, uint256[] memory ids, uint256[] memory amounts) external view returns (bool);
}