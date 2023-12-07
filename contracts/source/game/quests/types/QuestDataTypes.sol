// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../inventories/types/InventoryDataTypes.sol";
import "../../types/FactionEnums.sol";

/// @dev Quest 
/// @notice A quest has constraints that must be met before it can be started
/// @notice A quest consists of a number of steps that must be completed in order
/// @notice A quest consists of a number of rewards that the player can choose from when completed
struct Quest 
{
    /// @dev Quest name
    bytes32 name;

    /// @dev Level constraint
    bool hasLevelConstraint;
    uint8 level;

    /// @dev Faction constraint
    bool hasFactionConstraint;
    Faction faction;

    /// @dev Sub faction constraint
    bool hasSubFactionConstraint;
    SubFaction subFaction;

    /// @dev Recurrence constraint
    bool hasRecurrenceConstraint;
    uint maxRecurrences;

    /// @dev Cooldown constraint
    bool hasCooldownConstraint;
    uint cooldown;

    /// @dev Time constraint
    bool hasTimeConstraint;
    uint maxDuration;

    /// @dev Quest steps
    QuestStep[] steps;

    /// @dev Quest rewards
    /// @notice Players can only claim one reward per quest per recurrence
    QuestReward[] rewards;
}

/// @dev Quest step
/// @notice A quest step has constraints that must be met before it can be completed
/// @notice A quest step can consist of a number of items (ERC20 or ERC721) that are taken or given
struct QuestStep
{
    /// @dev Step name
    bytes32 name;

    /// @dev Tile constraint
    bool hasTileConstraint;
    uint16 tile;

    /// @dev Fungible tokens that are taken from the inventory
    FungibleTransactionData[] takeFungible;

    /// @dev Non-fungible tokens that are taken from the inventory
    NonFungibleTransactionData[] takeNonFungible;

    /// @dev Fungible tokens that are given to the inventory
    FungibleTransactionData[] giveFungible;

    /// @dev Non-fungible tokens that are given to the inventory
    NonFungibleTransactionData[] giveNonFungible;
}

/// @dev Quest reward
/// @notice A quest reward describes the xp and karma (can be negative) that are rewarded 
/// @notice A quest reward describes the amount of tokens that are rewarded
struct QuestReward
{
    /// @dev Reward name
    bytes32 name;

        /// @dev The amount of karma rewarded (negative values are allowed)
    int16 karma;

    /// @dev The amount of xp rewarded
    uint24 xp;
    
    /// @dev Fungible rewards
    FungibleTransactionData[] fungible;

    /// @dev Non-fungible rewards
    NonFungibleTransactionData[] nonFungible;
}

/// @dev Quest data per player
struct QuestPlayerData 
{
    /// @dev Times the quest has been completed
    uint16 completedCount;

    /// @dev Number of steps completed in this iteration
    uint8 stepsCompletedCount;

    /// @dev Steps completed in this iteration
    bytes8 stepsCompleted;

    /// @dev Timestamps
    uint64 timestampStarted;
    uint64 timestampCompleted;
    uint64 timestampClaimed;
}