// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "./types/CraftingDataTypes.sol";
import "../inventories/types/InventoryEnums.sol";

/// @title Cryptopia Crafting Contract
/// @notice Serves as the core mechanism for crafting within Cryptopia, facilitating the creation of unique in-game items.
/// This contract enables players to craft various items using specific recipes and ingredients, blending strategy and resource management.
/// Players can learn and master recipes, manage crafting slots, and engage in a creative process to produce items ranging from basic commodities to rare artifacts.
/// The crafting system adds depth to the gameplay, encouraging exploration and trade to acquire necessary components.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICrafting {

    /** 
     * Public functions
     */
    /// @dev Returns the amount of different `asset` recipes
    /// @param asset The contract address of the asset to which the recipes apply
    /// @return count The amount of different recipes
    function getRecipeCount(address asset) 
        external view 
        returns (uint count);


    /// @dev Returns a single `asset` recipe by `name`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param name The name of the asset recipe
    /// @return recipe The recipe
    function getRecipe(address asset, bytes32 name)
        external view 
        returns (CraftingRecipe memory recipe);


    /// @dev Returns a single `asset` recipe at `index`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param index The index of the asset recipe
    /// @return recipe The recipe
    function getRecipeAt(address asset, uint index)
        external view 
        returns (CraftingRecipe memory recipe);


    /// @dev Retrieve a range of `asset` recipes
    /// @param asset The contract address of the asset to which the recipes apply
    /// @param skip Starting index
    /// @param take Amount of recipes
    /// @return recipes_ The recipes
    function getRecipes(address asset, uint skip, uint take)
        external view 
        returns (CraftingRecipe[] memory recipes_);


    /// @dev Returns a single `asset` recipe at `index`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param index The index of the asset recipe
    /// @return ingredient The recipe ingredient
    function getRecipeIngredientAt(address asset, bytes32 recipe, uint index)
        external view 
        returns (CraftingRecipeIngredient memory ingredient);


    /// @dev Returns a single `asset` recipe at `index`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param recipe The name of recipe to retrieve the ingredients for
    /// @return ingredients The recipe ingredients
    function getRecipeIngredients(address asset, bytes32 recipe)
        external view 
        returns (CraftingRecipeIngredient[] memory ingredients);

    
    /// @dev Returns the number of `asset` recipes that `player` has learned
    /// @param player The player to retrieve the learned recipe count for
    /// @param asset The contract address of the asset to which the recipes apply
    /// @return count The number of `asset` recipes learned
    function getLearnedRecipeCount(address player, address asset) 
        external view 
        returns (uint count);


    /// @dev Returns the `asset` recipe at `index` for `player`
    /// @param player The player to retrieve the learned recipe for
    /// @param asset The contract address of the asset to which the recipe applies
    /// @return recipe The recipe name
    function getLearnedRecipeAt(address player, address asset, uint index) 
        external view 
        returns (bytes32 recipe);


    /// @dev Returns the `asset` recipe at `index` for `player`
    /// @param player The player to retrieve the learned recipe for
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param skip Starting index
    /// @param take Amount of recipes
    /// @return recipes_ The recipe names
    function getLearnedRecipes(address player, address asset, uint skip, uint take) 
        external view 
        returns (bytes32[] memory recipes_);


    /// @dev Returns the total number of crafting slots for `player`
    /// @param player The player to retrieve the slot count for
    /// @return count The total number of slots
    function getSlotCount(address player) 
        external view 
        returns (uint count);


    /// @dev Returns a single crafting slot for `player` by `slot` index (non-zero based)
    /// @param player The player to retrieve the slot data for
    /// @param slot The slot index (non-zero based)
    /// @return slot The slot data
    function getSlot(address player, uint slotId)
        external view 
        returns (CraftingSlot memory slot);


    /// @dev Returns a range of crafting slot for `player`
    /// @param player The player to retrieve the slot data for
    /// @return slots The slot datas
    function getSlots(address player) 
        external view 
        returns (CraftingSlot[] memory slots);


    /// @dev Start the crafting process (completed by calling claim(..) after the crafting time has passed) of an item (ERC721)
    /// @param asset The contract address of the asset to which the recipes apply
    /// @param recipe The name of the recipe to craft
    /// @param slotId The index (non-zero based) of the crafting slot to use
    /// @param inventory The inventory space to deduct ingredients from ({Ship|Backpack})
    function craft(address asset, bytes32 recipe, uint slotId, Inventory inventory) 
        external;


    /// @dev Claims (mints) the previously crafted item (ERC721) in `slot` after sufficient crafting time has passed (started by calling craft(..)) 
    /// @param slotId The number (non-zero based) of the slot to claim
    /// @param inventory The inventory space to mint the crafted item into ({Ship|Backpack}) 
    function claim(uint slotId, Inventory inventory)
        external;


    /// @dev Empties a slot without claiming the crafted item (without refunding ingredients, if any)
    /// @param slotId The number (non-zero based) of the slot to empty
    function empty(uint slotId) 
        external;

    /**
     * System functions
     */
    /// @dev Set the crafting `slotCount` for `player`
    /// @param player The player to set the slot count for
    /// @param slotCount The new slot count
    function __setCraftingSlots(address player, uint slotCount)
        external;


    /// @dev The `player` is able to craft the item after learning the `asset` `recipe` 
    /// @param player The player that learns the recipe
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param recipe The name of the asset recipe
    function __learn(address player, address asset, bytes32 recipe) 
        external;
}