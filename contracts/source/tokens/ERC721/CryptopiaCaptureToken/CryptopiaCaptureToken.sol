// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../CryptopiaERC721.sol";
import "./ICryptopiaCaptureToken.sol";


/// @title Cryptopia Capture Token
/// @dev Non-fungible token (ERC721)
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaCaptureToken is ICryptopiaCaptureToken, CryptopiaERC721 {
    
    struct Item
    {
        uint8 rarity;
        uint8 class;
        uint240 strength;
    }


    /**
     * Storage
     */
    uint private _currentTokenId; 

    /// @dev name => Item
    mapping(bytes32 => Item) public items;
    bytes32[] private itemsIndex;

    /// @dev tokenId => CaptureToken
    mapping (uint => bytes32) public tokenInstances;


    /**
     * Roles
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    /**
     * Modifiers
     */
    /// @dev Requires that an item with `name` exists
    /// @param name Unique token name
    modifier onlyExisting(bytes32 name)
    {
        require(_exists(name), "Non-existing token");
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
            "Cryptopia Capture Cards", "CAPTURE", proxyAuthenticator, initialContractURI, initialBaseTokenURI);
    }


    /// @dev Returns the amount of different items
    /// @return count The amount of different items
    function getItemCount() 
        public virtual override view 
        returns (uint)
    {
        return itemsIndex.length;
    }


    /// @dev Retreive data by item name
    /// @param name Unique item name
    /// @return rarity 0 = common, 1 = rare, 2 = legendary
    /// @return class 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @return strength influences the chance on has in capturing a creature
    function getItem(bytes32 name) 
        public virtual override view 
        returns (
            uint8 rarity,
            uint8 class,
            uint240 strength
        )
    {
        rarity = items[name].rarity;
        class = items[name].class;
        strength = items[name].strength;
    }


    /// @dev Retreive data by item token ID
    /// @param tokenId Unique token Id
    /// @return rarity 0 = common, 1 = rare, 2 = legendary
    /// @return class 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @return strength influences the chance on has in capturing a creature
    function getItemByTokenId(uint tokenId) 
        public virtual override view 
        returns (
            uint8 rarity,
            uint8 class,
            uint240 strength
        )
    {
        bytes32 name = tokenInstances[tokenId];
        rarity = items[name].rarity;
        class = items[name].class;
        strength = items[name].strength;
    }


    /// @dev Retreive a range of items
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return name Item name
    /// @return rarity 0 = common, 1 = rare, 2 = legendary, 3 = master
    /// @return class 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial, 999 = All
    /// @return strength influences the chance on has in capturing a creature
    function getItems(uint skip, uint take) 
        public virtual override view  
        returns (
            bytes32[] memory name,
            uint8[] memory rarity,
            uint8[] memory class,
            uint240[] memory strength
        )
    {
        name = new bytes32[](take);
        rarity = new uint8[](take);
        class = new uint8[](take);
        strength = new uint240[](take);

        uint index = skip;
        for (uint i = 0; i < take; i++)
        {
            name[i] = itemsIndex[index];
            rarity[i] = items[name[i]].rarity;
            class[i] = items[name[i]].class;
            strength[i] = items[name[i]].strength;
            index++;
        }
    }


    /// @dev Add or update items
    /// @param names Unique capture token name
    /// @param rarities 0 = common, 1 = rare, 2 = legendary, 3 = master
    /// @param classes 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @param strengths influences the chance on has in capturing a creature
    function setItems(bytes32[] memory names, uint8[] memory rarities, uint8[] memory classes, uint240[] memory strengths) 
        public virtual override 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < names.length; i++)
        {
            // Add item
            if (!_exists(names[i]))
            {
                itemsIndex.push(names[i]);
            }

            // Set item
            items[names[i]].rarity = rarities[i];
            items[names[i]].class = classes[i];
            items[names[i]].strength = strengths[i];
        }
    }


    /// @dev Mints a token to an address
    /// @param to address of the future owner of the token
    /// @param name Unique capture token name
    function mintTo(address to, bytes32 name)  
        public override 
        onlyRole(MINTER_ROLE) 
        onlyExisting(name) 
    {
        uint tokenId = _getNextTokenId();
        _mint(to, tokenId);
        _incrementTokenId();

        tokenInstances[tokenId] = name;
    }


    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    /// @param tokenId The token that's burned
    function burn(uint tokenId) 
        public override 
        onlyRole(MINTER_ROLE)  
    {
        _burn(tokenId);
    }


    /**
     * Private functions
     */
    /// @dev calculates the next token ID based on value of _currentTokenId
    /// @return uint for the next token ID
    function _getNextTokenId() private view returns (uint) {
        return _currentTokenId + 1;
    }


    /// @dev increments the value of _currentTokenId
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    
    /// @dev True if a creature with `name` exists
    /// @param name of the creature
    function _exists(bytes32 name) internal view returns (bool) 
    {
        return items[name].strength != 0;
    }
}