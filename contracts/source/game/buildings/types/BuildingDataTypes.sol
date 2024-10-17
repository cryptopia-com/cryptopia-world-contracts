// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../types/GameEnums.sol";
import "../../types/FactionEnums.sol";
import "./BuildingEnums.sol";

/// @dev Building in Cryptopia
struct Building
{
    /// @dev Unique name of the building
    bytes32 name;

    /// @dev Faction type (Eco, Tech, Traditional, Industrial) 
    Faction faction;

    /// @dev SubFaction type (None, Pirate, BountyHunter) 
    SubFaction subFaction;

    /// @dev Rarity level of the building (Common, Rare, etc.)
    Rarity rarity;

    /// @dev Type of building
    BuildingType buildingType;

    /// @dev The level of the building
    uint8 level;

    /// @dev The number of module slots available
    uint8 modules;

    /// @dev The CO2 emission level of the building
    /// @notice Reflecting its environmental impact in the game's ecosystem
    uint16 co2;

    /// @dev Base health points of the building (max damage the building can take)
    uint16 base_health;

    /// @dev Base defense rating (ability to resist attacks)
    uint16 base_defence;

    /// @dev Base storage capacity
    uint base_inventory;

    /// @dev Optional reference to the building this one upgrades from
    bytes32 upgradableFrom;
}

/// @dev Building instance
struct BuildingInstance
{
    /// @dev Reference to Building definition
    bytes32 name;

    /// @dev 0 - 100, indicating the construction progress
    uint8 construction; 

    /// @dev Effects on health of any equipped modules
    uint16 health;

    /// @dev Total damage taken
    uint16 damage;

    /// @dev Effects on defence of any equipped modules
    uint16 defence;

    /// @dev Effects on inventory of any equipped modules
    uint inventory;
}