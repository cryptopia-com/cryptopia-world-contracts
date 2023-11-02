// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../blueprints/IBlueprints.sol";
import "../CryptopiaERC721.sol";

/// @title Cryptopia Blueprints
/// @notice Non-fungible token that represends blueprints in Cryptopia
/// @dev Implements the ERC721 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaBlueprintToken is CryptopiaERC721, IBlueprints {

    /**
     * Storage
     */
    mapping(uint => bytes32) public structures;


    /** 
     * Public functions
     */
    /// @dev Contract initializer sets shared base uri
    /// @param proxyAuthenticator Whitelist for easy trading
    /// @param initialContractURI Location to contract info
    /// @param initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    function initialize(
        address proxyAuthenticator, 
        string memory initialContractURI, 
        string memory initialBaseTokenURI) 
        public initializer 
    {
        __CryptopiaERC721_init(
            "Cryptopia Blueprints", "BLUERPINT", proxyAuthenticator, initialContractURI, initialBaseTokenURI);
    }


    /// @dev Retrieves the structure of the blueprint with `tokenId`
    /// @param tokenId The blueprint token ID
    /// @return structure unique name
    function getStructure(uint tokenId) 
        public virtual override view   
        returns(bytes32)
    {
        return structures[tokenId];
    }


    /** 
     * System functions
     */
    /// @dev Destroys `tokenId`.
    /// @notice The approval is cleared when the token is burned.
    /// @notice This is an internal function that does not check if the sender is authorized to operate on the token.
    /// @param tokenId The blueprint token ID 
    function __burn(uint tokenId) 
        public virtual override
        onlyRole(SYSTEM_ROLE)  
    {
        _burn(tokenId);
    }
}