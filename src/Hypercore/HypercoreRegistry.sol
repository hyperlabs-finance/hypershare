// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// Inherited
import './Hypercore.sol';
import '../interface/IHypercoreRegistry.sol';

// Interfaces
import '../interface/IHyperbaseIdentityRegistry.sol';

/**

    HypercoreRegistry keeps an on-chain record of the shareholders.

 */

contract HypercoreRegistry is Hypercore, IHypercoreRegistry  {

    ////////////////
    // INTERFACES
    ////////////////

    /**
     * @dev The Hypershare identity registry.
     */ 
    IHyperbaseIdentityRegistry _identity;

    ////////////////
    // STATES
    ////////////////
	
    /**
     * Mapping from token ID to the addresses of all shareholders.
     */
    mapping(uint256 => address[]) public _shareholdersByToken;

    /**
     * Mapping from token ID to the exists status of the shareholder.
     */
    mapping(uint256 => mapping(address => bool)) public _shareholderExistsByAccountByToken;

    /**
     * Mapping from token ID to the country code to amount of shareholders per country.
     */
    mapping(uint256 => mapping(uint16 => uint256)) public _shareholderCountByCountryByToken;

    //////////////////////////////////////////////
    // TRANSFER FUNCTIONS
    //////////////////////////////////////////////

    /**
     * @dev Updates the shareholder registry to reflect a share transfer.
     * @param from The sending address. 
     * @param to The receiving address.
     * @param tokenId The token ID for the token to be transfered.
     * @param amount The integer amount of tokens to be transfered.
     */
    function transferred(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        public
        returns (bool)
    {
        updateShareholders(to, tokenId);
        pruneShareholders(from, tokenId);

        return true;
    }

    //////////////////////////////////////////////
    // UPDATES
    //////////////////////////////////////////////

    /**
     * @dev Adds a new shareholder and corresponding details to the shareholder registry.
     * @param account The address of the account to either add or update in the shareholder registry.
     * @param tokenId The token ID to add or update for the user. 
     */
    function updateShareholders(
        address account,
        uint256 tokenId
    )
        public
        // #TODO Security?
    {
        if (_shareholderExistsByAccountByToken[tokenId][account]) {
            _shareholdersByToken[tokenId].push(account);
            _shareholderExistsByAccountByToken[tokenId][account] = true;
            _shareholderCountByCountryByToken[tokenId][_identity.getCountryByAddress(account)]++;
                // #TODO, get shareholder manually or ??
        }
    }

    /**
     * @dev Rebuilds the shareholder registry and trims any shareholders who no longer have shares.
     * @param from The address of the user to remove from the shareholder registry.
     * @param tokenId The token ID in to prune the shareholder from.
     */
    function pruneShareholders(
        address from,
        uint256 tokenId
    )
        public
        // #TODO Security?
    {
        if (from != address(0) && _shareholderExistsByAccountByToken[tokenId][from]) {
            
            // If shareholder does not still have shares trim the indicies
            if (_share.balanceOf(from, tokenId) == 0) {

                for (uint8 i = 0; i < _shareholdersByToken[tokenId].length; i++)
                    if (_shareholdersByToken[tokenId][i] == from)
                        delete _shareholdersByToken[tokenId][i];

                _shareholderExistsByAccountByToken[tokenId][from] = false;
                _shareholderCountByCountryByToken[tokenId][_identity.getCountryByAddress(from)]--;
            }
        }
    }

    //////////////////////////////////////////////
    // SETTERS
    //////////////////////////////////////////////

    /**
     * @dev Sets the identity registry contract.
     * @param identity The address of the HyperbaseIdentityRegsitry contract.
     */
    function setIdentities(
        address identity
    )
        public 
    {
        _identity = IHyperbaseIdentityRegistry(identity);

        // Event
        emit UpdatedHyperbaseIdentityregistry(identity);
    }

    //////////////////////////////////////////////
    // GETTERS
    //////////////////////////////////////////////

    /**
     * @dev Returns the address of shareholder by index.
     * @param tokenId The token ID to query.
     * @param index The shareholder index.
     */
    function getHolderAt(
        uint256 tokenId,
        uint256 index
    )
        public
        view
        returns (address)
    {
        return _shareholdersByToken[tokenId][index];
    }

    /**
     * @dev Returns the number of shareholders by country.
     * @param tokenId The token ID to query.
     * @param country The country to return number of shareholders for.
     */
    function getShareholderCountByCountry(
        uint256 tokenId,
        uint16 country
    )
        public
        view
        returns (uint256)
    {
        return _shareholderCountByCountryByToken[tokenId][country];
    }

    /**
     * @dev Returns the number of shareholders.
     * @param tokenId The token ID to query.
     */
    function getShareholderCount(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        return _shareholdersByToken[tokenId].length;
    }
}