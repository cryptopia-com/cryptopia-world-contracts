// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../../source/tokens/ERC721/concrete/quests/CryptopiaQuestToken.sol";

/// @title Cryptopia Quest Token Contract
/// @notice Specializes in managing Non-Fungible Tokens (NFTs) for quests within Cryptopia, facilitating unique in-game interactions and rewards.
/// This contract governs the lifecycle of quest-related NFTs, from minting for specific quest achievements to burning post-usage or trade.
/// It ensures that these tokens, integral to quest progression and completion, are accurately tracked and managed within the game's ecosystem.
/// @dev Inherits from CryptopiaERC721 and implements INonFungibleQuestItem and IQuestItems interfaces.
/// The contract allows for creating, assigning, and destroying NFTs tied to game quests, linking quest progress with tangible in-game assets.
/// It interacts with the inventories contract to manage the assignment of these NFTs to player inventories, ensuring a seamless in-game experience.
/// This contract is an essential part of the quest mechanics, integrating NFTs with the game’s narrative and reward system.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentQuestToken is CryptopiaQuestToken {

    /// @dev Removes all token data for `skip` to `skip` + `take`
    /// @param skip The index to start cleaning from
    /// @param take The amount of items to clean
    function cleanTokenData(uint skip, uint take)
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        skip = skip + 1; // Convert to 1-based token ids
        for (uint i = skip; i < skip + take; i++) 
        {
            delete itemInstances[i];
        }
    }


    /// @dev Removes all item data
    /// @notice Does not implement batched removal because of the limited amount of items
    ///         in development and the upgradability of the contract
    function cleanItemData()
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < itemsIndex.length; i++) 
        {
            delete items[itemsIndex[i]];
        }

        delete itemsIndex;
    }
}