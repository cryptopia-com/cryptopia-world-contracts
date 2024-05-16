// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../game/types/GameEnums.sol";
import "../../../../game/types/FactionEnums.sol";

/// @dev Ship in Cryptopia
struct Ship
{
    /// @dev Unique name identifier for the ship
    bytes32 name;

    /// @dev Indicates if the ship is generic, allowing it to be equipped by any player regardless of faction
    bool generic;

    /// @dev Faction type (Eco, Tech, Traditional, Industrial) 
    Faction faction;

    /// @dev SubFaction type (None, Pirate, BountyHunter) 
    SubFaction subFaction;

    /// @dev Rarity level of the ship (Common, Rare, etc.)
    Rarity rarity;

    /// @dev The number of module slots available
    uint8 modules;

    /// @dev The CO2 emission level of the ship
    /// @notice Reflecting its environmental impact in the game's ecosystem
    uint16 co2;

    /// @dev Base speed defining the ship's movement capability 
    uint16 base_speed;

    /// @dev Base attack power of the ship 
    uint16 base_attack;

    /// @dev Base health points of the ship (max damage the ship can take)
    uint16 base_health;

    /// @dev Base defense rating (ability to resist attacks)
    uint16 base_defence;

    /// @dev Base storage capacity
    uint base_inventory;

    /// @dev Base fuel consumption rate (intercepting or escaping)
    uint base_fuelConsumption;

    /// @dev Reference to the pirate variant of the ship
    bytes32 pirateVersion;
}

/// @dev An Instance of a ship (ERC721 token data)
struct ShipInstance
{
    /// @dev Reference to Ship definition
    bytes32 name;

    /// @dev Indicates if the ship is locked, meaning it cannot be transferred if true
    bool locked;

    /// @dev Identifier for the ship's skin, defining its visual appearance
    uint16 skinIndex;

    /// @dev Effects on speed of any equipped modules
    uint16 speed;

    /// @dev Effects on attack of any equipped modules
    uint16 attack;

    /// @dev Effects on health of any equipped modules
    uint16 health;

    /// @dev Total damage taken
    uint16 damage;

    /// @dev Effects on defence of any equipped modules
    uint16 defence;

    /// @dev Effects on inventory of any equipped modules
    uint inventory;

    /// @dev Effects on fuelConsumption of any equipped modules
    uint fuelConsumption;
}

/// @dev Structure encapsulating essential ship equipment data
/// @notice Used to avoid 'stack too deep' errors
struct ShipEquipData 
{
    /// @dev Indicates if the ship is locked and thus non-transferable
    bool locked;

    /// @dev Indicates if the ship is generic, allowing it to be equipped by any player regardless of faction
    bool generic;

    /// @dev Faction type (Eco, Tech, Traditional, Industrial) 
    Faction faction;

    /// @dev SubFaction type (None, Pirate, BountyHunter) 
    SubFaction subFaction;

    /// @dev Storage capacity
    /// @notice Includes the effects of any equipped modules
    uint inventory;
}

/// @dev Structure representing the travel capabilities of a ship.
/// @notice Used to avoid 'stack too deep' errors
struct ShipTravelData 
{
    /// @dev Speed defining the ship's movement capability
    /// @notice Includes the effects of any equipped modules
    uint16 speed;

    /// @dev Fuel consumption rate (intercepting or escaping)
    /// @notice Includes the effects of any equipped modules
    uint fuelConsumption;
}

/// @dev Structure outlining the battle characteristics of a ship.
/// @notice Used in the `getShipBattleData` function to simplify data retrieval.
struct ShipBattleData 
{
    /// @dev The amount of damage currently sustained by the ship
    uint16 damage;

    /// @dev Attack power of the ship 
    /// @notice Includes the effects of any equipped modules
    uint16 attack;

    /// @dev Health points of the ship (max damage the ship can take)
    /// @notice Includes the effects of any equipped modules
    uint16 health;

    /// @dev Defense rating (ability to resist attacks)
    /// @notice Includes the effects of any equipped modules
    uint16 defence;

    /// @dev Indicates if tile safety is inverted (for pirates)
    bool tileSafetyInverse;
}
