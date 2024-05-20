// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../types/GameEnums.sol";
import "../../types/FactionEnums.sol";

/// @dev Player
struct Player
{
    /// @dev Player username
    bytes32 username;

    /// @dev Faction to which the player belongs
    Faction faction; 

    /// @dev Sub Faction none/pirate/bounty hunter
    SubFaction subFaction; 

    /// @dev Current level (zero signals not initialized)
    uint8 level; 

    /// @dev Current karma (KARMA_MIN signals piracy)
    int16 karma; 

    /// @dev Experience points towards next level; XP_BASE + (uint(level - 1) * XP_FACTOR)**XP_EXPONENT
    uint24 xp; 

    /// @dev STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
    uint24 luck; 

    /// @dev STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 charisma; 

    /// @dev STATS_INTELLIGENCE_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 intelligence; 

    /// @dev STATS_STRENGTH_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 strength; 

    /// @dev STATS_SPEED_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 speed; 

    /// @dev Equipped ship
    uint ship; 
}

/// @dev Player data
struct PlayerData
{
    /// @dev Faction to which the player belongs
    Faction faction; 

    /// @dev Sub Faction none/pirate/bounty hunter
    SubFaction subFaction; 

    /// @dev Current level (zero signals not initialized)
    uint8 level; 

    /// @dev Current karma (KARMA_MIN signals piracy)
    int16 karma; 

    /// @dev Experience points towards next level; XP_BASE + (uint(level - 1) * XP_FACTOR)**XP_EXPONENT
    uint24 xp; 

    /// @dev STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
    uint24 luck; 

    /// @dev STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 charisma; 

    /// @dev STATS_INTELLIGENCE_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 intelligence; 

    /// @dev STATS_STRENGTH_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 strength; 

    /// @dev STATS_SPEED_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 speed; 

    /// @dev Equipped ship
    uint ship; 
}

struct PlayerStats 
{
    /// @dev STATS_SPEED_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 speed; 

    /// @dev STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 charisma; 

    /// @dev STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
    uint24 luck; 

    /// @dev STATS_INTELLIGENCE_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 intelligence; 

    /// @dev STATS_STRENGTH_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 strength; 
}