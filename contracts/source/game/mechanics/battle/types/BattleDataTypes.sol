// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @dev Naval battle data; used to prevent stack too deep errors
struct BattleData 
{    
    // Effective attack power against the opponent for player1
    uint player1_effectiveAttack;

    // Effective attack power against the opponent for player2
    uint player2_effectiveAttack;

    // The amount of turns that would be needed for player1 to win the battle
    uint player1_turnsUntilWin;

    // The amount of turns that would be needed for player2 to win the battle
    uint player2_turnsUntilWin;

    // The amount of damage that the player1 has taken
    uint16 player1_damageTaken;

    // The amount of damage that the player2 has taken
    uint16 player2_damageTaken;

    /// The player that won the battle
    address victor;
}