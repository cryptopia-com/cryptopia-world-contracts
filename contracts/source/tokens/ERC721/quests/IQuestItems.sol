// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "./types/QuestItemDataTypes.sol";

/// @title Cryptopia Quest Token Contract
/// @notice Specializes in managing Non-Fungible Tokens (NFTs) for quests within Cryptopia, facilitating unique in-game interactions and rewards.
/// This contract governs the lifecycle of quest-related NFTs, from minting for specific quest achievements to burning post-usage or trade.
/// It ensures that these tokens, integral to quest progression and completion, are accurately tracked and managed within the game's ecosystem.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IQuestItems {

    /**
     * Public functions
     */
    /// @dev Returns the amount of different items
    /// @return count The amount of different items
    function getItemCount() 
        external view 
        returns (uint);


    /// @dev Returns the item at the given index
    /// @param index The index position of the item
    /// @return item The item
    function getItemAt(uint index) 
        external view 
        returns (QuestItem memory item);


    /// @dev Retreive a rance of items
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return items The items
    function getItems(uint skip, uint take) 
        external view 
        returns (QuestItem[] memory items);


    /// @dev Returns the item with the given id
    /// @param tokenId The token id of the item
    /// @return item The item
    function getItemByTokenId(uint tokenId) 
        external view 
        returns (QuestItem memory item);


    /// @dev Returns the item with the given name
    /// @param tokenIds The token ids of the items
    /// @return items The items
    function getItemsIdByTokenIds(uint[] memory tokenIds)
        external view 
        returns (QuestItem[] memory items);
}