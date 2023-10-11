// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "../../../../tokens/ERC20/retriever/TokenRetriever.sol";
import "../../../../tokens/ERC721/tools/ITools.sol";
import "../../../../tokens/ERC721/tools/errors/ToolErrors.sol";   
import "../../../../tokens/ERC777/assets/IAssetToken.sol";
import "../../../maps/CryptopiaMap/ICryptopiaMap.sol";
import "../../../players/IPlayerRegister.sol";
import "../../../inventories/IInventories.sol";
import "../../../inventories/errors/InventoryErrors.sol";
import "../../../assets/IAssetRegister.sol";
import "../../../assets/types/AssetEnums.sol";
import "../../../errors/GameErrors.sol";
import "../../interactions/IResourceGathering.sol";

/// @title Allows players to mint non-finite resources
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaResourceFaucet is ContextUpgradeable, TokenRetriever, IResourceGathering {

    /** 
     * Storage
     */
    uint24 constant XP_BASE = 50;
    uint constant COOLDOWN_BASE = 60 seconds;
    uint24 constant MULTIPLIER_PRECISION = 100;
    uint constant RESOURCE_PRECISION = 1_000_000_000_000_000_000;

    // Refs
    address public mapContract;
    address public assetRegisterContract;
    address public playerRegisterContract;
    address public inventoriesContract;
    address public toolTokenContract;

    // Player => resource => cooldown
    mapping (address => mapping (ResourceType => uint)) playerCooldown;


    /**
     * Errors
     */
    /// @dev Thrown when a player attempts to mint a resource, but the resource is not available at the player's location
    /// @param resource The resource that is not available at the player's location
    /// @param player The player that attempted to mint the resource
    error ResourceUnavailableAtLocation(ResourceType resource, address player);


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
    function getCooldown(address player, ResourceType resource) 
        public virtual override view 
        returns (uint) 
    {
        return playerCooldown[player][resource];
    }


    /// @dev Mint `asset` to sender's inventory
    /// @param resource The {AssetEnums} to mint 
    /// @param tool The token ID of the tool used to mint the resource (0 means no tool)
    /// @param limit The maximum amount of tokens to mint (limit to prevent full backpack)
    function mint(ResourceType resource, uint tool, uint limit) 
        public virtual override 
    {
        address player = _msgSender();
        uint amount = ICryptopiaMap(mapContract)
            .getPlayerResourceData(player, resource);

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
                .useForMinting(player, tool, resource, limit < amount ? limit : amount);

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
            .mintTo(inventoriesContract, (limit < amount ? limit : amount));

        // Assign tokens to player
        IInventories(inventoriesContract)
            .assignFungibleToken(player, Inventory.Backpack, asset, (limit < amount ? limit : amount));

        // Award XP
        IPlayerRegister(playerRegisterContract)
            .award(player, xp, 0);
    }


    /**
     * Internal functions
     */
    /// @dev Returns true if the minting of `resource` requires the use of a tool
    /// @param resource {ResourceType} the resource to mint
    /// @return bool True if `resource` requires a tool to mint
    function _requiresTool(ResourceType resource)
        internal pure 
        returns (bool)
    {
        return resource != ResourceType.Fruit;
    }
}