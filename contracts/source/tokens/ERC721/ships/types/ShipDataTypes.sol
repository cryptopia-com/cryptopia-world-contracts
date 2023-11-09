// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../../../game/types/FactionEnums.sol";

/// @dev Represents ship equip data
/// @notice Used as return type for `getShipEquipData` to prevent stack too deep errors
struct ShipEquipData {

    /// @dev If true the ship cannot be transferred
    bool locked;

    /// @dev If true faction and subfaction are disregarded (any player can equipt)
    bool generic;

    /// @dev {Faction} (can only be equipted by this faction)
    Faction faction;

    /// @dev {SubFaction} (pirate/bountyhunter)
    SubFaction subFaction;

    /// @dev Ship storage (after modules)
    uint inventory;
}

/// @dev Represents ship travel data
/// @notice Used as return type for `getShipTravelData` to prevent stack too deep errors
struct ShipTravelData {

    /// @dev The ship's speed
    uint16 speed;

    /// @dev The ship's fuel consumption (fuel token)
    uint fuelConsumption;
}

/// @dev Represents ship battle data
/// @notice Used as return type for `getShipBattleData` to prevent stack too deep errors
struct ShipBattleData {

    /// @dev The ship's current damage (max 250)
    uint8 damage;

    /// @dev The ship's base attack power 
    uint16 attack;

    /// @dev The ship's defence score (after modules)
    uint16 defence;
}