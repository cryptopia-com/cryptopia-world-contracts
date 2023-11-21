// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Pirate confrontation data
struct Confrontation 
{
    // Pirate
    address attacker;

    // Location intercept took place
    uint16 location;

    // Arrival timestamp of the target (used to prevent multiple interceptions)
    uint64 arrival;

    // Deadline for the target to respond
    uint64 deadline;

    // Timestamp after which the confrontation expires (can be extended by the target)
    uint64 expiration;

    // Escape attempt (can only be attempted once)
    bool escapeAttempted;
}

/// @dev Pirate plunder data
struct Plunder  
{
    // Deadline for the pirate to loot
    uint64 deadline;

    // Timestamp after which the loot is no longer hot
    uint64 loot_hot;

    // Assets that the pirate has looted
    bytes32 loot_hash;
}