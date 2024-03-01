// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../players/errors/PlayerErrors.sol";
import "../../inventories/types/InventoryEnums.sol";
import "../../inventories/errors/InventoryErrors.sol";
import "../../inventories/IInventories.sol";
import "../ICraftable.sol";
import "../ICrafting.sol";

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
contract CryptopiaCrafting is Initializable, AccessControlUpgradeable, ICrafting {

    /// @dev Data structure for a crafting recipe
    struct CraftingRecipeData 
    {
        /// @dev Index that identifies the position in the mapping
        uint index; 

        /// @dev The crafting level required
        /// @notice Level zero indicates the recipe is not initialized
        uint8 level;

        /// @dev Flag indicating whether the recipe can be learned by players
        bool learnable;

        /// @dev Crafting time in seconds required to complete this recipe
        uint64 craftingTime;

        /// @dev Mapping of ingredient addresses to their required quantities
        mapping (address => uint) ingredients;
        address[] ingredientsIndex;
    }

    /// @dev Crafting related data for a player
    struct CraftingPlayerData 
    {
        /// @dev The total number of crafting slots available to the player
        /// @notice Zero indicates that the player's crafting capability is not initiated
        uint slotCount; 

        /// @dev Mapping from slot index to the crafting slot data
        /// @notice Slots holds the current crafting status and recipe information
        mapping (uint => CraftingSlot) slots;

        /// @dev Nested mapping to track recipes learned by the player
        /// @notice Maps the asset (ERC721) address to the recipe item and its learned status.
        mapping (address => mapping (bytes32 => bool)) learned;
        mapping (address => bytes32[]) learnedIndex;
    }


    /**
     * Roles
     */
    bytes32 constant private SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage
     */
    /// @dev asset (ERC721) => recipe item => CraftingRecipe
    mapping (address => mapping (bytes32 => CraftingRecipeData)) public recipes;
    mapping (address => bytes32[]) internal recipesIndex;

    /// @dev player => PlayerCraftingData
    mapping (address => CraftingPlayerData) public playerDatas;

    /// Refs
    address public inventoriesContract;


    /**
     * Events
     */
    /// @dev Called when the crafting of `asset` `recipe` was started by `player`
    /// @param player The player that is crafting the item
    /// @param asset The address of the ERC721 contract
    /// @param item The item that is crafted
    /// @param slot The slot used to craft the item
    /// @param finished The datetime at which the item can be claimed
    event CraftingStart(address indexed player, address indexed asset, bytes32 indexed item, uint slot, uint finished);

    /// @dev Called when the crafted `asset` item in `slot` was claimed by `player`
    /// @param player The player that crafted the item
    /// @param asset The address of the ERC721 contract
    /// @param item The item (recipe) that was crafted
    /// @param slot The slot used to craft the item
    /// @param tokenId The token ID of the crafted item
    event CraftingClaim(address indexed player, address indexed asset, bytes32 indexed item, uint slot, uint tokenId);

    /// @dev Called when an item in `slot` was discarded by `player`
    /// @param player The player that crafted the item
    /// @param asset The address of the ERC721 contract
    /// @param item The item (recipe) that was crafted
    /// @param slot The slot used to craft the item
    event CraftingDiscard(address indexed player, address indexed asset, bytes32 indexed item, uint slot);

    /// @dev Called when the crafting `slotCount` of `player` was updated
    /// @param player The player whos slot count was modified
    /// @param slotCount the new slot count
    event CraftingSlotCountChange(address indexed player, uint slotCount);

    /// @dev Called when the `asset` `recipe` was mutated
    /// @param asset The address of the ERC721 contract
    /// @param item The item that was mutated
    event CraftingRecipeMutation(address indexed asset, bytes32 indexed item);

    /// @dev Called when the `player` learned `asset` `recipe` 
    /// @param player The player that learned the recipe
    /// @param asset The address of the ERC721 contract
    /// @param item The item that was learned
    event CraftingRecipeLearn(address indexed player, address indexed asset, bytes32 indexed item);


    /**
     * Errors
     */
    /// @dev Emitted when the crafting slot number is invalid or doesn't exist for the player
    /// @param player The player who attempted to use the slot
    /// @param slot The invalid slot number
    error CraftingSlotInvalid(address player, uint slot);

    /// @dev Emitted when the specified crafting slot is already in use
    /// @param player The player who attempted to use the slot
    /// @param slot The slot that's already in use
    error CraftingSlotOccupied(address player, uint slot);

    /// @dev Emitted when the crafting slot is empty
    /// @param player The player that attempted to craft
    /// @param slot The slot that was empty
    error CraftingSlotIsEmpty(address player, uint slot);

    /// @dev Emitted when the crafting slot is not ready
    /// @param player The player that attempted to craft
    /// @param slot The slot that was not ready
    error CraftingSlotNotReady(address player, uint slot);

    /// @dev Emitted when the recipe is invalid
    /// @param asset The asset that was used in the recipe
    /// @param recipe The recipe that was invalid
    error CraftingRecipeInvalid(address asset, bytes32 recipe);

    /// @dev Emitted when the recipe has not been learned by the player
    /// @param player The player who attempted to craft
    /// @param asset The asset associated with the recipe
    /// @param recipe The recipe that hasn't been learned
    error CraftingRecipeNotLearned(address player, address asset, bytes32 recipe);

    
    /**
     * Modifiers
     */
    /// @dev Requires that `player` is registered
    /// @param player address to check
    modifier validPlayer(address player)
    {
        if (playerDatas[player].slotCount == 0)
        {
            revert PlayerNotRegistered(player);
        }
        _;
    }


    /// @dev Requires that `inventory` is not Wallet
    /// @param inventory inventory to check
    modifier validInventory(Inventory inventory)
    {
        if (inventory == Inventory.Wallet)
        {
            revert InventoryInvalid(inventory);
        }
        _;
    }


    /// @dev Construct
    /// @param _inventoriesContract Contract responsible for inventories
    function initialize(
        address _inventoriesContract) 
        public initializer 
    {
        __AccessControl_init();

        // Refs
        inventoriesContract = _inventoriesContract;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * Admin functions
     */
    /// @dev Batch operation to set recepes
    /// @param recipes_ The recipes to set
    function setRecipes(CraftingRecipe[] memory recipes_) 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        public virtual 
    {
        for (uint i = 0; i < recipes_.length; i++)
        {
            _setRecipe(recipes_[i]);
        }
    }


    /** 
     * Public functions
     */
    // @dev Returns the amount of different `asset` recipes
    /// @param asset The contract address of the asset to which the recipes apply
    /// @return count The amount of different recipes
    function getRecipeCount(address asset) 
        public virtual override view 
        returns (uint count)
    {
        count = recipesIndex[asset].length;
    }


    /// @dev Returns a single `asset` recipe by `item` 
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param item The item of the asset recipe
    /// @return recipe The recipe
    function getRecipe(address asset, bytes32 item)
        public virtual override view 
        returns (CraftingRecipe memory recipe)
    {
        recipe = _getRecipe(asset, item);
    }   


    /// @dev Returns a single `asset` recipe at `index`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param index The index of the asset recipe
    /// @return recipe The recipe
    function getRecipeAt(address asset, uint index)
        public virtual override view 
        returns (CraftingRecipe memory recipe)
    {
        recipe = _getRecipe(asset, recipesIndex[asset][index]);
    }


    /// @dev Retrieve a range of `asset` recipes
    /// @param asset The contract address of the asset to which the recipes apply
    /// @param skip Starting index
    /// @param take Amount of recipes
    /// @return recipes_ The recipes
    function getRecipes(address asset, uint skip, uint take)
        public virtual override view 
        returns (CraftingRecipe[] memory recipes_)
    {
        uint length = take;
        if (skip + take > recipesIndex[asset].length)
        {
            length = recipesIndex[asset].length - skip;
        }

        recipes_ = new CraftingRecipe[](length);
        for (uint i = skip; i < length; i++)
        {
            recipes_[i] = _getRecipe(
                asset, recipesIndex[asset][skip + i]);
        }
    }


    /// @dev Returns a single `asset` recipe at `index`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param index The index of the asset recipe
    /// @return ingredient The recipe ingredient
    function getRecipeIngredientAt(address asset, bytes32 recipe, uint index)
         public virtual override view 
        returns (CraftingRecipeIngredient memory ingredient)
    {
        CraftingRecipeData storage recipe_ = recipes[asset][recipe];
        ingredient = CraftingRecipeIngredient(
            recipe_.ingredientsIndex[index], 
            recipe_.ingredients[recipe_.ingredientsIndex[index]]);
    }


    /// @dev Returns a single `asset` recipe at `index`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param recipe The item of recipe to retrieve the ingredients for
    /// @return ingredients The recipe ingredients
    function getRecipeIngredients(address asset, bytes32 recipe)
        public virtual override view 
        returns (CraftingRecipeIngredient[] memory ingredients)
    {
        CraftingRecipeData storage recipe_ = recipes[asset][recipe];
        ingredients = new CraftingRecipeIngredient[](recipe_.ingredientsIndex.length);

        for (uint i = 0; i < recipe_.ingredientsIndex.length; i++)
        {
            ingredients[i] = CraftingRecipeIngredient(
                recipe_.ingredientsIndex[i], 
                recipe_.ingredients[recipe_.ingredientsIndex[i]]);
        }

        return ingredients;
    }


    /// @dev Returns the number of `asset` recipes that `player` has learned
    /// @param player The player to retrieve the learned recipe count for
    /// @param asset The contract address of the asset to which the recipes apply
    /// @return count The number of `asset` recipes learned
    function getLearnedRecipeCount(address player, address asset) 
        public virtual override view 
        returns (uint count)
    {
        count = playerDatas[player].learnedIndex[asset].length;
    }


    /// @dev Returns the `asset` recipe at `index` for `player`
    /// @param player The player to retrieve the learned recipe for
    /// @param asset The contract address of the asset to which the recipe applies
    /// @return recipe The recipe item
    function getLearnedRecipeAt(address player, address asset, uint index) 
        public virtual override view 
        returns (bytes32 recipe)
    {
        recipe = playerDatas[player].learnedIndex[asset][index];
    }


    /// @dev Returns the `asset` recipe at `index` for `player`
    /// @param player The player to retrieve the learned recipe for
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param skip Starting index
    /// @param take Amount of recipes
    /// @return recipes_ The recipe items
    function getLearnedRecipes(address player, address asset, uint skip, uint take) 
        public virtual override view 
        returns (bytes32[] memory recipes_)
    {
        recipes_ = new bytes32[](take);

        uint index = skip;
        for (uint i = 0; i < playerDatas[player].learnedIndex[asset].length; i++)
        {
            recipes_[i] = playerDatas[player].learnedIndex[asset][index];
            index++;
        }
    }


    /// @dev Returns the total number of crafting slots for `player` 
    /// @param player The player to retrieve the slot count for
    /// @return count The total number of slots
    function getSlotCount(address player) 
        public virtual override view 
        returns (uint count)
    {
        count = playerDatas[player].slotCount;
    }


    /// @dev Returns a single crafting slot for `player` by `slot` index (non-zero based)
    /// @param player The player to retrieve the slot data for
    /// @param slotId The slot index (non-zero based)
    /// @return slot The slot data
    function getSlot(address player, uint slotId)
        public virtual override view 
        returns (CraftingSlot memory slot)
    {
        slot = playerDatas[player].slots[slotId];
    }


    /// @dev Returns a range of crafting slot for `player`
    /// @param player The player to retrieve the slot data for
    /// @return slots The slot datas
    function getSlots(address player) 
        external view 
        returns (CraftingSlot[] memory slots)
    {
        slots = new CraftingSlot[](playerDatas[player].slotCount);
        for (uint i = 0; i < playerDatas[player].slotCount; i++)
        {
            slots[i] = playerDatas[player].slots[i + 1];
        }

        return slots;
    }


    /// @dev Start the crafting process (completed by calling claim(..) after the crafting time has passed) of an item (ERC721)
    /// @param asset The contract address of the asset to which the recipes apply
    /// @param recipe The item of the recipe to craft
    /// @param slotId The index (non-zero based) of the crafting slot to use
    /// @param inventory The inventory space to deduct ingredients from ({Ship|Backpack})
    function craft(address asset, bytes32 recipe, uint slotId, Inventory inventory) 
        validPlayer(msg.sender) 
        validInventory(inventory) 
        public virtual override  
    {
        // Require valid recipe
        if (recipes[asset][recipe].level == 0)
        {
            revert CraftingRecipeInvalid(asset, recipe);
        }

        // Check recipe not learnable or learned
        if (recipes[asset][recipe].learnable && 
            !playerDatas[msg.sender].learned[asset][recipe]) 
        {
            revert CraftingRecipeNotLearned(msg.sender, asset, recipe);
        }

        // Require a valid slot
        if (slotId == 0 || slotId > playerDatas[msg.sender].slotCount)
        {
            revert CraftingSlotInvalid(msg.sender, slotId);
        }

        // Require free slot
        if (playerDatas[msg.sender].slots[slotId].finished > 0)
        {
            revert CraftingSlotOccupied(msg.sender, slotId);
        }

        // Deduct resources (send to treasury) 
        for (uint i = 0; i < recipes[asset][recipe].ingredientsIndex.length; i++)
        {
            IInventories(inventoriesContract)
                .__deductFungibleToken(
                    msg.sender, 
                    inventory, 
                    recipes[asset][recipe].ingredientsIndex[i], 
                    recipes[asset][recipe].ingredients[recipes[asset][recipe].ingredientsIndex[i]],
                    true);
        }

        // Add to slot
        playerDatas[msg.sender].slots[slotId].asset = asset;
        playerDatas[msg.sender].slots[slotId].recipe = recipe;
        playerDatas[msg.sender].slots[slotId].finished = block.timestamp + recipes[asset][recipe].craftingTime;

        // Emit
        emit CraftingStart(msg.sender, asset, recipe, slotId, playerDatas[msg.sender].slots[slotId].finished);
    }


    /// @dev Claims (mints) the previously crafted item (ERC721) in `slot` after sufficient crafting time has passed (started by calling craft(..)) 
    /// @param slotId The number (non-zero based) of the slot to claim
    /// @param inventory The inventory space to mint the crafted item into ({Ship|Backpack}) 
    function claim(uint slotId, Inventory inventory)
        validInventory(inventory)
        public virtual override 
    {
        // Require slot occupied
        if (playerDatas[msg.sender].slots[slotId].finished == 0)
        {
            revert CraftingSlotIsEmpty(msg.sender, slotId);
        }

        // Require slot ready
        if (playerDatas[msg.sender].slots[slotId].finished > block.timestamp)
        {
            revert CraftingSlotNotReady(msg.sender, slotId);
        }

        address asset = playerDatas[msg.sender].slots[slotId].asset;
        bytes32 item = playerDatas[msg.sender].slots[slotId].recipe;

        // Reset slot
        _resetSlot(msg.sender, slotId);

        // Mint item
        uint tokenId = ICraftable(asset)
            .__craft(item, msg.sender, inventory);
            
        // Assert
        assert(tokenId > 0); 

        // Emit
        emit CraftingClaim(msg.sender, asset, item, slotId, tokenId);
    }


    /// @dev Discards the item in a slot without claiming it (without refunding ingredients, if any)
    /// @param slotId The number (non-zero based) of the item to discard
    function discard(uint slotId) 
        public virtual override 
    {
        // Require slot occupied
        CraftingSlot memory slot = playerDatas[msg.sender].slots[slotId];
        if (slot.finished == 0)
        {
            revert CraftingSlotIsEmpty(msg.sender, slotId);
        }

        _resetSlot(msg.sender, slotId);

        // Emit
        emit CraftingDiscard(msg.sender, slot.asset, slot.recipe, slotId);
    }


    /**
     * System functions
     */
    /// @dev Set the crafting `slotCount` for `player`
    /// @param player The player to set the slot count for
    /// @param slotCount The new slot count
    function __setCraftingSlots(address player, uint slotCount)
        onlyRole(SYSTEM_ROLE) 
        public virtual 
    {
        playerDatas[player].slotCount = slotCount;

        // Emit
        emit CraftingSlotCountChange(player, slotCount);
    }


    /// @dev The `player` is able to craft the item after learning the `asset` `recipe` 
    /// @param player The player that learns the recipe
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param item The that can be crafted
    function __learn(address player, address asset, bytes32 item) 
        onlyRole(SYSTEM_ROLE)
        public virtual
    {
        // System only
        playerDatas[player].learned[asset][item] = true;
        playerDatas[player].learnedIndex[asset].push(item);

        // Emit
        emit CraftingRecipeLearn(player, asset, item);
    }


    /** 
     * Internal functions
     */
    /// @dev Checks if an `asset` recipe with `item` exists
    /// @param asset The asset to wich the recipe applies
    /// @param item The item of the recipe to check
    /// @return bool True if the recipe exists
    function _recipeExists(address asset, bytes32 item)
        internal view 
        returns (bool)
    {
        return recipes[asset][item].level > 0;
    }


    /// @dev Returns a single `asset` recipe by `item` 
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param item The item of the asset recipe
    /// @return recipe The recipe
    function _getRecipe(address asset, bytes32 item)
        internal view 
        returns (CraftingRecipe memory recipe)
    {
        CraftingRecipeData storage data = recipes[asset][item];
        recipe = CraftingRecipe(
            data.level,
            data.learnable,
            asset,
            item,
            data.craftingTime,
            new CraftingRecipeIngredient[](data.ingredientsIndex.length));

        for (uint i = 0; i < data.ingredientsIndex.length; i++)
        {
            recipe.ingredients[i] = CraftingRecipeIngredient(
                data.ingredientsIndex[i], 
                data.ingredients[data.ingredientsIndex[i]]);
        }
    }


    /// @dev Set a single recipe
    /// @param recipe_ The recipe to set
    function _setRecipe(CraftingRecipe memory recipe_) 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        public virtual 
    {
        if (!_recipeExists(recipe_.asset, recipe_.item))
        {
            // Add index
            recipes[recipe_.asset][recipe_.item].index = recipesIndex[recipe_.asset].length;
            recipesIndex[recipe_.asset].push(recipe_.item);
        }

        // Set values
        CraftingRecipeData storage recipe = recipes[recipe_.asset][recipe_.item];
        recipe.level = recipe_.level;
        recipe.learnable = recipe_.learnable;
        recipe.craftingTime = recipe_.craftingTime;
        
        // Reset ingredients
        if (recipe.ingredientsIndex.length > 0)
        {
            for (uint i = 0; i < recipe.ingredientsIndex.length; i++)
            {
                delete recipe.ingredients[recipe.ingredientsIndex[i]];
            }

            delete recipe.ingredientsIndex;
        }

        // Set ingredients
        for (uint i = 0; i < recipe_.ingredients.length; i++)
        {
            recipe.ingredientsIndex.push(recipe_.ingredients[i].asset);
            recipe.ingredients[recipe_.ingredients[i].asset] = recipe_.ingredients[i].amount;
        }

        // Emit
        emit CraftingRecipeMutation(recipe_.asset, recipe_.item);
    }


    /// @dev Resets a crafting `slot` for `player` by setting it's values to their defaults
    /// @param player The owner of the crafting slot
    /// @param slotId The index (non zero based) of the slot to reset
    function _resetSlot(address player, uint slotId)
        internal 
    {
        playerDatas[player].slots[slotId].asset = address(0);
        playerDatas[player].slots[slotId].recipe = bytes32(0);
        playerDatas[player].slots[slotId].finished = 0;
    }
}