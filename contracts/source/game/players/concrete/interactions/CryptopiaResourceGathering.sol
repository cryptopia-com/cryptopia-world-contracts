// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "../../../../tokens/ERC20/concrete/CryptopiaERC20Retriever.sol";
import "../../../../tokens/ERC20/assets/IAssetToken.sol";
import "../../../../tokens/ERC721/tools/ITools.sol";
import "../../../../tokens/ERC721/tools/errors/ToolErrors.sol";   
import "../../../maps/IMaps.sol";
import "../../../players/IPlayerRegister.sol";
import "../../../inventories/IInventories.sol";
import "../../../inventories/errors/InventoryErrors.sol";
import "../../../assets/IAssetRegister.sol";
import "../../../assets/types/AssetEnums.sol";
import "../../../errors/TimingErrors.sol";
import "../../interactions/IResourceGathering.sol";

/// @title Allows players to mint non-finite resources
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaResourceGathering is ContextUpgradeable, CryptopiaERC20Retriever, IResourceGathering {

    /** 
     * Storage
     */
    uint24 constant private XP_BASE = 50;
    uint constant private COOLDOWN_BASE = 60 seconds;
    uint24 constant private MULTIPLIER_PRECISION = 100;
    uint constant private RESOURCE_PRECISION = 1_000_000_000_000_000_000;

    // Refs
    address public mapContract;
    address public assetRegisterContract;
    address public playerRegisterContract;
    address public inventoriesContract;
    address public toolTokenContract;

    // Player => resource => cooldown
    mapping (address => mapping (Resource => uint)) playerCooldown;


    /**
     * Errors
     */
    /// @dev Thrown when a player attempts to mint a resource, but the resource is not available at the player's location
    /// @param resource The resource that is not available at the player's location
    /// @param player The player that attempted to mint the resource
    error ResourceUnavailableAtLocation(Resource resource, address player);


    /** 
     * Public functions
     */
    /// @param _mapContract Location of the map contract
    /// @param _assetRegisterContract Location of the asset register contract
    /// @param _playerRegisterContract Location of the player register contract
    /// @param _inventoriesContract Location of the inventories contract
    /// @param _toolTokenContract Location of the tool token contract
    function initialize(
        address _mapContract, 
        address _assetRegisterContract,
        address _playerRegisterContract,
        address _inventoriesContract,
        address _toolTokenContract) 
        public initializer 
    {
        __Context_init();

        // Assign refs
        mapContract = _mapContract;
        assetRegisterContract = _assetRegisterContract;
        playerRegisterContract = _playerRegisterContract;
        inventoriesContract = _inventoriesContract;
        toolTokenContract = _toolTokenContract;
    }


    /// @dev Returns the timestamp at which `player` can mint `resource` again
    /// @param player the account to retrieve the cooldown timestamp for
    /// @param resource the resource to retrieve the cooldown timestamp for
    /// @return uint cooldown timestamp at which `player` can mint `resource` again
    function getCooldown(address player, Resource resource) 
        public virtual override view 
        returns (uint) 
    {
        return playerCooldown[player][resource];
    }


    /// @dev Mint `asset` to sender's inventory
    /// @param resource The {AssetEnums} to mint 
    /// @param tool The token ID of the tool used to mint the resource (0 means no tool)
    /// @param limit The maximum amount of tokens to mint (limit to prevent full backpack)
    function mint(Resource resource, uint tool, uint limit) 
        public virtual override 
    {
        address player = _msgSender();
        uint amount = _getResourceAmount(player, resource);

        // Check if resource is available at location
        if (amount == 0) 
        {
            revert ResourceUnavailableAtLocation(resource, player);
        }

        uint24 xp;
        uint cooldown;

        // Use tool
        if (_requiresTool(resource))
        {
            // Check if required tool is provided
            if (tool == 0) 
            {
                revert ToolRequiredForMinting(resource);
            }

            // Check if tool is in backpack of player
            (address owner, Inventory inventory) = IInventories(inventoriesContract)
                .getNonFungibleTokenData(toolTokenContract, tool);

            if (owner != player || inventory != Inventory.Backpack) 
            {
                revert InventoryItemNotFound(player, Inventory.Backpack, toolTokenContract, tool);
            }

            // Apply tool effects
            (uint24 multiplier_cooldown, uint24 multiplier_xp, uint24 multiplier_effectiveness) = ITools(toolTokenContract)
                .__useForMinting(player, tool, resource, limit < amount ? limit : amount);

            xp = uint24(XP_BASE * (limit < amount ? limit : amount) / RESOURCE_PRECISION * multiplier_xp / MULTIPLIER_PRECISION);
            amount = amount * multiplier_effectiveness / MULTIPLIER_PRECISION;
            cooldown = COOLDOWN_BASE * multiplier_cooldown / MULTIPLIER_PRECISION;
        }
        else 
        {
            xp = uint24(XP_BASE * (limit < amount ? limit : amount) / RESOURCE_PRECISION);
            cooldown = COOLDOWN_BASE;
        }

        // Cooldown
        if (playerCooldown[player][resource] > block.timestamp) 
        {
            revert CooldownActive(player, playerCooldown[player][resource]);
        }

        playerCooldown[player][resource] = block.timestamp + cooldown;

        // Resolve resource
        address asset = IAssetRegister(assetRegisterContract)
            .getAssetByResrouce(resource);

        // Mint tokens to inventory
        IAssetToken(asset)
            .__mintTo(inventoriesContract, (limit < amount ? limit : amount));

        // Assign tokens to player
        IInventories(inventoriesContract)
            .__assignFungibleToken(player, Inventory.Backpack, asset, (limit < amount ? limit : amount));

        // Award XP
        IPlayerRegister(playerRegisterContract)
            .__award(player, xp, 0);
    }


    /// @dev Returns data about the players ability to interact with resources 
    /// @param account Player to retrieve data for
    /// @param resource Type of resource to test for
    /// @return uint the amount of `resource` that can be minted
    function _getResourceAmount(address account, Resource resource) 
        internal view 
        returns (uint)
    {
        (
            uint16 tileIndex, 
            bool canInteract
        ) = IMaps(mapContract).getPlayerLocationData(account);

        TileStatic memory tile = IMaps(mapContract)
            .getTileDataStatic(tileIndex);

        if (!canInteract)
        {
            return 0; // Traveling
        }

        // Fish
        if (resource == Resource.Fish)
        {
            // On the sea
            if (tile.waterLevel > tile.elevationLevel)
            {
                return (tile.waterLevel - tile.elevationLevel) * RESOURCE_PRECISION;
            }

            // On land (has lake)
            else if (tile.hasLake)
            {
                return RESOURCE_PRECISION;
            }

            // On land (no lake)
            return 0;
        }

        // Meat
        if (resource == Resource.Meat)
        {
            if (tile.waterLevel > tile.elevationLevel)
            {
                return 0;
            }

            return RESOURCE_PRECISION;
        }

        // Fruit || Wood
        if (resource == Resource.Fruit || resource == Resource.Wood)
        {
            if (tile.waterLevel > tile.elevationLevel)
            {
                return 0;
            }

            return RESOURCE_PRECISION;
        }
        
        // Stone
        if (resource == Resource.Stone)
        {
            if (tile.waterLevel > tile.elevationLevel)
            {
                return 0;
            }

            return RESOURCE_PRECISION;
        }

        // Sand
        if (resource == Resource.Sand)
        {
            if (tile.waterLevel > tile.elevationLevel)
            {
                return 0;
            }

            return RESOURCE_PRECISION;
        }

        return 0;
    }


    /**
     * Internal functions
     */
    /// @dev Returns true if the minting of `resource` requires the use of a tool
    /// @param resource {Resource} the resource to mint
    /// @return bool True if `resource` requires a tool to mint
    function _requiresTool(Resource resource)
        internal pure 
        returns (bool)
    {
        return resource != Resource.Fruit;
    }
}