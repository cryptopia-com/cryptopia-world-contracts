// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../game/quests/rewards/INonFungibleQuestReward.sol";
import "../../../../game/console/rewards/INonFungibleGameConsoleReward.sol";
import "../../../../game/inventories/IInventories.sol";
import "../../ships/types/ShipSkinDataTypes.sol";
import "../../ships/IShipSkins.sol";  
import "../CryptopiaERC721.sol";

/// @title Cryptopia Ship Token Contract
/// @notice Skins that can be applied to ships to change their appearance
/// @dev Extends CryptopiaERC721, integrating ERC721 functionalities with game-specific mechanics.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaShipSkinToken is CryptopiaERC721, IShipSkins, INonFungibleQuestReward, INonFungibleGameConsoleReward {

    /// @dev Ship in Cryptopia
    struct ShipSkinData
    {
        /// @dev Index within the skinsIndex array
        uint index;

        /// @dev The ship that the skin is for 
        bytes32 ship;
    }


    /**
     * Storage
     */
    uint private _currentTokenId; 

    /// @dev name => ShipSkinData
    mapping(bytes32 => ShipSkinData) public skins;
    bytes32[] internal skinsIndex;

    /// @dev tokenId => skin
    mapping (uint => bytes32) public skinInstances;

    // Refs
    address public inventoriesContract;


    /**
     * Events
     */
    /// @dev Emitted when a skin is minted
    /// @param tokenId The id of the minted skin
    /// @param skin The name of the minted skin
    /// @param to The player or account that received the minted skin
    event ShipSkinMinted(uint indexed tokenId, bytes32 skin, address to);

    /// @dev Emitted when a skin is burned
    /// @param tokenId The id of the burned skin
    /// @param skin The name of the burned skin
    event ShipSkinBurned(uint indexed tokenId, bytes32 skin);


    /**
     * Errors
     */
    /// @dev Emitted when `skin` does not exist
    /// @param skin The skin that does not exist
    error ShipSkinNotFound(bytes32 skin);


    /**
     * Modifiers
     */
    /// @dev Requires that an item with `name` exists
    /// @param _name Unique token name
    modifier onlyExisting(bytes32 _name)
    {
        if (!_exists(_name)) 
        {
            revert ShipSkinNotFound(_name);
        }
        _;
    }


    /// @dev Contract initializer sets shared base uri
    /// @param _authenticator Whitelist
    /// @param initialContractURI Location to contract info
    /// @param initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    /// @param _inventoriesContract Contract responsible for inventories
    function initialize(
        address _authenticator, 
        string memory initialContractURI, 
        string memory initialBaseTokenURI,
        address _inventoriesContract) 
        public initializer 
    {
        __CryptopiaERC721_init(
            "Cryptopia Ship Skins", "SHIPSKIN", _authenticator, initialContractURI, initialBaseTokenURI);

        // Set refs
        inventoriesContract = _inventoriesContract;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * Admin functions
     */
    /// @dev Add or update skins
    /// @param data Skin data
    function setSkins(ShipSkin[] memory data) 
        public virtual  
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < data.length; i++)
        {
            _setSkin(data[i]);
        }
    }


    /// @dev Mint a new skin
    /// @param skin The name of the skin
    /// @param to The address to mint the skin to
    function mint(bytes32 skin, address to) 
        public virtual
        onlyRole(MINTER_ROLE)
        onlyExisting(skin)
        returns (uint tokenId)
    {
        // Mint
        tokenId = _getNextTokenId();
        _mint(to, tokenId);
        _incrementTokenId();
        skinInstances[tokenId] = skin;

        // Emit event
        emit ShipSkinMinted(tokenId, skin, to);
    }


    /**
     * Public functions
     */
    /// @dev Returns the amount of different skins
    /// @return count The amount of different skins
    function getSkinCount() 
        public virtual override view 
        returns (uint)
    {
        return skinsIndex.length;
    }


    /// @dev Retreive a skin by name
    /// @param _name Skin name (unique)
    /// @return skin a single skin 
    function getSkin(bytes32 _name) 
        public virtual override view 
        returns (ShipSkin memory skin) 
    {
        skin = _getSkin(_name);
    }


    /// @dev Retreive a skin by index
    /// @param index The index of the skin to retreive
    /// @return skin a single skin
    function getSkinAt(uint index) 
        public virtual override view 
        returns (ShipSkin memory skin)
    {
        skin = _getSkin(skinsIndex[index]);
    }


    /// @dev Retreive a rance of skins
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return skins_ range of skins
    function getSkins(uint skip, uint take) 
        public virtual override view 
        returns (ShipSkin[] memory skins_)
    {
        uint length = take;
        if (skinsIndex.length < skip + take) 
        {
            length = skinsIndex.length - skip;
        }

        skins_ = new ShipSkin[](length);
        for (uint i = 0; i < length; i++)
        {
            skins_[i] = _getSkin(skinsIndex[skip + i]);
        }
    }


    /// @dev Retreive a skin by token id
    /// @param tokenId The id of the skin to retreive
    /// @return instance a single skin instance
    function getSkinInstance(uint tokenId) 
        public virtual override view 
        returns (ShipSkinInstance memory instance)
    {
        instance = _getSkinInstance(tokenId);
    }


    /// @dev Retreive skins by token ids
    /// @param tokenIds The ids of the skins to retreive
    /// @return instances a range of skin instances
    function getSkinInstances(uint[] memory tokenIds) 
        public virtual override view 
        returns (ShipSkinInstance[] memory instances)
    {
        instances = new ShipSkinInstance[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++)
        {
            instances[i] = _getSkinInstance(tokenIds[i]);
        }
    }


    /// @dev getTokenURI() postfixed with the token ID baseTokenURI(){tokenID}
    /// @param tokenId Token ID
    /// @return uri where token data can be retrieved
    function getTokenURI(uint tokenId) 
        public virtual override view 
        returns (string memory) 
    {
        return string(abi.encodePacked(getBaseTokenURI(), skinInstances[tokenId]));
    }
    

    /**
     * System functions
     */
    /// @dev Mint a quest reward
    /// @param player The player to mint the item to
    /// @param inventory The inventory to mint the item to
    /// @param skin The item to mint
    function __mintQuestReward(address player, Inventory inventory, bytes32 skin)
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        onlyExisting(skin) 
        returns (uint tokenId)
    {
        tokenId = _mintReward(player, inventory, skin);
    }


    /// @dev Mint a reward for the game console
    /// @param player The player to mint the item to
    /// @param inventory The inventory to mint the item to
    /// @param skin The item to mint
    function __mintGameConsoleReward(address player, Inventory inventory, bytes32 skin)
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        onlyExisting(skin) 
        returns (uint tokenId)
    {
        tokenId = _mintReward(player, inventory, skin);
    }


    /// @dev Burn a skin
    /// @param tokenId The id of the skin to burn
    function __burn(uint tokenId)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        // Burn tokens
        _burn(tokenId);

        // Emit event
        emit ShipSkinBurned(tokenId, skinInstances[tokenId]);

        // Remove instance
        delete skinInstances[tokenId];
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

    
    /// @dev True if a skin with `name` exists
    /// @param _name of the skin
    function _exists(bytes32 _name) internal view returns (bool) 
    {
        return skinsIndex.length > 0 && skinsIndex[skins[_name].index] == _name;
    }


    /// @dev Add or update a skin
    /// @param skin Skin data
    function _setSkin(ShipSkin memory skin) 
        internal 
    {
        // Add skin
        if (!_exists(skin.name))
        {
            skins[skin.name].index = skinsIndex.length;
            skinsIndex.push(skin.name);
        }

        // Set skin
        ShipSkinData storage data = skins[skin.name];
        data.ship = skin.ship;
    }


    /// @dev Retreive a skin by name
    /// @param _name Skin name (unique)
    /// @return skin a single skin
    function _getSkin(bytes32 _name) 
        internal virtual view 
        returns (ShipSkin memory skin)
    {
        ShipSkinData memory data = skins[_name];
        skin = ShipSkin({
            name: _name,
            ship: data.ship
        });
    }


    /// @dev Retreive a skin instance by token id
    /// @param tokenId The id of the skin to retreive
    /// @return instance a single skin instance
    function _getSkinInstance(uint tokenId) 
        internal virtual view 
        returns (ShipSkinInstance memory instance)
    {
        bytes32 skinName = skinInstances[tokenId];
        ShipSkinData memory data = skins[skinName];
        instance = ShipSkinInstance({
            tokenId: tokenId,
            owner: ownerOf(tokenId),
            index: uint16(data.index),
            name: skinName,
            ship: data.ship
        });
    }


    /// @dev Mint a reward
    /// @param player The player to mint the item to
    /// @param inventory The inventory to mint the item to
    /// @param skin The item to mint
    function _mintReward(address player, Inventory inventory, bytes32 skin)
        internal 
        returns (uint tokenId)
    {
        tokenId = _getNextTokenId();
        _incrementTokenId();
        skinInstances[tokenId] = skin;

        // Into wallet
        if (inventory == Inventory.Wallet)
        {
             _mint(player, tokenId);
        }

        // Into inventory
        else 
        {
            _mint(inventoriesContract, tokenId);

            // Assign
            IInventories(inventoriesContract)
                .__assignNonFungibleToken(player, inventory, address(this), tokenId);
        }

        // Emit event
        emit ShipSkinMinted(tokenId, skin, player);
    }
}