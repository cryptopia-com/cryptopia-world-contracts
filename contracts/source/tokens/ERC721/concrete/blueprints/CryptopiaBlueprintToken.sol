// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

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
    uint private _currentTokenId; 

    /// @dev tokenId => building
    mapping(uint => bytes32) private blueprintInstances;


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


    /// @dev Retrieves the building of the blueprint with `tokenId`
    /// @param tokenId The blueprint token ID
    /// @return building unique name
    function getBuilding(uint tokenId) 
        public virtual override view   
        returns(bytes32)
    {
        return blueprintInstances[tokenId];
    }


    /**
     * System functions
     */
    /// @dev Mints a blueprint to an address
    /// @param to address of the owner of the blueprint
    /// @param building Unique building name
    function __mintTo(address to, bytes32 building)  
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
    {
        uint tokenId = _getNextTokenId();
        _mint(to, tokenId);
        _incrementTokenId();
        blueprintInstances[tokenId] = building;
    }


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


    /**
     * Private functions
     */
    /// @dev calculates the next token ID based on value of _currentTokenId
    /// @return uint for the next token ID
    function _getNextTokenId() private view returns (uint) 
    {
        return _currentTokenId + 1;
    }


    /// @dev increments the value of _currentTokenId
    function _incrementTokenId() private 
    {
        _currentTokenId++;
    }
}