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

    /// @dev Quest item
    struct QuestItemDataEntry
    {
        uint index;
        bytes32 name; 
    }

    /**
     * Storage
     */
    uint private _currentTokenId; 

    /// @dev name => Item
    mapping (bytes32 => QuestItemDataEntry) public items;
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
    /// @param item The Item to set
    function setItem(QuestItem memory item)
        public virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setItem(item);
    }


    /// @dev Sets a range of quest items 
    /// @param items_ The Items to set
    function setItems(QuestItem[] memory items_) 
        public virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint i = 0; i < items_.length; i++) 
        {
            _setItem(items_[i]);
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
        returns (QuestItem memory item)
    {
        item = QuestItem(items[itemsIndex[index]].name);
    }


    /// @dev Retreive a rance of items
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return items_ The items
    function getItems(uint skip, uint take) 
        public override view 
        returns (QuestItem[] memory items_)
    {
        uint length = take;
        if (itemsIndex.length < skip + take) 
        {
            length = itemsIndex.length - skip;
        }

        items_ = new QuestItem[](length);
        for (uint i = 0; i < length; i++) 
        {
            items_[i] = QuestItem(items[itemsIndex[skip + i]].name);
        }

        return items_;
    }


    /// @dev Returns the item with the given id
    /// @param tokenId The token id of the item
    /// @return item The item
    function getItemByTokenId(uint tokenId) 
        public override view 
        returns (QuestItem memory item)
    {
        item = QuestItem(items[itemInstances[tokenId]].name);
    }


    /// @dev Returns the item with the given name
    /// @param tokenIds The token ids of the items
    /// @return items_ The items
    function getItemsIdByTokenIds(uint[] memory tokenIds)
        public override view 
        returns (QuestItem[] memory items_)
    {
        items_ = new QuestItem[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) 
        {
            items_[i] = QuestItem(items[itemInstances[tokenIds[i]]].name);
        }

        return items_;
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
    /// @param item The item to set
    function _setItem(QuestItem memory item)
        internal virtual
    {
        if (item.name == bytes32(0)) 
        {
            revert QuestItemNotFound(item.name);
        }

        // Add item
        if (!_exists(item.name)) 
        {
            items[item.name] = QuestItemDataEntry(
                itemsIndex.length, item.name);
            itemsIndex.push(item.name);
        }
    }
}