// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../inventories/types/InventoryDataTypes.sol";

/// @dev Data structure for a score submission
struct GameConsoleSession 
{
    /// @dev The player that submitted the score
    address player;

    /// @dev The timestamp of the submission
    uint64 timestamp;

    /// @dev The score
    uint32 score;
}

/// @dev Data structure for a console game
struct GameConsoleTitle
{
    /// @dev The title of the game
    bytes32 name;

     /// @dev Location of the logic contract
    address logic;
    
    /// @dev The highscore
    GameConsoleSession highscore;

    /// @dev The leaderboard
    GameConsoleSession[] leaderboard;
}

/// @dev Data structure for a console game submission
struct GameConsoleReward 
{
    /// @dev Experience points awarded for submitting a score
    uint24 xp;
    
    /// @dev Array of fungible rewards (like ERC20 tokens) awarded
    FungibleTransactionData[] fungible;

    /// @dev Array of non-fungible rewards (like ERC721 tokens) awarded
    NonFungibleTransactionData[] nonFungible;
}