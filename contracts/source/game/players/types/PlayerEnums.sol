// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @title Player enums
enum PlayerStat
{
    Speed,
    Charisma,
    Luck,
    Intelligence,
    Strength
}

/// @title ProfessionEnums
/// @notice Contains the different professions available in Cryptopia's mechanics
enum Profession 
{
    Any,
    Builder,
    Architect,
    Engineer,
    Miner
}