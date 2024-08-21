// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "./types/GameConsoleDataTypes.sol";

/// @title Console game logic interface
/// @dev Contains the logic to interact with console games
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IGameConsoleTitle {

    /// @dev Get the name of the game
    /// @return name The name of the game
    function getName() 
        external view 
        returns (bytes32 name);

    /// @dev Determine if the session is valid and calculate the reward
    /// @param session The session
    /// @param sessionData Additional data used to verify the session
    /// @param sessionCount The number of times the game has been run by the player
    /// @param isPersonalHighscore True if the session is the personal highscore
    /// @param isGlobalHighscore True if the session is the global highscore
    /// @return isValid True if the score is valid
    /// @return reward The reward for the session
    function run(GameConsoleSession memory session, bytes32 sessionData, uint sessionCount, bool isPersonalHighscore, bool isGlobalHighscore) 
        external view 
        returns (bool isValid, GameConsoleReward memory reward);
}