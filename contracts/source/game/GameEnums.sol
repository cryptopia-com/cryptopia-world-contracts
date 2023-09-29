// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Game enums
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract GameEnums {

    enum Faction
    {
        Eco,
        Tech,
        Industrial,
        Traditional
    }

    enum SubFaction 
    {
        None,
        Pirate,
        BountyHunter
    }

    enum Rarity
    {
        Common,
        Rare,
        Legendary,
        Master
    }
}