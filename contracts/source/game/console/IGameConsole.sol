// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../inventories/types/InventoryEnums.sol";
import "./types/GameConsoleDataTypes.sol";

/// @title GameConsole 
/// @dev The game console contains a collection of game titles and records highscores, sessions and leaderboards. The game console 
///      runs on-chain sessions that are submitted by players. The game console is not tamper-proof and should be used for casual 
///      games only. There are no guarantees that the highscores are accurate or that they have not been tampered with. This system
///      is not suitable for high-stakes games or games that require high security. 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IGameConsole {

    /// @dev Get the amount of titles
    /// @return count The amount of titles
    function getTitleCount() 
        external view 
        returns (uint count);


    /// @dev Get a console title
    /// @param name The name of the title
    /// @return title_ The title
    function getTitle(bytes32 name) 
        external view 
        returns (GameConsoleTitle memory title_);
        

    /// @dev Get all console titles
    /// @param skip The amount of titles to skip
    /// @param take The amount of titles to take
    /// @return titles_ Titles and global leaderboard
    function getTitles(uint skip, uint take) 
        external view 
        returns (GameConsoleTitle[] memory titles_);


    /// @dev Get all console titles and personal highscores for a specific player
    /// @param player The player to get the highscores for
    /// @param skip The amount of titles to skip
    /// @param take The amount of titles to take
    /// @return titles_ Titles and global leaderboards
    /// @return highscores Personal highscores
    function getTitlesAndHighscores(address player, uint skip, uint take) 
        external view 
        returns (GameConsoleTitle[] memory titles_, GameConsoleSession[] memory highscores);


    /// @dev Submit a new game session
    /// @param title The title of the game
    /// @param score The session score 
    /// @param data Additional data used to verify the score (no guerantees are made about the data's integrity)
    /// @param inventory The inventory to store the rewards in
    function submit(bytes32 title, uint32 score, bytes32 data, Inventory inventory) 
        external;
}