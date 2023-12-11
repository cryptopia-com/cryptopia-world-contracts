// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "./types/BattleDataTypes.sol";

/// @title Cryptopia Naval Battle Mechanics
/// @notice This contract is at the heart of naval combat within Cryptopia, 
/// orchestrating the complexities of ship-to-ship battles. It manages the intricate details of naval 
/// engagements, including attack effectiveness, defense mechanisms, and the influence of luck and 
/// environmental factors like tile safety. The contract ensures a dynamic and strategic battle environment, 
/// where each player's decisions, ship attributes, and tile locations significantly impact the battle outcomes.
/// It integrates closely with ship and player data contracts to fetch relevant information for calculating battle dynamics. 
/// This contract provides a framework for players to engage in exciting naval battles, enhancing their gaming experience 
/// with unpredictable and thrilling combat scenarios.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IBattleMechanics {

    /**
     * System functions
     */
    /// @dev Quick battle between two players
    /// @notice Player 1 is expected to be the initiator of the battle (msg.sender)
    /// @param player1 The account of the first player
    /// @param player2 The account of the second player
    /// @param location The location at which the battle takes place
    /// @return battleData The outcome of the battle
    function __quickBattle(address player1, address player2, uint16 location) 
        external returns (BattleData memory battleData);
}