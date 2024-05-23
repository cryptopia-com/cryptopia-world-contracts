// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../game/types/GameEnums.sol";
import "../../../../game/types/FactionEnums.sol";
import "../../../../game/players/types/PlayerEnums.sol";

/// @dev Development book in Cryptopia
struct DevelopmentBook
{
    /// @dev Unique name identifier for the book
    bytes32 name;

    /// @dev The player that authored the book (if any)
    address author;

    /// @dev The rarity of the book
    Rarity rarity;

    /// @dev The level required to use the book
    uint8 level;

    /// @dev Indicates if a faction constraint is applied to consume the book
    bool hasFactionConstraint;
    /// @dev Specific faction required to consume the book
    /// @notice Effective if hasFactionConstraint is true
    Faction faction;

    /// @dev Indicates if a sub-faction constraint is applied to consume the book
    bool hasSubFactionConstraint;
    /// @dev Specific sub-faction required to consume the book
    /// @notice Effective if hasSubFactionConstraint is true
    SubFaction subFaction;

    /// @dev The stats that this book will increase
    PlayerStat statType;

    /// @dev The amount of stats that this book will increase
    uint8 statIncrease;

    /// @dev Experience points awarded for consuming the book
    uint24 xp;
}

/// @dev Development book instance in Cryptopia
struct DevelopmentBookInstance
{
    /// @dev The token id of the book 
    uint tokenId;

    /// @dev The address that owns this book 
    address owner;

    /// @dev The index of the book
    uint16 index;

    /// @dev Unique name identifier for the book
    bytes32 name;

    /// @dev The player that authored the book (if any)
    address author;

    /// @dev The rarity of the book
    Rarity rarity;

    /// @dev The level required to use the book
    uint8 level;

    /// @dev Indicates if a faction constraint is applied to consume the book
    bool hasFactionConstraint;
    /// @dev Specific faction required to consume the book
    /// @notice Effective if hasFactionConstraint is true
    Faction faction;

    /// @dev Indicates if a sub-faction constraint is applied to consume the book
    bool hasSubFactionConstraint;
    /// @dev Specific sub-faction required to consume the book
    /// @notice Effective if hasSubFactionConstraint is true
    SubFaction subFaction;

    /// @dev The stats that this book will increase
    PlayerStat statType;

    /// @dev The amount of stats that this book will increase
    uint8 statIncrease;

    /// @dev Experience points awarded for consuming the book
    uint24 xp;
}