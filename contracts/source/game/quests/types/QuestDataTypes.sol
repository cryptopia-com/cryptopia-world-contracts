// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../inventories/types/InventoryDataTypes.sol";
import "../../types/FactionEnums.sol";

/// @dev Struct representing a quest within Cryptopia
/// @notice Quests come with constraints (like level or faction requirements) that players must meet to start them
/// @notice Quests include a series of ordered steps for completion and offer multiple rewards for players to choose from upon completion
struct Quest {

    /// @dev Unique identifier for the quest
    bytes32 name;

    /// @dev Indicates if a level constraint is applied to start the quest
    bool hasLevelConstraint;
    /// @dev Minimum player level required to start the quest, effective if hasLevelConstraint is true
    uint8 level;

    /// @dev Indicates if a faction constraint is applied to start the quest
    bool hasFactionConstraint;
    /// @dev Specific faction required to start the quest, effective if hasFactionConstraint is true
    Faction faction;

    /// @dev Indicates if a sub-faction constraint is applied to start the quest
    bool hasSubFactionConstraint;
    /// @dev Specific sub-faction required to start the quest, effective if hasSubFactionConstraint is true
    SubFaction subFaction;

    /// @dev Indicates if there's a limit on how many times the quest can be repeated
    bool hasRecurrenceConstraint;
    /// @dev Maximum number of times the quest can be repeated, effective if hasRecurrenceConstraint is true
    uint maxRecurrences;

    /// @dev Indicates if there's a cooldown period between quest repetitions
    bool hasCooldownConstraint;
    /// @dev Cooldown duration in seconds before the quest can be started again, effective if hasCooldownConstraint is true
    uint cooldown;

    /// @dev Indicates if there's a time limit to complete the quest
    bool hasTimeConstraint;
    /// @dev Maximum duration in seconds to complete the quest, effective if hasTimeConstraint is true
    uint maxDuration;

    /// @dev Array of steps that need to be completed in order to finish the quest
    QuestStep[] steps;

    /// @dev Array of rewards available upon quest completion
    /// @notice Players can choose only one reward per quest completion
    QuestReward[] rewards;
}

/// @dev Struct representing a step within a quest
/// @notice Each step may have specific constraints (like location) and involves giving or taking certain items
struct QuestStep {
    
    /// @dev Unique identifier for the quest step
    bytes32 name;

    /// @dev Indicates if the step requires the player to be at a specific location
    bool hasTileConstraint;
    /// @dev Specific map tile where the step needs to be completed, effective if hasTileConstraint is true
    uint16 tile;

    /// @dev Array of fungible tokens (like ERC20 tokens) that the player must give up to complete the step
    FungibleTransactionData[] takeFungible;

    /// @dev Array of non-fungible tokens (like ERC721 tokens) that the player must give up to complete the step
    NonFungibleTransactionData[] takeNonFungible;

    /// @dev Array of fungible tokens that the player receives upon completing the step
    FungibleTransactionData[] giveFungible;

    /// @dev Array of non-fungible tokens that the player receives upon completing the step
    NonFungibleTransactionData[] giveNonFungible;
}

/// @dev Struct representing a reward for completing a quest
/// @notice Rewards include experience points, karma (which can be negative), and tokens
struct QuestReward {

    /// @dev Unique identifier for the reward
    bytes32 name;

    /// @dev Karma points awarded (or deducted if negative) for claiming the reward
    int16 karma;

    /// @dev Experience points awarded for claiming the reward
    uint24 xp;
    
    /// @dev Array of fungible rewards (like ERC20 tokens) awarded
    FungibleTransactionData[] fungible;

    /// @dev Array of non-fungible rewards (like ERC721 tokens) awarded
    NonFungibleTransactionData[] nonFungible;
}