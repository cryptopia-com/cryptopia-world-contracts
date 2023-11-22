// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../../../game/types/GameEnums.sol";
import "../../../../game/players/errors/PlayerErrors.sol";
import "../../../../game/players/IPlayerRegister.sol";
import "../../../../game/inventories/IInventories.sol";
import "../../../../game/crafting/ICraftable.sol";
import "../../../../game/assets/types/AssetEnums.sol";
import "../../tools/ITools.sol";
import "../CryptopiaERC721.sol";

/// @title Cryptopia Tool Token
/// @dev Non-fungible token (ERC721)
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaToolToken is CryptopiaERC721, ITools, ICraftable {

    /**
     * Storage
     */
    uint24 constant private MAX_DAMAGE = 100;
    uint24 constant private MAX_DURABILITY = 100;

    // Auto token id 
    uint private _currentTokenId; 

    /// @dev name => Tool
    mapping (bytes32 => Tool) public tools;
    bytes32[] private toolsIndex;

    /// @dev tokenId => ToolInstance
    mapping (uint => ToolInstance) public toolInstances;

    /// @dev tool => Resource => max amount
    mapping (bytes32 => mapping (ResourceType => uint)) public minting;

    // Refs
    address public playerRegisterContract;
    address public inventoriesContract;


    /**
     * Events
     */
    /// @dev Emitted when 'tool' takes damage
    /// @param tool The tool ID of the tool that takes damage
    /// @param damage The amount of damage that the tool took
    event ToolDamage(uint indexed tool, uint24 damage);


    /**
     * Errors
     */
    /// @dev Emitted when a tool with the specified identifier does not exist in the system
    /// @param tool The identifier of the tool that wasn't found
    error ToolNotFound(bytes32 tool);

    /// @dev Emitted when the specified tool is not valid for minting the provided resource
    /// @param toolId The unique ID of the tool in question
    /// @param resource The resource attempted to be minted with the tool
    error ToolInvalidForMinting(uint toolId, ResourceType resource);

    /// @dev Emitted when an attempt is made to mint an amount that surpasses the tool's limit
    /// @param toolId The unique ID of the tool in question
    /// @param resource The resource attempted to be minted with the tool
    /// @param attemptedAmount The amount the user tried to mint
    /// @param allowedAmount The maximum amount the tool allows to be minted
    error ToolMintLimitExceeded(uint toolId, ResourceType resource, uint attemptedAmount, uint allowedAmount);


    /**
     * Modifiers
     */
    /// @dev Requires that an item with `name` exists
    /// @param name Unique token name
    modifier onlyExisting(bytes32 name)
    {  
        if (!_exists(name))
        {
            revert ToolNotFound(name);
        }
        _;
    }


    /// @dev Contract initializer sets shared base uri
    /// @param authenticator Whitelist
    /// @param initialContractURI Location to contract info
    /// @param initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    /// @param _playerRegisterContract Contract responsible for players
    /// @param _inventoriesContract Contract responsible for inventories
    function initialize(
        address authenticator, 
        string memory initialContractURI, 
        string memory initialBaseTokenURI,
        address _playerRegisterContract,
        address _inventoriesContract) 
        public initializer 
    {
        __CryptopiaERC721_init(
            "Cryptopia Tools", "TOOL", authenticator, initialContractURI, initialBaseTokenURI);

        playerRegisterContract = _playerRegisterContract;
        inventoriesContract = _inventoriesContract;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Create basic tools
        uint24[7] memory stats = [uint24(100), uint24(100), uint24(100), uint24(100), uint24(0), uint24(0), uint24(0)];
        _setTool("Axe", Rarity.Common, 1, stats);
        _setTool("Pickaxe", Rarity.Common, 1, stats);
        _setTool("Fishing rod", Rarity.Common, 1, stats);
        _setTool("Shovel", Rarity.Common, 1, stats);

        minting["Axe"][ResourceType.Wood] = 1_000_000_000_000_000_000;
        minting["Axe"][ResourceType.Meat] = 1_000_000_000_000_000_000;
        minting["Pickaxe"][ResourceType.Stone] = 1_000_000_000_000_000_000;
        minting["Pickaxe"][ResourceType.Meat] = 1_000_000_000_000_000_000;
        minting["Fishing rod"][ResourceType.Fish] = 1_000_000_000_000_000_000;
        minting["Shovel"][ResourceType.Sand] = 1_000_000_000_000_000_000;
    }


    /**
     * Admin functions
     */
    /// @dev Add or update tools
    /// @param name Tool name (unique)
    /// @param rarity Tool rarity {Rarity}
    /// @param level Tool level (determins where the tool can be used and by who)
    /// @param stats durability, multiplier_cooldown, multiplier_xp, multiplier_effectiveness
    /// @param minting_resources The resources {ResourceType} that can be minted with the tool
    /// @param minting_amounts The max amounts of resources that can be minted with the tool
    function setTools(
        bytes32[] memory name, 
        Rarity[] memory rarity, 
        uint8[] memory level,
        uint24[7][] memory stats,
        ResourceType[][] memory minting_resources,
        uint[][] memory minting_amounts) 
        public virtual  
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < name.length; i++)
        {
            _setTool(
                name[i], 
                rarity[i],
                level[i],
                stats[i]);

            // Set minting
            for (uint j = 0; j < minting_resources[i].length; j++)
            {
                minting[name[i]][minting_resources[i][j]] = minting_amounts[i][j];
            }
        }
    }


    /**
     * Public functions
     */
    /// @dev Returns the amount of different tools
    /// @return count The amount of different tools
    function getToolCount() 
        public virtual override view 
        returns (uint)
    {
        return toolsIndex.length;
    }


    /// @dev Retreive a tools by name
    /// @param name Tool name (unique)
    /// @return data Tool data
    function getTool(bytes32 name) 
        public virtual override view 
        returns (Tool memory data)
    {
        data = tools[name];
    }


    /// @dev Retreive a rance of tools
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return names Tool names (unique)
    /// @return data range of tool templates
    function getTools(uint skip, uint take) 
        public override view 
        returns (
            bytes32[] memory names, 
            Tool[] memory data
        )
    {
        uint length = take;
        if (length > toolsIndex.length - skip) {
            length = toolsIndex.length - skip;
        }

        names = new bytes32[](length);
        data = new Tool[](length);
        for (uint i = 0; i < length; i++)
        {
            names[i] = toolsIndex[skip + i];
            data[i] = tools[names[i]];
        }

    }


    /// @dev Retreive a tools by token id
    /// @param tokenId The id of the tool to retreive
    /// @return instance a single tool instance
    function getToolInstance(uint tokenId) 
        public virtual override view 
        returns (ToolInstance memory instance)
    {
        instance = toolInstances[tokenId];
    }


    /// @dev Retreive a tools by token id
    /// @param tokenIds The ids of the tools to retreive
    /// @return instances a range of tool instances
    function getToolInstances(uint[] memory tokenIds) 
        public virtual override view 
        returns (ToolInstance[] memory instances)
    {
        instances = new ToolInstance[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++)
        {
            instances[i] = toolInstances[tokenIds[i]];
        }
    }


    /**
     * System functions
     */
    /// @dev Applies tool effects to the `cooldown` period and the `amount` of `resource` that's being minted by `player`
    /// @param player The account that's using the tool for minting
    /// @param toolId The token ID of the tool being used to mint 
    /// @param resource The resource {ResourceType} that's being minted
    /// @param amount The amount of tokens to be minted
    function __useForMinting(address player, uint toolId, ResourceType resource, uint amount) 
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        returns (
            uint24 multiplier_cooldown,
            uint24 multiplier_xp,
            uint24 multiplier_effectiveness
        )
    {
        bytes32 tool = toolInstances[toolId].name;

        // Check if tool can be used for minting resource
        if (minting[tool][resource] == 0)
        {
            revert ToolInvalidForMinting(toolId, resource);
        }

        // Check if amount is within minting limits
        if (amount > minting[tool][resource])
        {
            revert ToolMintLimitExceeded(toolId, resource, amount, minting[tool][resource]);
        }
        
        // Check if player has the required level
        uint8 playerLevel = IPlayerRegister(playerRegisterContract).getLevel(player);
        if (playerLevel < tools[tool].level)
        {
            revert PlayerLevelInsufficient(player, playerLevel, tools[tool].level);
        }

        // Apply effects
        multiplier_cooldown = tools[tool].multiplier_cooldown;
        multiplier_xp = MAX_DAMAGE == toolInstances[toolId].damage 
            ? 0 : tools[tool].multiplier_xp * (MAX_DAMAGE - toolInstances[toolId].damage) / MAX_DAMAGE;
        multiplier_effectiveness = MAX_DAMAGE == toolInstances[toolId].damage 
            ? 0 : tools[tool].multiplier_effectiveness * (MAX_DAMAGE - toolInstances[toolId].damage) / MAX_DAMAGE;

        // Apply damage
        uint24 damage = MAX_DURABILITY - tools[tool].durability;
        if (damage > 0)
        {
            if (toolInstances[toolId].damage + damage < MAX_DAMAGE)
            {
                // Emit
                emit ToolDamage(toolId, damage);

                // Apply damage
                toolInstances[toolId].damage += damage;   
            }
            else 
            {
                // Emit
                emit ToolDamage(toolId, MAX_DAMAGE - toolInstances[toolId].damage);

                // Apply damage
                toolInstances[toolId].damage = MAX_DAMAGE;
            }
        }
    }


    /// @dev Allows for the crafting of a tool
    /// @param tool The name of the tool to be crafted
    /// @param player The player to craft the tool for
    /// @param inventory The inventory to mint the item into
    /// @return uint The token ID of the crafted item
    function __craft(bytes32 tool, address player, Inventory inventory) 
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        onlyExisting(tool) 
        returns (uint)
    {
        // Mint
        uint tokenId = _getNextTokenId();
        _mint(inventoriesContract, tokenId);
        _incrementTokenId();
        toolInstances[tokenId].name = tool;

        // Assign
        IInventories(inventoriesContract)
            .__assignNonFungibleToken(player, inventory, address(this), tokenId);

        return tokenId;
    }


    /**
     * Private functions
     */
    /// @dev calculates the next token ID based on value of _currentTokenId
    /// @return uint for the next token ID
    function _getNextTokenId() private view returns (uint) {
        return _currentTokenId + 1;
    }


    /// @dev increments the value of _currentTokenId
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    
    /// @dev True if a tool with `name` exists
    /// @param name of the tool
    function _exists(bytes32 name) internal view returns (bool) 
    {
        return tools[name].multiplier_effectiveness != 0;
    }


    /// @dev Add or update tools
    /// @param name Tool name (unique)
    /// @param rarity Tool rarity {Rarity}
    /// @param level Tool level (determins where the tool can be used and by who)
    /// @param stats durability, multiplier_cooldown, multiplier_xp, multiplier_effectiveness, value1, value2, value3
    function _setTool(bytes32 name, Rarity rarity, uint8 level, uint24[7] memory stats) 
        internal 
    {
        // Add tool
        if (!_exists(name))
        {
            toolsIndex.push(name);
        }

        // Set tool
        Tool storage tool = tools[name];
        tool.rarity = rarity;
        tool.level = level;
        tool.durability = stats[0];
        tool.multiplier_cooldown = stats[1];
        tool.multiplier_xp = stats[2];
        tool.multiplier_effectiveness = stats[3];
        tool.value1 = stats[4];
        tool.value2 = stats[5];
        tool.value3 = stats[6];
    }
}