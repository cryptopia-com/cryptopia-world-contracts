// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../game/types/GameEnums.sol";
import "../../../game/assets/types/AssetEnums.sol";
import "./types/ToolDataTypes.sol";

/// @title Cryptopia Tool Token
/// @notice This contract handles the creation, management, and utilization of tools within Cryptopia.
/// It provides functionalities to craft tools, use them for minting resources, and manage their durability.
/// Tools in this contract are ERC721 tokens, allowing each tool to have unique properties and state.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ITools {

    /**
     * Public functions
     */
    /// @dev Returns the amount of different tools
    /// @return count The amount of different tools
    function getToolCount() 
        external view 
        returns (uint);


    /// @dev Retreive a tools by name
    /// @param name_ Tool name (unique)
    /// @return tool The tool data
    function getTool(bytes32 name_) 
        external view 
        returns (Tool memory tool);


    /// @dev Retreive a rance of tools
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return tools The tool datas
    function getTools(uint skip, uint take) 
        external view 
        returns (Tool[] memory tools);


    /// @dev Retreive a tools by token id
    /// @param tokenId The id of the tool to retreive
    /// @return instance a single tool instance
    function getToolInstance(uint tokenId) 
        external view 
        returns (ToolInstance memory instance);


    /// @dev Retreive a tools by token id
    /// @param tokenIds The ids of the tools to retreive
    /// @return instances a range of tool instances
    function getToolInstances(uint[] memory tokenIds) 
        external view 
        returns (ToolInstance[] memory instances);


    /**
     * System functions
     */
    /// @dev Applies tool effects to the `amount` of `resource` that's being minted by `player`
    /// @param player The account that's using the tool for minting
    /// @param toolId The token ID of the tool being used to mint 
    /// @param resource The resource {Resource} that's being minted
    /// @param amount The amount of tokens to be minted; checked against value1
    /// @return multiplier_xp The multiplier for experience points gained while using the tool
    /// @return multiplier_effectiveness The multiplier impacting the effectiveness of the tool in various game scenarios
    function __useForMinting(address player, uint toolId, Resource resource, uint amount) 
        external  
        returns (
            uint24 multiplier_xp,
            uint24 multiplier_effectiveness
        );
}