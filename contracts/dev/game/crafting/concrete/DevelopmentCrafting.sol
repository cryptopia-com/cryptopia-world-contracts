// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../source/game/crafting/concrete/CryptopiaCrafting.sol";

/// @title Cryptopia Crafting Contract
/// @notice Serves as the core mechanism for crafting within Cryptopia, facilitating the creation of unique in-game items.
/// This contract enables players to craft various items using specific recipes and ingredients, blending strategy and resource management.
/// Players can learn and master recipes, manage crafting slots, and engage in a creative process to produce items ranging from basic commodities to rare artifacts.
/// The crafting system adds depth to the gameplay, encouraging exploration and trade to acquire necessary components.
/// @dev Inherits from Initializable and AccessControlUpgradeable, implementing the ICrafting interface.
/// It manages detailed crafting recipes and player crafting data, including ingredients, crafting levels, and slots.
/// The contract is structured to support upgradability, ensuring adaptability to future expansions of crafting features.
/// It emphasizes security and integrity in managing crafting operations, with checks and balances to maintain fair gameplay.
/// A comprehensive solution for managing ERC-20 tokens, NFTs, and crafting dynamics within the game's ecosystem.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentCrafting is CryptopiaCrafting {

    /// @dev Remove the player data 
    /// @param accounts The accounts to remove data from
    function cleanPlayerData(address[] calldata accounts, address[] calldata assets) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < accounts.length; i++) 
        {
            CraftingPlayerData storage playerData = playerDatas[accounts[i]];
            for (uint j = 0; j < playerData.slotCount; j++) 
            {
                delete playerData.slots[j];
            }

            for (uint j = 0; j < assets.length; j++) 
            {
                address asset = assets[j];
                for (uint k = 0; k < playerData.learnedIndex[asset].length; k++) 
                {
                    delete playerData.learned[asset][playerData.learnedIndex[asset][k]];
                }

                delete playerData.learnedIndex[asset];
            }

            delete playerDatas[accounts[i]];
        }
    }

    /// @dev Remove the recipe data
    /// @param assets The assets to remove data from
    function cleanRecipeData(address[] calldata assets) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < assets.length; i++) 
        {
            address asset = assets[i];
            for (uint j = 0; j < recipesIndex[asset].length; j++) 
            {
                CraftingRecipeData storage recipe = recipes[asset][recipesIndex[asset][j]];
                for (uint k = 0; k < recipe.ingredientsIndex.length; k++) 
                {
                    delete recipe.ingredients[recipe.ingredientsIndex[k]];
                }

                delete recipe.ingredientsIndex;
                delete recipes[asset][recipesIndex[asset][j]];
            }

            delete recipesIndex[asset];
        }
    }
}