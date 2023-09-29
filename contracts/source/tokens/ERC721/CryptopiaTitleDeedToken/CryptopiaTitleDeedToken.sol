// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../CryptopiaERC721.sol";
import "./ICryptopiaTitleDeedToken.sol";

/// @title Cryptopia Title Deed Token
/// @notice Non-fungible token that represends land ownership in Cryptopia
/// @dev Implements the ERC721 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaTitleDeedToken is ICryptopiaTitleDeedToken, CryptopiaERC721 {

    /**
     *  Storage
     */
    uint public maxTokenId;


    /**
     * Roles
     */
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Modifiers
     */
    modifier inRange(uint tokenId) {
        require(tokenId > 0 && tokenId < maxTokenId, "Non-Existent Title Deed");
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


    /// @dev Increase the total supply
    /// @param increment Number to increment total supply with
    function increaseMaxTokenId(uint increment) 
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


        claimFor(tokenId, _msgSender());
    }
    

    /// @dev Mints a token to account. Coordinates can be found with (x, y) = (index % mapwidth, index / mapWidth) 
    /// @param tokenId Unique token id and tile identifier.
    /// @param account Account to mint the token to
    function claimFor(uint tokenId, address account) 
        public virtual override 
        inRange(tokenId)
    {
        require(!_exists(tokenId), "TokenId already exists");
        _safeMint(account, tokenId);
    }
}