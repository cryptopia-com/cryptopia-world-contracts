// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Crafting recipe data
struct CraftingRecipe 
{
    bytes32 name;
    uint8 level; // Level zero indicated not initialized
    bool learnable;

    // Asset (ERC721)
    address asset;

    // Crafting time
    uint64 craftingTime;

    // Ingredients
    CraftingRecipeIngredient[] ingredients;
}

/// @dev Recipe ingredient data
struct CraftingRecipeIngredient
{
    // Asset (ERC20)
    address asset;
    uint amount;
}

/// @dev Crafting slot data
struct CraftingSlot
{
    /// @dev The asset (ERC721) that is being crafted
    address asset;

    /// @dev The recipe (name) that is being crafted
    bytes32 recipe;

    /// @dev The timestamp after which the crafted item can be claimed
    uint finished;        
}