// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../../../game/quests/items/INonFungibleQuestItem.sol";
import "../../../../game/inventories/IInventories.sol";
import "../../quests/IQuestItems.sol";
import "../CryptopiaERC721.sol";

/// @title Quest Items 
/// @dev Non-fungible token (ERC721) 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaQuestToken is CryptopiaERC721, INonFungibleQuestItem, IQuestItems {

    /**
     * Storage
     */
    uint private _currentTokenId; 

    /// @dev name => Item
    mapping (bytes32 => QuestItem) public items;
    bytes32[] private itemsIndex;

    /// @dev tokenId => item name
    mapping (uint => bytes32) public itemInstances;

    // Refs
    address public inventoriesContract;


    /**
     * Errors
     */
    /// @dev Emitted when a quest item with the specified identifier does not exist in the system
    /// @param item The identifier of the item that wasn't found
    error QuestItemNotFound(bytes32 item);


    /**
     * Modifiers
     */
    /// @dev Requires that an `item` exists
    /// @param item Unique token name
    modifier onlyExisting(bytes32 item)
    {  
        if (!_exists(item))
        {
            revert QuestItemNotFound(item);
        }
        _;
    }


    /// @dev Contract initializer sets shared base uri
    /// @param authenticator Whitelist
    /// @param initialContractURI Location to contract info
    /// @param initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    /// @param _inventoriesContract Contract responsible for inventories
    function initialize(
        address authenticator, 
        string memory initialContractURI, 
        string memory initialBaseTokenURI,
        address _inventoriesContract) 
        public initializer 
    {
        __CryptopiaERC721_init(
            "Cryptopia Quest Items", "QUEST", authenticator, initialContractURI, initialBaseTokenURI);

        inventoriesContract = _inventoriesContract;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * Admin functions
     */
    /// @dev Sets a range of quest items
    /// @param name The names of the items
    function setItem(bytes32 name)
        public virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setItem(name);
    }


    /// @dev Sets a range of quest items
    /// @param names The names of the items
    function setItems(bytes32[] memory names)
        public virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint i = 0; i < names.length; i++) 
        {
            _setItem(names[i]);
        }
    }


    /**
     * Public functions
     */
    /// @dev Returns the amount of different items
    /// @return count The amount of different items
    function getItemCount() 
        public override view 
        returns (uint)
    {
        return itemsIndex.length;
    }


    /// @dev Returns the item at the given index
    /// @param index The index position of the item
    /// @return item The item
    function getItemAt(uint index) 
        public override view 
        returns (QuestItem memory)
    {
        return items[itemsIndex[index]];
    }


    /// @dev Retreive a rance of items
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return names Tool names (unique)
    function getItems(uint skip, uint take) 
        public override view 
        returns (QuestItem[] memory)
    {
        QuestItem[] memory result = new QuestItem[](take);
        for (uint i = 0; i < take; i++) 
        {
            result[i] = items[itemsIndex[skip + i]];
        }

        return result;
    }


    /// @dev Returns the item with the given id
    /// @param tokenId The token id of the item
    /// @return item The item
    function getItemByTokenId(uint tokenId) 
        public override view 
        returns (QuestItem memory)
    {
        return items[itemInstances[tokenId]];
    }


    /// @dev Returns the item with the given name
    /// @param tokenIds The token ids of the items
    /// @return items The items
    function getItemsIdByTokenId(uint[] memory tokenIds)
        public override view 
        returns (QuestItem[] memory)
    {
        QuestItem[] memory result = new QuestItem[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) 
        {
            result[i] = items[itemInstances[tokenIds[i]]];
        }

        return result;
    }


    /**
     * System functions
     */
    /// @dev Mint quest item
    /// @param item Item to mint
    /// @param player The player that completed the quest
    /// @param inventory The inventory to mint the item to
    /// @return tokenId Token id of the item that was minted
    function __mintQuestItem(bytes32 item, address player, Inventory inventory) 
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        onlyExisting(item) 
        returns (uint tokenId)
    {
        // Mint
        tokenId = _getNextTokenId();
        _mint(inventoriesContract, tokenId);
        _incrementTokenId();
        itemInstances[tokenId] = item; 

        // Assign
        IInventories(inventoriesContract)
            .__assignNonFungibleToken(player, inventory, address(this), tokenId);

        return tokenId;
    }


    /// @dev Burn quest item
    /// @param item Item to burn
    /// @param tokenId Token id of the item to burn
    /// @param player The player that completed the quest
    /// @param inventory The inventory to burn the item from
    function __burnQuestItem(bytes32 item, uint tokenId, address player, Inventory inventory) 
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
    {
        // Check that tokenId represents the item
        if (itemInstances[tokenId] != item) 
        {
            revert QuestItemNotFound(item);
        }

        // Burn
        _burn(tokenId);
        delete itemInstances[tokenId];

        // Unassign
        IInventories(inventoriesContract)
            .__deductNonFungibleToken(player, inventory, address(this), tokenId, false); 
    }


    /**
     * Internal functions
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


    /// @dev Returns true if the item exists
    /// @param name The name of the item
    function _exists(bytes32 name)
        internal virtual view 
        returns (bool)
    {
        return itemsIndex.length > 0 && itemsIndex[items[name].index] == name;
    }


    /// @dev Sets the item
    /// @param name The name of the item
    function _setItem(bytes32 name)
        internal virtual
    {
        // Add item
        if (!_exists(name)) 
        {
            items[name].index = itemsIndex.length;
            itemsIndex.push(name);
        }
    }
}