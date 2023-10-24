// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../inventories/types/InventoryEnums.sol";

/// @title Crafting interface
/// @dev Allows the player to craft Non-fungible tokens (ERC721) based on recepies
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICrafting {

    /** 
     * Admin functions
     */
    /// @dev Set the crafting `slotCount` for `player`
    /// @param player The player to set the slot count for
    /// @param slotCount The new slot count
    function setCraftingSlots(address player, uint slotCount)
        external;


    /// @dev The `player` is able to craft the item after learning the `asset` `recipe` 
    /// @param player The player that learns the recipe
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param recipe The name of the asset recipe
    function learn(address player, address asset, bytes32 recipe) 
        external;


    /** 
     * Public functions
     */
    /// @dev Returns the amount of different `asset` recipes
    /// @return count The amount of different recipes
    function getRecipeCount(address asset) 
        external view 
        returns (uint);


    /// @dev Returns a single `asset` recipe at `index`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param index The index of the asset recipe
    /// @return level Recipe can be crafted and/or learned by players from this level
    /// @return learnable True indicates that the recipe has to be learned before it can be used
    /// @return craftingTime The time it takes to craft the item
    /// @return ingredients_asset Resource contracts (ERC20) needed for crafting
    /// @return ingredients_count Resource amounts needed for crafting
    function getRecipeAt(address asset, uint index)
        external view 
        returns (
            uint8 level,
            bool learnable,
            uint240 craftingTime,
            address[] memory ingredients_asset,
            uint[] memory ingredients_count
        );


    /// @dev Returns a single `asset` recipe at `index`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param index The index of the asset recipe
    /// @return assets Resource contracts (ERC20) needed for crafting
    /// @return amounts Resource amounts needed for crafting
    function getRecipeIngredientsAt(address asset, uint index)
        external view 
        returns (
            address[] memory assets,
            uint[] memory amounts
        );


    /// @dev Returns a single `asset` recipe by `name`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param name The name of the asset recipe
    /// @return level Recipe can be crafted and/or learned by players from this level
    /// @return learnable True indicates that the recipe has to be learned before it can be used
    /// @return craftingTime The time it takes to craft the item
    /// @return ingredients_asset Resource contracts (ERC20) needed for crafting
    /// @return ingredients_amount Resource amounts needed for crafting
    function getRecipe(address asset, bytes32 name)
        external view 
        returns (
            uint8 level,
            bool learnable,
            uint240 craftingTime,
            address[] memory ingredients_asset,
            uint[] memory ingredients_amount
        );


    /// @dev Returns a single `asset` recipe by `name`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param name The name of the asset recipe
    /// @return assets Resource contracts (ERC20) needed for crafting
    /// @return amounts Resource amounts needed for crafting
    function getRecipeIngredients(address asset, bytes32 name)
        external view 
        returns (
            address[] memory assets,
            uint[] memory amounts
        );


    /// @dev Retrieve a range of `asset` recipes
    /// @param asset The contract address of the asset to which the recipes apply
    /// @param skip Starting index
    /// @param take Amount of recipes
    /// @return name Recipe name
    /// @return level Recipe can be crafted and/or learned by players from this level
    /// @return learnable True indicates that the recipe has to be learned before it can be used
    /// @return craftingTime The time it takes to craft the item
    /// @return ingredient_count The number of different ingredients needed to craft this item
    function getRecipes(address asset, uint skip, uint take)
        external view 
        returns (
            bytes32[] memory name,
            uint8[] memory level,
            bool[] memory learnable,
            uint240[] memory craftingTime,
            uint[] memory ingredient_count
        );


    /// @dev Retrieve a range of `asset` recipes
    /// @param asset The contract address of the asset to which the recipes apply
    /// @param skip Starting index
    /// @param take Amount of recipes
    /// @return asset1 Resource contracts (ERC20) needed for crafting
    /// @return asset2 Resource contracts (ERC20) needed for crafting
    /// @return asset3 Resource contracts (ERC20) needed for crafting
    /// @return asset4 Resource contracts (ERC20) needed for crafting
    /// @return amount1 Resource amounts needed for crafting
    /// @return amount2 Resource amounts needed for crafting
    /// @return amount3 Resource amounts needed for crafting
    /// @return amount4 Resource amounts needed for crafting
    function getRecipesIngredients(address asset, uint skip, uint take)
        external view 
        returns (
            address[] memory asset1,
            address[] memory asset2,
            address[] memory asset3,
            address[] memory asset4,
            uint[] memory amount1,
            uint[] memory amount2,
            uint[] memory amount3,
            uint[] memory amount4
        );

    
    /// @dev Returns the number of `asset` recipes that `player` has learned
    /// @param player The player to retrieve the learned recipe count for
    /// @param asset The contract address of the asset to which the recipes apply
    /// @return uint The number of `asset` recipes learned
    function getLearnedRecipeCount(address player, address asset) 
        external view 
        returns (uint);


    /// @dev Returns the `asset` recipe at `index` for `player`
    /// @param player The player to retrieve the learned recipe for
    /// @param asset The contract address of the asset to which the recipe applies
    /// @return bytes32 The recipe name
    function getLearnedRecipeAt(address player, address asset, uint index) 
        external view 
        returns (bytes32);


    /// @dev Returns the `asset` recipe at `index` for `player`
    /// @param player The player to retrieve the learned recipe for
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param skip Starting index
    /// @param take Amount of recipes
    /// @return bytes32[] The recipe names
    function getLearnedRecipes(address player, address asset, uint skip, uint take) 
        external view 
        returns (bytes32[] memory);


    /// @dev Returns the total number of crafting slots for `player`
    /// @param player The player to retrieve the slot count for
    /// @return uint The total number of slots
    function getSlotCount(address player) 
        external view 
        returns (uint);


    /// @dev Returns a single crafting slot for `player` by `slot` index (non-zero based)
    /// @param player The player to retrieve the slot data for
    /// @param slot The slot index (non-zero based)
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param recipe The name of the recipe that is being crafted 
    /// @param finished The timestamp after which the crafted item can be claimed
    function getSlot(address player, uint slot)
        external view 
        returns (
            address asset,
            bytes32 recipe,
            uint finished
        );


    /// @dev Returns a range of crafting slot for `player`
    /// @param player The player to retrieve the slot data for
    /// @param slot The slot index (non-zero based)
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param recipe The name of the recipe that is being crafted 
    /// @param finished The timestamp after which the crafted item can be claimed
    function getSlots(address player) 
        external view 
        returns (
            uint[] memory slot,
            address[] memory asset,
            bytes32[] memory recipe,
            uint[] memory finished
        );


    /// @dev Start the crafting process (completed by calling claim(..) after the crafting time has passed) of an item (ERC721)
    /// @param asset The contract address of the asset to which the recipes apply
    /// @param recipe The name of the recipe to craft
    /// @param slot The index (non-zero based) of the crafting slot to use
    /// @param inventory The inventory space to deduct ingredients from ({Ship|Backpack})
    function craft(address asset, bytes32 recipe, uint slot, Inventory inventory) 
        external;


    /// @dev Claims (mints) the previously crafted item (ERC721) in `slot` after sufficient crafting time has passed (started by calling craft(..)) 
    /// @param slot The number (non-zero based) of the slot to claim
    /// @param inventory The inventory space to mint the crafted item into ({Ship|Backpack}) 
    function claim(uint slot, Inventory inventory)
        external;


    /// @dev Empties a slot without claiming the crafted item (without refunding ingredients, if any)
    /// @param slot The number (non-zero based) of the slot to empty
    function empty(uint slot) 
        external;
}