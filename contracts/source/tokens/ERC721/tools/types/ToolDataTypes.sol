// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../../../game/types/GameEnums.sol";
import "../../../../game/assets/types/AssetEnums.sol";

/// @dev Tool template
struct Tool
{
    bytes32 name;
    Rarity rarity;
    uint8 level;
    uint24 durability;
    uint24 multiplier_cooldown;
    uint24 multiplier_xp;
    uint24 multiplier_effectiveness;
    uint24 value1;
    uint24 value2;
    uint24 value3;

    // Minting data
    ToolMinting[] minting;
}

/// @dev Tool minting 
struct ToolMinting
{
    Resource resource;
    uint amount;
}

/// @dev Tool instance
struct ToolInstance
{
    bytes32 name;
    uint24 damage;
}
