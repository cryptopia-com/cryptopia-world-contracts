// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../../game/types/GameEnums.sol";
import "../../../game/assets/types/AssetEnums.sol";
import "./types/ToolDataTypes.sol";

/// @title Tools 
/// @dev Non-fungible token (ERC721) 
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
    /// @param name Tool name (unique)
    /// @return data Tool data
    function getTool(bytes32 name) 
        external view 
        returns (Tool memory data);


    /// @dev Retreive a rance of tools
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return names Tool names (unique)
    /// @return data range of tool templates
    function getTools(uint skip, uint take) 
        external view 
        returns (
            bytes32[] memory names, 
            Tool[] memory data
        );


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
    /// @dev Applies tool effects to the `cooldown` period and the `amount` of `resource` that's being minted by `player`
    /// @param player The account that's using the tool for minting
    /// @param toolId The token ID of the tool being used to mint 
    /// @param resource The resource {ResourceType} that's being minted
    /// @param amount The amount of tokens to be minted; checked against value1
    function __useForMinting(address player, uint toolId, ResourceType resource, uint amount) 
        external  
        returns (
            uint24 multiplier_cooldown,
            uint24 multiplier_xp,
            uint24 multiplier_effectiveness
        );
}