// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./ICryptopiaResourceFaucet.sol";
import "../../map/CryptopiaMap/ICryptopiaMap.sol";
import "../../players/CryptopiaPlayerRegister/ICryptopiaPlayerRegister.sol";
import "../../inventories/CryptopiaInventories/ICryptopiaInventories.sol";
import "../../../assets/AssetEnums.sol";
import "../../../assets/CryptopiaAssetRegister/ICryptopiaAssetRegister.sol";
import "../../../tokens/ERC20/retriever/TokenRetriever.sol";
import "../../../tokens/ERC721/CryptopiaToolToken/ICryptopiaToolToken.sol";
import "../../../tokens/ERC777/CryptopiaAssetToken/ICryptopiaAssetToken.sol";

/// @title Allows players to mint non-finite resources
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaResourceFaucet is ICryptopiaResourceFaucet, ContextUpgradeable, TokenRetriever {

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
    mapping (address => mapping (AssetEnums.Resource => uint)) playerCooldown;


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
    function getCooldown(address player, AssetEnums.Resource resource) 
        public virtual override view 
        returns (uint) 
    {
        return playerCooldown[player][resource];
    }


    /// @dev Mint `asset` to sender's inventory
    /// @param resource The {AssetEnums} to mint 
    /// @param tool The token ID of the tool used to mint the resource (0 means no tool)
    /// @param limit The maximum amount of tokens to mint (limit to prevent full backpack)
    function mint(AssetEnums.Resource resource, uint tool, uint limit) 
        public virtual override 
    {
        address player = _msgSender();
        uint amount = ICryptopiaMap(mapContract).getPlayerResourceData(player, resource);
        require(amount > 0, "CryptopiaResourceFaucet: Unable to mint resource");

        uint24 xp;
        uint cooldown;

        // Use tool
        if (_requiresTool(resource))
        {
            require(tool > 0, "CryptopiaResourceFaucet: Unable to mint resource without a tool");

            (address owner, InventoryEnums.Inventories inventory) = ICryptopiaInventories(inventoriesContract)
                .getNonFungibleTokenData(toolTokenContract, tool);

            require(owner == player, "CryptopiaResourceFaucet: Tool not owned by player");
            require(inventory == InventoryEnums.Inventories.Backpack, "CryptopiaResourceFaucet: Tool not in backpack");

            // Apply tool effects
            (uint24 multiplier_cooldown, uint24 multiplier_xp, uint24 multiplier_effectiveness) = ICryptopiaToolToken(toolTokenContract)
                .useToMintResource(player, tool, resource, limit < amount ? limit : amount);

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
        require(playerCooldown[player][resource] <= block.timestamp, "CryptopiaResourceFaucet: In cooldown period");
        playerCooldown[player][resource] = block.timestamp + cooldown;

        address asset = ICryptopiaAssetRegister(assetRegisterContract)
            .getAssetByResrouce(resource);

        // Mint tokens to inventory
        ICryptopiaAssetToken(asset)
            .mintTo(inventoriesContract, (limit < amount ? limit : amount));

        // Assign tokens to player
        ICryptopiaInventories(inventoriesContract)
            .assignFungibleToken(player, InventoryEnums.Inventories.Backpack, asset, (limit < amount ? limit : amount));

        // Award XP
        ICryptopiaPlayerRegister(playerRegisterContract)
            .award(player, xp, 0);
    }


    /**
     * Internal functions
     */
    /// @dev Returns true if the minting of `resource` requires the use of a tool
    /// @param resource {AssetEnums.Resource} the resource to mint
    /// @return bool True if `resource` requires a tool to mint
    function _requiresTool(AssetEnums.Resource resource)
        internal pure 
        returns (bool)
    {
        return resource != AssetEnums.Resource.Fruit;
    }
}