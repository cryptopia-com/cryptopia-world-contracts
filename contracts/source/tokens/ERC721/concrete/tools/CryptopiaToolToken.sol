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

    /// @dev Tool minting data
    struct ToolMintingDataEntry
    {
        uint index;
        uint amount;
    }

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

    /// @dev tool => Resource => data
    mapping (bytes32 => mapping (Resource => ToolMintingDataEntry)) public minting;
    mapping (bytes32 => Resource[]) public mintingIndex;

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
    /// @param toolData Tool data
    /// @param toolMintingData Tool minting data
    function setTools(
        Tool[] memory toolData,
        ToolMintingData[][] memory toolMintingData) 
        public virtual  
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < toolData.length; i++)
        {
            _setTool(toolData[0], toolMintingData[0]);
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
    /// @return toolData Tool data
    /// @return mintingData Tool minting data 
    function getTool(bytes32 name) 
        public virtual override view 
        returns (
            Tool memory toolData,
            ToolMintingData[] memory mintingData
        )
    {
        toolData = tools[name];
        mintingData = new ToolMintingData[](mintingIndex[name].length);
        for (uint i = 0; i < mintingIndex[name].length; i++)
        {
            mintingData[i] = ToolMintingData({
                resource: mintingIndex[name][i],
                amount: minting[name][mintingIndex[name][i]].amount
            });
        }
    }


    /// @dev Retreive a rance of tools
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return toolDatas Range of tools
    /// @return mintingDatas Range of tool minting data 
    function getTools(uint skip, uint take) 
        public override view 
        returns (
            Tool[] memory toolDatas,
            ToolMintingData[][] memory mintingDatas
        )
    {
        uint length = take;
        if (length > toolsIndex.length - skip) 
        {
            length = toolsIndex.length - skip;
        }

        toolDatas = new Tool[](length);
        mintingDatas = new ToolMintingData[][](length);
        for (uint i = 0; i < length; i++)
        {
            toolDatas[i] = tools[toolsIndex[skip + i]];
            mintingDatas[i] = new ToolMintingData[](mintingIndex[toolDatas[i].name].length);
            for (uint j = 0; j < mintingIndex[toolDatas[i].name].length; j++)
            {
                mintingDatas[i][j] = ToolMintingData({
                    resource: mintingIndex[toolDatas[i].name][j],
                    amount: minting[toolDatas[i].name][mintingIndex[toolDatas[i].name][j]].amount
                });
            }
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
        bytes32 tool = toolInstances[toolId].name; 

        // Check if tool can be used for minting resource
        if (minting[tool][resource].amount == 0)
        {
            revert ToolInvalidForMinting(toolId, resource);
        }

        // Check if amount is within minting limits
        if (amount > minting[tool][resource].amount)
        {
            revert ToolMintLimitExceeded(toolId, resource, amount, minting[tool][resource].amount);
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
        return tools[tool].multiplier_effectiveness != 0;
    }


    /// @dev True if a minting data entry for `resource` and `tool` exists
    /// @param tool The tool to check
    /// @param resource The resource to check
    /// @return True if a minting data entry for `resource` and `tool` exists
    function _exists(bytes32 tool, Resource resource) 
        internal view 
        returns (bool) 
    {
        return mintingIndex[tool].length > 0 && mintingIndex[tool][minting[tool][resource].index] == resource;
    }


    /// @dev Add or update tool
    /// @param tool Tool data
    /// @param mintingData Tool minting data
    function _setTool(
        Tool memory tool, 
        ToolMintingData[] memory mintingData
    ) 
        internal 
    {
        // Add tool
        if (!_exists(tool.name))
        {
            toolsIndex.push(tool.name);
        }

        // Set tool
        tools[tool.name] = tool;

        // Set minting data
        for (uint i = 0; i < mintingData.length; i++)
        {
            if (mintingData[i].amount > 0)
            {
                // Add
                if (!_exists(tool.name, mintingData[i].resource))
                {
                    mintingIndex[tool.name].push(mintingData[i].resource);

                    minting[tool.name][mintingData[i].resource] = ToolMintingDataEntry({
                        index: mintingIndex[tool.name].length - 1,
                        amount: mintingData[i].amount
                    });
                }

                // Update
                else 
                {
                    
                    minting[tool.name][mintingData[i].resource].amount = mintingData[i].amount;
                }
            }

            // Remove
            else if (_exists(tool.name, mintingData[i].resource))
            {
                // Remove from index
                uint index = minting[tool.name][mintingData[i].resource].index;
                mintingIndex[tool.name][index] = mintingIndex[tool.name][mintingIndex[tool.name].length - 1];
                mintingIndex[tool.name].pop();

                // Remove from mapping
                delete minting[tool.name][mintingData[i].resource];
            }
        }
    }
}