// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @dev Data related to a pirate's confrontation with a target player
struct Confrontation 
{
    /// @dev Address of the pirate initiating the confrontation
    address attacker;

    /// @dev The map location where the interception occurred
    uint16 location;

    /// @dev Timestamp of the target's arrival
    /// @notice Used to prevent multiple interceptions
    uint64 arrival;

    /// @dev Deadline for the target to respond to the confrontation
    uint64 deadline;

    /// @dev Expiration timestamp for the confrontation
    /// @notice After expiration the confrontation can no longer be acted upon
    uint64 expiration;

    /// @dev Indicates whether an escape attempt has been made (true if attempted)
    bool escapeAttempted;
}

/// @dev Data related to the potential plundering by a pirate post-confrontation
struct Plunder  
{
    /// @dev Deadline for the pirate to complete the looting process
    uint64 deadline;

    /// @dev Timestamp indicating when the looted assets are no longer considered 'hot' (recently stolen)
    uint64 loot_hot;

    /// @dev Hash of the looted assets, representing what the pirate has taken
    bytes32 loot_hash;
}
