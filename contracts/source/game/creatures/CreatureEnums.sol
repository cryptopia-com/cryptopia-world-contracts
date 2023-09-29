// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Creature enums
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CreatureEnums {

    enum CreatureClass
    {
        Carnivore, // Strong against Herbivores, but weak against Reptiles
        Herbivore, // Strong against Aerials, but weak against Carnivores
        Reptile, // Strong against Carnivores, but weak against Aerials
        Aerial // Strong against Reptiles, but weak against Herbivores
    }
}