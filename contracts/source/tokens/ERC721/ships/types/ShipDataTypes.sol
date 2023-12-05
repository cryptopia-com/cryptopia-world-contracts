// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../../../game/types/GameEnums.sol";
import "../../../../game/types/FactionEnums.sol";

/// @dev Ship template
struct Ship
{
    /// @dev Ship name (unique)
    bytes32 name;

    /// @dev if true faction and subfaction are disregarded (any player can equipt)
    bool generic;

    /// @dev {Faction} (can only be equipted by this faction)
    Faction faction;

    /// @dev {SubFaction} (pirate/bountyhunter)
    SubFaction subFaction;

    /// @dev Ship rarity {Rarity}
    Rarity rarity;

    /// @dev the amount of module slots
    uint8 modules;

    /// @dev The amount of CO2 that is outputted
    uint16 co2;

    /// @dev Base speed (before modules)
    uint16 base_speed;

    /// @dev Base attack (before modules)
    uint16 base_attack;

    /// @dev Base health (before modules)
    uint16 base_health;

    /// @dev Base defence (before modules)
    uint16 base_defence;

    /// @dev Base storage (before modules)
    uint base_inventory;

    /// @dev Base fuel consumption (before modules)
    uint base_fuelConsumption;

    /// @dev The pirate version of this ship (if any)
    bytes32 pirateVersion;
}

/// @dev Ship instance (equiptable by player)
struct ShipInstance
{
    /// @dev Ship name (maps to template)
    bytes32 name;

    /// @dev If true the ship cannot be transferred
    bool locked;

    /// @dev The ID of the ship's skin
    uint16 skin;

    /// @dev Speed (after modules)
    uint16 speed;

    /// @dev Attack (after modules)
    uint16 attack;

    /// @dev Health (after modules)
    uint16 health;

    /// @dev Damage (0 - health)
    uint16 damage;

    /// @dev Defence (after modules)
    uint16 defence;

    /// @dev Storage (after modules)
    uint inventory;

    /// @dev Fuel consumption (after modules)
    uint fuelConsumption;
}

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

    /// @dev The ship's current damage (0 - health)
    uint16 damage;

    /// @dev The ship's base attack power 
    uint16 attack;

    /// @dev The ship's max health
    uint16 health;

    /// @dev The ship's defence score (after modules)
    uint16 defence;

    /// @dev True if the tile safety is inverted (unsafe tiles become safe and vice versa)
    bool tileSafetyInverse;
}