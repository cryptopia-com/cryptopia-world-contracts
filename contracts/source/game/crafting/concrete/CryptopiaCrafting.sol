// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../../players/errors/PlayerErrors.sol";
import "../../inventories/types/InventoryEnums.sol";
import "../../inventories/errors/InventoryErrors.sol";
import "../../inventories/IInventories.sol";
import "../ICraftable.sol";
import "../ICrafting.sol";

/// @title Cryptopia Crafting 
/// @dev Allows the player to craft Non-fungible assets (ERC721) based on recepies
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaCrafting is Initializable, AccessControlUpgradeable, ICrafting {

    struct Recipe 
    {
        uint8 level; // Level zero indicated not initialized
        bool learnable;

        // Crafting
        uint240 craftingTime;

        // Ingredients
        mapping (address => uint) ingredients;
        address[] ingredientsIndex;
    }

    struct CraftingSlot
    {
        address asset;
        bytes32 recipe;
        uint finished;        
    }

    struct PlayerData 
    {
        // Slots
        uint slotCount; // Zero indicates not initiated

        /// @dev index => CraftingSlot
        mapping (uint => CraftingSlot) slots;

        /// @dev asset (ERC721) => recipe name => learned
        mapping (address => mapping (bytes32 => bool)) learned;
        mapping (address => bytes32[]) learnedIndex;
    }


    /**
     * Roles
     */
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage
     */
    /// @dev asset (ERC721) => name => Recipe
    mapping (address => mapping (bytes32 => Recipe)) public recipes;
    mapping (address => bytes32[]) private recipesIndex;

    /// @dev player => PlayerData
    mapping (address => PlayerData) private playerData;

    /// Refs
    address public inventoriesContract;


    /**
     * Events
     */
    /// @dev Called when the crafting of `asset` `recipe` was started by `player`
    /// @param player The player that is crafting the item
    /// @param asset The address of the ERC721 contract
    /// @param recipe The recipe (name) that is crafted
    /// @param slot The slot used to craft the item
    /// @param finished The datetime at which the item can be claimed
    event CraftingStart(address indexed player, address indexed asset, bytes32 indexed recipe, uint slot, uint finished);

    /// @dev Called when the crafted `asset` item in `slot` was claimed by `player`
    /// @param player The player that crafted the item
    /// @param asset The address of the ERC721 contract
    /// @param item The item (recipe) that was crafted
    /// @param slot The slot used to craft the item
    /// @param tokenId The token ID of the crafted item
    event CraftingClaim(address indexed player, address indexed asset, bytes32 indexed item, uint slot, uint tokenId);

    /// @dev Called when the crafting `slotCount` of `player` was updated
    /// @param player The player whos slot count was modified
    /// @param slotCount the new slot count
    event CraftingSlotCountChange(address indexed player, uint slotCount);

    /// @dev Called when the `asset` `recipe` was mutated
    /// @param asset The address of the ERC721 contract
    /// @param recipe The recipe (name) that was mutated
    event CraftingRecipeMutation(address indexed asset, bytes32 indexed recipe);

    /// @dev Called when the `player` learned `asset` `recipe` 
    /// @param player The player that learned the recipe
    /// @param asset The address of the ERC721 contract
    /// @param recipe The recipe (name) that was learned
    event CraftingRecipeLearn(address indexed player, address indexed asset, bytes32 indexed recipe);


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
        if (playerData[player].slotCount == 0)
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


    /** 
     * Admin functions
     */
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


    /// @dev Set the crafting `slotCount` for `player`
    /// @param player The player to set the slot count for
    /// @param slotCount The new slot count
    function setCraftingSlots(address player, uint slotCount)
        onlyRole(SYSTEM_ROLE) 
        public virtual 
    {
        playerData[player].slotCount = slotCount;

        // Emit
        emit CraftingSlotCountChange(player, slotCount);
    }
    

    /// @dev Batch operation to set recepes
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param name The name of the asset recipe
    /// @param level Recipe can be crafted and/or learned by players from this level
    /// @param learnable True indicates that the recipe has to be learned before it can be used
    /// @param craftingTime The time it takes to craft an item
    /// @param ingredients_asset Resource contracts (ERC777) needed for crafting
    /// @param ingredients_amount Resource amounts needed for crafting
    function setRecipes(
        address[] memory asset,
        bytes32[] memory name,
        uint8[] memory level,
        bool[] memory learnable,
        uint240[] memory craftingTime,
        address[][] memory ingredients_asset,
        uint[][] memory ingredients_amount) 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        public virtual 
    {
        for (uint i = 0; i < asset.length; i++)
        {
            if (!_recipeExists(asset[i], name[i]))
            {
                // Add index
                recipesIndex[asset[i]].push(name[i]);
            }

            // Set values
            Recipe storage recipe = recipes[asset[i]][name[i]];
            recipe.level = level[i];
            recipe.learnable = learnable[i];
            recipe.craftingTime = craftingTime[i];
            
            // Reset ingredients
            if (recipe.ingredientsIndex.length > 0)
            {
                for (uint j = 0; j < recipe.ingredientsIndex.length; j++)
                {
                    recipe.ingredients[recipe.ingredientsIndex[j]] = 0;
                }

                delete recipe.ingredientsIndex;
            }

            // Set ingredients
            for (uint j = 0; j < ingredients_asset[i].length; j++)
            {
                recipe.ingredientsIndex.push(ingredients_asset[i][j]);
                recipe.ingredients[ingredients_asset[i][j]] = ingredients_amount[i][j];
            }

            // Emit
            emit CraftingRecipeMutation(asset[i], name[i]);
        }
    }


    /// @dev The `player` is able to craft the item after learning the `asset` `recipe` 
    /// @param player The player that learns the recipe
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param recipe The name of the asset recipe
    function learn(address player, address asset, bytes32 recipe) 
        onlyRole(SYSTEM_ROLE)
        public virtual
    {
        // System only
        playerData[player].learned[asset][recipe] = true;
        playerData[player].learnedIndex[asset].push(recipe);

        // Emit
        emit CraftingRecipeLearn(player, asset, recipe);
    }


    /** 
     * Public functions
     */
    /// @dev Returns the amount of different `asset` recipes
    /// @param asset The contract address of the asset to which the recipes apply
    /// @return count The amount of different recipes
    function getRecipeCount(address asset) public view returns (uint256) 
    {
        return recipesIndex[asset].length;
    }


    /// @dev Returns a single `asset` recipe at `index`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param index The index of the asset recipe
    /// @return level Recipe can be crafted and/or learned by players from this level
    /// @return learnable True indicates that the recipe has to be learned before it can be used
    /// @return craftingTime The time it takes to craft an item
    /// @return ingredients_asset Resource contracts (ERC777) needed for crafting
    /// @return ingredients_amount Resource amounts needed for crafting
    function getRecipeAt(address asset, uint index)
        public virtual override view 
        returns (
            uint8 level,
            bool learnable,
            uint240 craftingTime,
            address[] memory ingredients_asset,
            uint[] memory ingredients_amount
        )
    {
        Recipe storage recipe = recipes[asset][recipesIndex[asset][index]];
        level = recipe.level;
        learnable = recipe.learnable;
        craftingTime = recipe.craftingTime;
        ingredients_asset = new address[](recipe.ingredientsIndex.length);
        ingredients_amount = new uint[](recipe.ingredientsIndex.length);

        for (uint i = 0; i < recipe.ingredientsIndex.length; i++)
        {
            ingredients_asset[i] = recipe.ingredientsIndex[i];
            ingredients_amount[i] = recipe.ingredients[recipe.ingredientsIndex[i]];
        }
    }


    /// @dev Returns a single `asset` recipe at `index`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param index The index of the asset recipe
    /// @return assets Resource contracts (ERC777) needed for crafting
    /// @return amounts Resource amounts needed for crafting
    function getRecipeIngredientsAt(address asset, uint index)
        public virtual override view 
        returns (
            address[] memory assets,
            uint[] memory amounts
        )
    {
        Recipe storage recipe = recipes[asset][recipesIndex[asset][index]];
        assets = new address[](recipe.ingredientsIndex.length);
        amounts = new uint[](recipe.ingredientsIndex.length); 

        for (uint i = 0; i < recipe.ingredientsIndex.length; i++)
        {
            assets[i] = recipe.ingredientsIndex[i];
            amounts[i] = recipe.ingredients[recipe.ingredientsIndex[i]];
        }
    }


    /// @dev Returns a single `asset` recipe by `name`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param name The name of the asset recipe
    /// @return level Recipe can be crafted and/or learned by players from this level
    /// @return learnable True indicates that the recipe has to be learned before it can be used
    /// @return craftingTime The time it takes to craft an item
    /// @return ingredients_asset Resource contracts (ERC777) needed for crafting
    /// @return ingredients_amount Resource amounts needed for crafting
    function getRecipe(address asset, bytes32 name)
        public virtual override view 
        returns (
            uint8 level,
            bool learnable,
            uint240 craftingTime,
            address[] memory ingredients_asset,
            uint[] memory ingredients_amount
        )
    {
        Recipe storage recipe = recipes[asset][name];
        level = recipe.level;
        learnable = recipe.learnable;
        craftingTime = recipe.craftingTime;
        ingredients_asset = new address[](recipe.ingredientsIndex.length);
        ingredients_amount = new uint[](recipe.ingredientsIndex.length);

        for (uint i = 0; i < recipe.ingredientsIndex.length; i++)
        {
            ingredients_asset[i] = recipe.ingredientsIndex[i];
            ingredients_amount[i] = recipe.ingredients[recipe.ingredientsIndex[i]];
        }
    }


    /// @dev Returns a single `asset` recipe by `name`
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param name The name of the asset recipe
    /// @return assets Resource contracts (ERC777) needed for crafting
    /// @return amounts Resource amounts needed for crafting
    function getRecipeIngredients(address asset, bytes32 name)
        public virtual override view 
        returns (
            address[] memory assets,
            uint[] memory amounts
        )
    {
        Recipe storage recipe = recipes[asset][name];
        assets = recipe.ingredientsIndex;

        amounts = new uint[](recipe.ingredientsIndex.length);
        for (uint i = 0; i < recipe.ingredientsIndex.length; i++)
        {
            amounts[i] = recipe.ingredients[recipe.ingredientsIndex[i]];
        }
    }


    /// @dev Retrieve a range of `asset` recipes
    /// @param asset The contract address of the asset to which the recipes apply
    /// @param skip Starting index
    /// @param take Amount of recipes
    /// @return name Recipe name
    /// @return level Recipe can be crafted and/or learned by players from this level
    /// @return learnable True indicates that the recipe has to be learned before it can be used
    /// @return craftingTime The time it takes to craft an item
    /// @return ingredient_count The number of different ingredients needed to craft this item
    function getRecipes(address asset, uint skip, uint take)
        public virtual override view 
        returns (
            bytes32[] memory name,
            uint8[] memory level,
            bool[] memory learnable,
            uint240[] memory craftingTime,
            uint[] memory ingredient_count
        )
    {
        name = new bytes32[](take);
        level = new uint8[](take);
        learnable = new bool[](take);
        craftingTime = new uint240[](take);
        ingredient_count = new uint[](take);

        uint index = skip;
        for (uint32 i = 0; i < take; i++)
        {   
            name[i] = recipesIndex[asset][index];
            level[i] = recipes[asset][name[i]].level;
            learnable[i] = recipes[asset][name[i]].learnable;
            craftingTime[i] = recipes[asset][name[i]].craftingTime;
            ingredient_count[i] = recipes[asset][name[i]].ingredientsIndex.length;
            index++;
        }
    }


    /// @dev Retrieve a range of `asset` recipes
    /// @param asset The contract address of the asset to which the recipes apply
    /// @param skip Starting index
    /// @param take Amount of recipes
    /// @return asset1 Resource contracts (ERC777) needed for crafting
    /// @return asset2 Resource contracts (ERC777) needed for crafting
    /// @return asset3 Resource contracts (ERC777) needed for crafting
    /// @return asset4 Resource contracts (ERC777) needed for crafting
    /// @return amount1 Resource amounts needed for crafting
    /// @return amount2 Resource amounts needed for crafting
    /// @return amount3 Resource amounts needed for crafting
    /// @return amount4 Resource amounts needed for crafting
    function getRecipesIngredients(address asset, uint skip, uint take)
        public virtual override view 
        returns (
            address[] memory asset1,
            address[] memory asset2,
            address[] memory asset3,
            address[] memory asset4,
            uint[] memory amount1,
            uint[] memory amount2,
            uint[] memory amount3,
            uint[] memory amount4
        )
    {
        asset1 = new address[](take);
        asset2 = new address[](take);
        asset3 = new address[](take);
        asset4 = new address[](take);
        amount1 = new uint[](take);
        amount2 = new uint[](take);
        amount3 = new uint[](take);
        amount4 = new uint[](take);

        for (uint32 i = 0; i < take; i++)
        {   
            bytes32 name = recipesIndex[asset][skip];

            if (recipes[asset][name].ingredientsIndex.length > 0)
            {
                asset1[i] = recipes[asset][name].ingredientsIndex[0];
                amount1[i] = recipes[asset][name].ingredients[asset1[i]];
            }

            if (recipes[asset][name[i]].ingredientsIndex.length > 1)
            {
                asset2[i] = recipes[asset][name].ingredientsIndex[1];
                amount2[i] = recipes[asset][name].ingredients[asset2[i]];
            }

            if (recipes[asset][name[i]].ingredientsIndex.length > 2)
            {
                asset3[i] = recipes[asset][name].ingredientsIndex[2];
                amount3[i] = recipes[asset][name].ingredients[asset3[i]];
            }

            if (recipes[asset][name[i]].ingredientsIndex.length > 3)
            {
                asset4[i] = recipes[asset][name].ingredientsIndex[3];
                amount4[i] = recipes[asset][name].ingredients[asset4[i]];
            }

            skip++;
        }
    }

    
    /// @dev Returns the number of `asset` recipes that `player` has learned
    /// @param player The player to retrieve the learned recipe count for
    /// @param asset The contract address of the asset to which the recipes apply
    /// @return uint The number of `asset` recipes learned
    function getLearnedRecipeCount(address player, address asset) 
        public virtual override view 
        returns (uint)
    {
        return playerData[player].learnedIndex[asset].length;
    }


    /// @dev Returns the `asset` recipe at `index` for `player`
    /// @param player The player to retrieve the learned recipe for
    /// @param asset The contract address of the asset to which the recipe applies
    /// @return bytes32 The recipe name
    function getLearnedRecipeAt(address player, address asset, uint index) 
        public virtual override view 
        returns (bytes32)
    {
        return playerData[player].learnedIndex[asset][index];
    }


    /// @dev Returns the `asset` recipe at `index` for `player`
    /// @param player The player to retrieve the learned recipe for
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param skip Starting index
    /// @param take Amount of recipes
    /// @return bytes32[] The recipe names
    function getLearnedRecipes(address player, address asset, uint skip, uint take) 
        public virtual override view 
        returns (bytes32[] memory)
    {
        bytes32[] memory response = new bytes32[](take);

        uint index = skip;
        for (uint i = 0; i < playerData[player].learnedIndex[asset].length; i++)
        {
            response[i] = playerData[player].learnedIndex[asset][index];
            index++;
        }

        return response;
    }


    /// @dev Returns the total number of crafting slots for `player`
    /// @param player The player to retrieve the slot count for
    /// @return uint The total number of slots
    function getSlotCount(address player) 
        public virtual override view 
        returns (uint)
    {
        return playerData[player].slotCount;
    }


    /// @dev Returns a single crafting slot for `player` by `slot` index (non-zero based)
    /// @param player The player to retrieve the slot data for
    /// @param slot The slot index (non-zero based)
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param recipe The name of the recipe that is being crafted 
    /// @param finished The timestamp after which the crafted item can be claimed
    function getSlot(address player, uint slot)
        public virtual override view 
        returns (
            address asset,
            bytes32 recipe,
            uint finished
        )
    {
        asset = playerData[player].slots[slot].asset;
        recipe = playerData[player].slots[slot].recipe;
        finished = playerData[player].slots[slot].finished;
    }


    /// @dev Returns a range of crafting slot for `player`
    /// @param player The player to retrieve the slot data for
    /// @param slot The slot index (non-zero based)
    /// @param asset The contract address of the asset to which the recipe applies
    /// @param recipe The name of the recipe that is being crafted 
    /// @param finished The timestamp after which the crafted item can be claimed
    function getSlots(address player) 
        public virtual override view 
        returns (
            uint[] memory slot,
            address[] memory asset,
            bytes32[] memory recipe,
            uint[] memory finished
        )
    {
        uint slotCount = playerData[player].slotCount;
        slot = new uint[](slotCount);
        asset = new address[](slotCount);
        recipe = new bytes32[](slotCount);
        finished = new uint[](slotCount);

        for (uint i = 0; i < slotCount; i++)
        {
            slot[i] = i + 1;
            asset[i] = playerData[player].slots[slot[i]].asset;
            recipe[i] = playerData[player].slots[slot[i]].recipe;
            finished[i] = playerData[player].slots[slot[i]].finished;
        }
    }


    /// @dev Start the crafting process (completed by calling claim(..) after the crafting time has passed) of an item (ERC721)
    /// @param asset The contract address of the asset to which the recipes apply
    /// @param recipe The name of the recipe to craft
    /// @param slot The index (non-zero based) of the crafting slot to use
    /// @param inventory The inventory space to deduct ingredients from ({Ship|Backpack})
    function craft(address asset, bytes32 recipe, uint slot, Inventory inventory) 
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
            !playerData[msg.sender].learned[asset][recipe]) 
        {
            revert CraftingRecipeNotLearned(msg.sender, asset, recipe);
        }

        // Require a valid slot
        if (slot == 0 || slot > playerData[msg.sender].slotCount)
        {
            revert CraftingSlotInvalid(msg.sender, slot);
        }

        // Require free slot
        if (playerData[msg.sender].slots[slot].finished > 0)
        {
            revert CraftingSlotOccupied(msg.sender, slot);
        }

        // Deduct resources (send to treasury) 
        for (uint i = 0; i < recipes[asset][recipe].ingredientsIndex.length; i++)
        {
            IInventories(inventoriesContract)
                .deductFungibleToken(
                    msg.sender, 
                    inventory, 
                    recipes[asset][recipe].ingredientsIndex[i], 
                    recipes[asset][recipe].ingredients[recipes[asset][recipe].ingredientsIndex[i]]);
        }

        // Add to slot
        playerData[msg.sender].slots[slot].asset = asset;
        playerData[msg.sender].slots[slot].recipe = recipe;
        playerData[msg.sender].slots[slot].finished = block.timestamp + recipes[asset][recipe].craftingTime;

        // Emit
        emit CraftingStart(msg.sender, asset, recipe, slot, playerData[msg.sender].slots[slot].finished);
    }


    /// @dev Claims (mints) the previously crafted item (ERC721) in `slot` after sufficient crafting time has passed (started by calling craft(..)) 
    /// @param slot The number (non-zero based) of the slot to claim
    /// @param inventory The inventory space to mint the crafted item into ({Ship|Backpack}) 
    function claim(uint slot, Inventory inventory)
        validInventory(inventory)
        public virtual override 
    {
        // Require slot occupied
        if (playerData[msg.sender].slots[slot].finished == 0)
        {
            revert CraftingSlotIsEmpty(msg.sender, slot);
        }

        // Require slot ready
        if (playerData[msg.sender].slots[slot].finished > block.timestamp)
        {
            revert CraftingSlotNotReady(msg.sender, slot);
        }

        address asset = playerData[msg.sender].slots[slot].asset;
        bytes32 item = playerData[msg.sender].slots[slot].recipe;

        // Reset slot
        _resetSlot(msg.sender, slot);

        // Mint item
        uint tokenId = ICraftable(asset).craft(
            item, msg.sender, inventory);
            
        // Assert
        assert(tokenId > 0); 

        // Emit
        emit CraftingClaim(msg.sender, asset, item, slot, tokenId);
    }


    /// @dev Empties a slot without claiming the crafted item (without refunding ingredients, if any)
    /// @param slot The number (non-zero based) of the slot to empty
    function empty(uint slot) 
        public virtual override 
    {
        _resetSlot(msg.sender, slot);
    }


    /** 
     * Internal functions
     */
    /// @dev Checks if an `asset` recipe with `name` exists
    /// @param asset The asset to wich the recipe applies
    /// @param name The name of the recipe to check
    /// @return bool True if the recipe exists
    function _recipeExists(address asset, bytes32 name)
        internal view 
        returns (bool)
    {
        return recipes[asset][name].level > 0;
    }


    /// @dev Resets a crafting `slot` for `player` by setting it's values to their defaults
    /// @param player The owner of the crafting slot
    /// @param slot The index (non zero based) of the slot to reset
    function _resetSlot(address player, uint slot)
        internal 
    {
        playerData[player].slots[slot].asset = address(0);
        playerData[player].slots[slot].recipe = bytes32(0);
        playerData[player].slots[slot].finished = 0;
    }
}