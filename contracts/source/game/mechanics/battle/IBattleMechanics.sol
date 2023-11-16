// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "./types/BattleDataTypes.sol";

/// @title Cryptopia battle game mechanics
/// @dev Provides the mechanics for the battle gameplay
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