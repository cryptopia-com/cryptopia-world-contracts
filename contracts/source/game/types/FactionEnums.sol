// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @title Factions
enum Faction
{
    Eco,
    Tech,
    Industrial,
    Traditional,
    Count // Sentinel value
}

/// @title Sub factions
enum SubFaction 
{
    None,
    Pirate,
    BountyHunter
}