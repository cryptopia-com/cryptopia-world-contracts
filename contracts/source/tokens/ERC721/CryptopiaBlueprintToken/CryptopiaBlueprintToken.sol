// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../../infrastructure/authentication/IAuthenticator.sol";
import "../CryptopiaERC721.sol";
import "./ICryptopiaBlueprintToken.sol";

/// @title Cryptopia Blueprints
/// @notice Non-fungible token that represends blueprints in Cryptopia
/// @dev Implements the ERC721 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaBlueprintToken is ICryptopiaBlueprintToken, Initializable, CryptopiaERC721 {

    /**
     * Storage
     */
    mapping(uint => bytes32) public structures;

    /**
     * Roles
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


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


    /// @dev Destroys `tokenId`.
    /// @notice The approval is cleared when the token is burned.
    /// @notice This is an internal function that does not check if the sender is authorized to operate on the token.
    /// @param tokenId The blueprint token ID 
    function burn(uint tokenId) 
        public virtual override
        onlyRole(MINTER_ROLE)  
    {
        _burn(tokenId);
    }
}