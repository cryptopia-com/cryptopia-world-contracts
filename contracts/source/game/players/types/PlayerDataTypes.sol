// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../types/GameEnums.sol";
import "../../types/FactionEnums.sol";

/// @dev Player Data
struct PlayerData
{
    Faction faction; // Faction to which the player belongs
    SubFaction subFaction; // Sub Faction none/pirate/bounty hunter 
    uint8 level; // Current level (zero signals not initialized)
    int16 karma; // Current karma (KARMA_MIN signals piracy)
    uint24 xp; // Experience points towards next level; XP_BASE + (uint(level - 1) * XP_FACTOR)**XP_EXPONENT
    uint24 luck; // STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
    uint24 charisma; // STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 intelligence;  // STATS_INTELLIGENCE_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 strength; // STATS_STRENGTH_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint24 speed; // STATS_SPEED_BASE + (0 - MAX_LEVEL player choice when leveling up)
    uint ship; // Equipped ship
}