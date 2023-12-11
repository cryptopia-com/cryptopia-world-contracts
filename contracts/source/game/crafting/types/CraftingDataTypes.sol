// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Data structure for a crafting recipe
struct CraftingRecipe 
{
    /// @dev Required crafting level to utilize this recipe
    /// @notice A level of zero indicates that the recipe is not initialized
    uint8 level;

    /// @dev Flag indicating whether this recipe can be learned by players
    bool learnable;

    /// @dev Address of the ERC721 asset associated with this recipe
    address asset;

    /// @dev Unique identifier of the item to be crafted
    bytes32 item;

    /// @dev Time in seconds required to complete the crafting process
    uint64 craftingTime;

    /// @dev Array of ingredients required for the crafting process
    /// @notice Ingredients are represented as ERC20 tokens with their respective amounts
    CraftingRecipeIngredient[] ingredients;
}

/// @dev Data structure for a crafting recipe ingredient
struct CraftingRecipeIngredient
{
    /// @dev Address of the ERC20 token representing the ingredient
    address asset;

    /// @dev Quantity of the ingredient required for the recipe
    uint amount;
}

/// @dev Data structure representing a player's crafting slot
struct CraftingSlot
{
    /// @dev Address of the ERC721 asset being crafted in this slot
    address asset;

    /// @dev Identifier of the recipe being used for crafting
    bytes32 recipe;

    /// @dev Unix timestamp indicating when the crafting process will be complete
    /// @notice The crafted item can be claimed after this time
    uint finished;        
}
