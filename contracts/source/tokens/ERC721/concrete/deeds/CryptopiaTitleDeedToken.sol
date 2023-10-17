// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../deeds/ITitleDeeds.sol";
import "../CryptopiaERC721.sol";

/// @title Cryptopia Title Deed Token
/// @notice Non-fungible token that represends land ownership in Cryptopia
/// @dev Implements the ERC721 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaTitleDeedToken is CryptopiaERC721, ITitleDeeds {

    /**
     *  Storage
     */
    uint public maxTokenId;


    /**
     * Roles
     */
    bytes32 constant private SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Errors
     */
    /// @dev Emitted when `tokenId` is not a valid title deed
    /// @param tokenId The token identifier
    error InvalidTitleDeed(uint tokenId);

    /// @dev Emitted when a title deed with `tokenId` already exists
    /// @param tokenId The title deed token identifier
    error TitleDeedAlreadyExists(uint tokenId);


    /**
     * Modifiers
     */
    /// @dev Throws if `tokenId` is out of bounds
    /// @param tokenId The token identifier
    modifier validTitleDeed(uint tokenId) 
    {
        if (tokenId <= 0 || tokenId >= maxTokenId) 
        {
            revert InvalidTitleDeed(tokenId);
        }
        _;
    }

    /// @dev Throws if `tokenId` is a non existing title deed
    /// @param tokenId The token identifier
    modifier nonExistingTitleDeed(uint tokenId) 
    {
        if (_exists(tokenId)) 
        {
            revert TitleDeedAlreadyExists(tokenId);
        }
        _;
    }


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
            "Cryptopia TitleDeeds", "DEED", proxyAuthenticator, initialContractURI, initialBaseTokenURI);
    }


    /// @dev Increase the max supply
    /// @param increment Number to increment max supply with
    function increaseLimit(uint increment) 
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        maxTokenId += increment;
    }


    /// @dev Retrieves the zero based tile index of the title deed with `tokenId`
    /// @param tokenId The title deed token ID
    /// @return tile index (zero based)
    function getTile(uint tokenId) 
        public virtual override view returns(uint32)
    {
        return uint32(tokenId - 1);
    }


    /// @dev Retrieve a range of owners
    /// @param skip Starting index
    /// @param take Amount of owners
    /// @return owners Token owners
    function getOwners(uint skip, uint take) 
        public virtual override view
        returns (address[] memory owners)
    {
        owners = new address[](take);
        uint tokenId = skip + 1;
        for (uint i = 0; i < take; i++)
        {
            owners[i] = _exists(tokenId) 
                ? ownerOf(tokenId) : address(0);

            tokenId++;
        }
    }


    /// @dev Mints a token to msg.sender. Coordinates can be found with (x, y) = (index % mapwidth, index / mapWidth) 
    /// @param tokenId Unique token id and tile identifier.
    function claim(uint tokenId) 
        public virtual override
    {

        // Todo: Check player pos in map


        claimFor(tokenId, msg.sender);
    }
    

    /// @dev Mints a token to account. Coordinates can be found with (x, y) = (index % mapwidth, index / mapWidth) 
    /// @param tokenId Unique token id and tile identifier.
    /// @param account Account to mint the token to
    function claimFor(uint tokenId, address account) 
        public virtual override 
        validTitleDeed(tokenId) 
        nonExistingTitleDeed(tokenId) 
    {
        _safeMint(account, tokenId);
    }
}