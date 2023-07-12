// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IHyperbaseIdentityRegistry {

    event IdentityRegistered(address indexed holderAddress, uint256 indexed identity);
    event IdentityRemoved(address indexed holderAddress, uint256 indexed identity);
    event IdentityUpdated(address indexed oldIdentity, address indexed newIdentity);
    event CountryUpdated(address indexed holderAddress, uint16 indexed country);

    function newIdentity(address account, uint16 country) external returns (uint256);
    function deleteIdentityByAddress(address account) external;
    function deleteIdentity(uint256 identity) external;
    function setCountry(uint256 identity,  uint16 country) external;
	function getIdentity(uint256 identity) external view returns (bool, uint16);
    function getCountry(uint256 identity) external view returns (uint16);
	function getIdentityByAddress(address account) external view returns (bool, uint16);
    function getCountryByAddress(address account) external view returns (uint16);

}