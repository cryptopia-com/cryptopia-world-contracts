// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "./LabourEnums.sol";

/// @dev Represents labour requirements, including profession and level constraints
struct LabourRequirement 
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

    /// @dev The number of professionals needed
    uint8 requiredProfessionals;
}