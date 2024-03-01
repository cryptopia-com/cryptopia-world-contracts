// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../game/types/GameEnums.sol";
import "../../../../game/assets/types/AssetEnums.sol";

/// @dev Tool 
struct Tool
{
    /// @dev Name of the tool (unique)
    bytes32 name;

    /// @dev Rarity level of the tool
    Rarity rarity;

    /// @dev Minimum player level required to use the tool
    uint8 level;

    /// @dev Durability of the tool
    /// @notice Represents the rate at which the tool takes damage
    uint24 durability;

    /// @dev Multiplier for experience points gained while using the tool
    uint24 multiplier_xp;

    /// @dev Multiplier impacting the effectiveness of the tool in various game scenarios
    uint24 multiplier_effectiveness;

    // Generic values
    uint24 value1;
    uint24 value2;
    uint24 value3;

    /// @dev Tool minting data
    ToolMinting[] minting;
}

/// @dev Tool minting data
struct ToolMinting
{
    /// @dev Type of resource that the tool is capable of minting
    /// @notice Each tool can be effective for minting specific resources in the game
    Resource resource;

    /// @dev Maximum amount of the resource that can be minted using the tool
    /// @notice Sets a limit to how much of a resource can be extracted or produced by the tool
    uint amount;
}

/// @dev Represents an instance of a tool, linked to a specific ERC721 token
struct ToolInstance
{
    /// @dev The ERC721 token id of the tool
    uint tokenId;

    /// @dev Name of the tool, linking it to its template in the tools mapping
    bytes32 name;

    /// @dev Rarity level of the tool
    Rarity rarity;

    /// @dev Minimum player level required to use the tool
    uint8 level;

    /// @dev Durability of the tool
    /// @notice Represents the rate at which the tool takes damage
    uint24 durability;

    /// @dev Multiplier for experience points gained while using the tool
    uint24 multiplier_xp;

    /// @dev Multiplier impacting the effectiveness of the tool in various game scenarios
    uint24 multiplier_effectiveness;

    /// @dev The current amount of damage of the tool
    /// @notice Damage affects the tool's effectiveness and is a result of regular use
    /// @notice Represented as a percentage (0-100), with 100 indicating maximum damage
    uint24 damage;

    // Generic values
    uint24 value1;
    uint24 value2;
    uint24 value3;

    /// @dev Tool minting data
    ToolMinting[] minting;
}