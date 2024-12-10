// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "./LabourEnums.sol";

/// @dev Represents labour data
struct LabourData
{
    /// @dev The profession required
    Profession profession;

    /// @dev Indicates if a minimum level is specified
    bool hasMinimumLevel;

    /// @dev The minimum level required (if hasMinimumLevel is true)
    uint8 minLevel;

    /// @dev Indicates if a maximum level is specified
    bool hasMaximumLevel;

    /// @dev The maximum level allowed (if hasMaximumLevel is true)
    uint8 maxLevel;

    /// @dev The number of slots that can be filled by professionals
    uint8 slots;

    /// @dev Action values
    uint64 actionValue1;
    uint64 actionValue2;
}

/// @dev Represents labour data
struct LabourContract
{
    /// @dev The profession required
    Profession profession;

    /// @dev Indicates if a minimum level is specified
    bool hasMinimumLevel;

    /// @dev The minimum level required (if hasMinimumLevel is true)
    uint8 minLevel;

    /// @dev Indicates if a maximum level is specified
    bool hasMaximumLevel;

    /// @dev The maximum level allowed (if hasMaximumLevel is true)
    uint8 maxLevel;

    /// @dev The total number of slots that can be filled by professionals
    uint8 slots; 

    /// @dev The number of open slots that can still be filled by professionals
    uint8 openSlots;

    /// @dev Action values
    uint64 actionValue1;
    uint64 actionValue2;

    /// @dev The compensation for the labour
    uint compensation;
}