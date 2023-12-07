// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../../../game/types/GameEnums.sol";
import "../../../../game/players/errors/PlayerErrors.sol";
import "../../../../game/players/IPlayerRegister.sol";
import "../../../../game/inventories/IInventories.sol";
import "../../../../game/crafting/ICraftable.sol";
import "../../../../game/assets/types/AssetEnums.sol";
import "../../../../game/quests/rewards/INonFungibleQuestReward.sol";
import "../../tools/ITools.sol";
import "../CryptopiaERC721.sol";

/// @title Cryptopia Tool Token
/// @dev Non-fungible token (ERC721)
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaToolToken is CryptopiaERC721, ITools, ICraftable, INonFungibleQuestReward {

    /// @dev Tool data
    struct ToolData 
    {
        uint index;
        Rarity rarity;
        uint8 level;
        uint24 durability;
        uint24 multiplier_cooldown;
        uint24 multiplier_xp;
        uint24 multiplier_effectiveness;
        uint24 value1;
        uint24 value2;
        uint24 value3;

        /// @dev Resource => minting data
        mapping (Resource => uint) minting;
        Resource[] mintingIndex;
    }

    /**
     * Storage
     */
    uint24 constant private MAX_DAMAGE = 100;
    uint24 constant private MAX_DURABILITY = 100;

    // Auto token id 
    uint private _currentTokenId; 

    /// @dev name => ToolData
    mapping (bytes32 => ToolData) public tools;
    bytes32[] private toolsIndex;

    /// @dev tokenId => ToolInstance
    mapping (uint => ToolInstance) public toolInstances;

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
    error ToolInvalidForMinting(uint toolId, Resource resource);

    /// @dev Emitted when an attempt is made to mint an amount that surpasses the tool's limit
    /// @param toolId The unique ID of the tool in question
    /// @param resource The resource attempted to be minted with the tool
    /// @param attemptedAmount The amount the user tried to mint
    /// @param allowedAmount The maximum amount the tool allows to be minted
    error ToolMintLimitExceeded(uint toolId, Resource resource, uint attemptedAmount, uint allowedAmount);


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
    }


    /**
     * Admin functions
     */
    /// @dev Add or update tools
    /// @param tools_ Tool datas to add or update
    function setTools(
        Tool[] memory tools_) 
        public virtual  
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < tools_.length; i++)
        {
            _setTool(tools_[i]);
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
    /// @return tool The tool data
    function getTool(bytes32 name) 
        public virtual override view 
        returns (Tool memory tool)
    {
        return _getTool(name);
    }


    /// @dev Retreive a rance of tools
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return tools_ The tool datas  
    function getTools(uint skip, uint take)  
        public virtual override view 
        returns (Tool[] memory tools_)
    {
        uint length = take;
        if (toolsIndex.length < skip + take) 
        {
            length = toolsIndex.length - skip;
        }

        tools_ = new Tool[](length);
        for (uint i = 0; i < length; i++)
        {
            tools_[i] = _getTool(toolsIndex[skip + i]);
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
    /// @param resource The resource {Resource} that's being minted
    /// @param amount The amount of tokens to be minted
    function __useForMinting(address player, uint toolId, Resource resource, uint amount) 
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        returns (
            uint24 multiplier_cooldown,
            uint24 multiplier_xp,
            uint24 multiplier_effectiveness
        )
    {
        bytes32 toolName = toolInstances[toolId].name; 

        // Check if tool can be used for minting resource
        if (tools[toolName].minting[resource] == 0) 
        {
            revert ToolInvalidForMinting(toolId, resource);
        }

        // Check if amount is within minting limits
        if (amount > tools[toolName].minting[resource]) 
        {
            revert ToolMintLimitExceeded(toolId, resource, amount, tools[toolName].minting[resource]); 
        }
        
        // Check if player has the required level
        uint8 playerLevel = IPlayerRegister(playerRegisterContract).getLevel(player);
        if (playerLevel < tools[toolName].level)
        {
            revert PlayerLevelInsufficient(player, playerLevel, tools[toolName].level);
        }

        // Apply effects
        multiplier_cooldown = tools[toolName].multiplier_cooldown;
        multiplier_xp = MAX_DAMAGE == toolInstances[toolId].damage 
            ? 0 : tools[toolName].multiplier_xp * (MAX_DAMAGE - toolInstances[toolId].damage) / MAX_DAMAGE;
        multiplier_effectiveness = MAX_DAMAGE == toolInstances[toolId].damage 
            ? 0 : tools[toolName].multiplier_effectiveness * (MAX_DAMAGE - toolInstances[toolId].damage) / MAX_DAMAGE;

        // Apply damage
        uint24 damage = MAX_DURABILITY - tools[toolName].durability;
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


    /// @dev Mint a quest reward
    /// @param tool The item to mint
    /// @param player The player to mint the item to
    /// @param inventory The inventory to mint the item to
    function __mintQuestReward(bytes32 tool, address player, Inventory inventory)
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        onlyExisting(tool) 
        returns (uint tokenId)
    {
        // Mint
        tokenId = _getNextTokenId();
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
    function _getNextTokenId() 
        internal view 
        returns (uint) 
    {
        return _currentTokenId + 1;
    }


    /// @dev increments the value of _currentTokenId
    function _incrementTokenId() 
        internal 
    {
        _currentTokenId++;
    }

    
    /// @dev True if a tool with `name` exists
    /// @param tool The tool to check
    /// @return True if a tool with `name` exists
    function _exists(bytes32 tool) 
        internal view 
        returns (bool) 
    {
        return tools[tool].multiplier_effectiveness > 0;
    }


    /// @dev True if a minting data entry for `resource` and `tool` exists
    /// @param tool The tool to check
    /// @param resource The resource to check
    /// @return True if a minting data entry for `resource` and `tool` exists
    function _exists(bytes32 tool, Resource resource) 
        internal view 
        returns (bool) 
    {
        return tools[tool].minting[resource] > 0;
    }


    /// @dev Retreive a tools by name
    /// @param name Tool name (unique)
    /// @return tool The tool data
    function _getTool(bytes32 name) 
        internal view  
        returns (Tool memory tool)
    {
        ToolData storage data = tools[name];
        tool = Tool({
            name: name,
            rarity: data.rarity,
            level: data.level,
            durability: data.durability,
            multiplier_cooldown: data.multiplier_cooldown,
            multiplier_xp: data.multiplier_xp,
            multiplier_effectiveness: data.multiplier_effectiveness,
            value1: data.value1,
            value2: data.value2,
            value3: data.value3,
            minting: new ToolMinting[](data.mintingIndex.length)
        });

        for (uint i = 0; i < data.mintingIndex.length; i++)
        {
            tool.minting[i] = ToolMinting({
                resource: data.mintingIndex[i],
                amount: data.minting[data.mintingIndex[i]] 
            });
        }
    }


    /// @dev Add or update tool
    /// @param tool_ Tool data
    function _setTool(Tool memory tool_) 
        internal 
    {
        // Add tool
        if (!_exists(tool_.name))
        {
            tools[tool_.name].index = toolsIndex.length;
            toolsIndex.push(tool_.name);
        }

        // Set tool
        ToolData storage tool = tools[tool_.name];
        tool.rarity = tool_.rarity;
        tool.level = tool_.level;
        tool.durability = tool_.durability;
        tool.multiplier_cooldown = tool_.multiplier_cooldown;
        tool.multiplier_xp = tool_.multiplier_xp;
        tool.multiplier_effectiveness = tool_.multiplier_effectiveness;
        tool.value1 = tool_.value1;
        tool.value2 = tool_.value2;
        tool.value3 = tool_.value3;

        // Reset minting data
        if (tool.mintingIndex.length > 0)
        {
            for (uint i = 0; i < tool.mintingIndex.length; i++)
            {
                delete tool.minting[tool.mintingIndex[i]];
            }

            delete tool.mintingIndex;
        }

        // Add minting data
        for (uint i = 0; i < tool_.minting.length; i++)
        {
            tool.mintingIndex.push(tool_.minting[i].resource);
            tool.minting[tool_.minting[i].resource] = tool_.minting[i].amount; 
        }
    }
}