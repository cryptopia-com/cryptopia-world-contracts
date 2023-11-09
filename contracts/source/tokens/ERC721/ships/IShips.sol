// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../../game/types/GameEnums.sol";
import "../../../game/types/FactionEnums.sol";
import "../types/ERC721DataTypes.sol";
import "./types/ShipDataTypes.sol";

/// @title Ships
/// @dev Non-fungible token (ERC721) 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IShips {

    /**
     * Public functions
     */
    /// @dev Returns the amount of different ships
    /// @return count The amount of different ships
    function getShipCount() 
        external view 
        returns (uint);


    /// @dev Retreive a rance of ships
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return name Ship name (unique)
    /// @return generic if true faction and subfaction are disregarded (any player can equipt)
    /// @return faction {Faction} (can only be equipted by this faction)
    /// @return subFaction {SubFaction} (pirate/bountyhunter)
    /// @return rarity Ship rarity {Rarity}
    /// @return modules the amount of module slots
    /// @return base_speed Ship starting speed (before modules)
    /// @return base_attack Ship starting attack (before modules)
    /// @return base_defence Ship starting defence (before modules)
    /// @return base_inventory Ship starting storage (before modules)
    /// @return base_fuelConsumption Ship starting fuel consumption (before modules)
    function getShips(uint skip, uint take) 
        external view 
        returns (
            bytes32[] memory name,
            bool[] memory generic,
            Faction[] memory faction,
            SubFaction[] memory subFaction,
            Rarity[] memory rarity,
            uint8[] memory modules, 
            uint16[] memory base_speed,
            uint16[] memory base_attack,
            uint16[] memory base_defence,
            uint[] memory base_inventory,
            uint[] memory base_fuelConsumption
        );


    /// @dev Retreive a ships by name
    /// @param name Ship name (unique)
    /// @return generic True if faction and subfaction are disregarded (any player can equipt)
    /// @return faction {Faction} (can only be equipted by this faction)
    /// @return subFaction {SubFaction} (pirate/bountyhunter)
    /// @return rarity Ship rarity {Rarity}
    /// @return modules Amount of module slots
    /// @return base_speed Ship starting speed (before modules)
    /// @return base_attack Ship starting attack (before modules)
    /// @return base_defence Ship starting defence (before modules)
    /// @return base_inventory Ship starting storage (before modules)
    /// @return base_fuelConsumption Ship starting fuel consumption (before modules)
    function getShip(bytes32 name) 
        external view 
        returns (
            bool generic,
            Faction faction,
            SubFaction subFaction,
            Rarity rarity,
            uint8 modules, 
            uint16 base_speed,
            uint16 base_attack,
            uint16 base_defence,
            uint base_inventory,
            uint base_fuelConsumption
        );


    /// @dev Retreive a ships by token id
    /// @param tokenId The id of the ship to retreive
    /// @return name Ship name (unique)
    /// @return locked True if the ship cannot be transferred
    /// @return generic True if faction and subfaction are disregarded (any player can equipt)
    /// @return faction {Faction} (can only be equipted by this faction)
    /// @return subFaction {SubFaction} (pirate/bountyhunter)
    /// @return rarity Ship rarity {Rarity}
    /// @return modules Amount of module slots
    /// @return damage Ship damage (0 - 250)
    /// @return speed Ship speed (after modules)
    /// @return attack Ship attack (after modules)
    /// @return defence Ship defence (after modules)
    /// @return inventory Ship storage (after modules)
    /// @return fuelConsumption Ship fuel consumption (after modules)
    function getShipInstance(uint tokenId) 
        external view 
        returns (
            bytes32 name,
            bool locked,
            bool generic,
            Faction faction,
            SubFaction subFaction,
            Rarity rarity,
            uint8 modules,
            uint8 damage,
            uint16 speed,
            uint16 attack,
            uint16 defence,
            uint inventory,
            uint fuelConsumption
        );

    
    /// @dev Retreive ships by token ids
    /// @param tokenIds The id of the ship to retreive
    /// @return name Ship name (unique)
    /// @return locked True if the ship cannot be transferred
    /// @return generic True if faction and subfaction are disregarded (any player can equipt)
    /// @return faction {Faction} (can only be equipted by this faction)
    /// @return subFaction {SubFaction} (pirate/bountyhunter)
    /// @return rarity Ship rarity {Rarity}
    /// @return modules Amount of module slots
    /// @return damage Ship damage (0 - 250)
    /// @return speed Ship speed (after modules)
    /// @return attack Ship attack (after modules)
    /// @return defence Ship defence (after modules)
    /// @return inventory Ship storage (after modules) 
    function getShipInstances(uint[] memory tokenIds) 
        external view 
        returns (
            bytes32[] memory name,
            bool[] memory locked,
            bool[] memory generic,
            Faction[] memory faction,
            SubFaction[] memory subFaction,
            Rarity[] memory rarity,
            uint8[] memory modules,
            uint8[] memory damage,
            uint16[] memory speed,
            uint16[] memory attack,
            uint16[] memory defence,
            uint[] memory inventory
        );


    /// @dev Retrieve equipt data for a ship instance
    /// @param tokenId The id of the ship to retreive the inventory data for
    /// @return equipData Ship equip data
    function getShipEquipData(uint tokenId)
        external view 
        returns (ShipEquipData memory);

    
    /// @dev Retrieve the speed of a ship instance (after modules)
    /// @param tokenId The id of the ship to retreive the speed for
    /// @return speed Ship speed (after modules)
    function getShipSpeed(uint tokenId) 
        external view 
        returns (uint16 speed);


    /// @dev Retrieve the fuel consumption of a ship instance (after modules)
    /// @param tokenId The id of the ship to retreive the fuel consumption for
    /// @return fuelConsumption Ship fuel consumption (after modules)
    function getShipFuelConsumption(uint tokenId) 
        external view 
        returns (uint fuelConsumption);


    /// @dev Retrieve the travel data of a ship instance (after modules)
    /// @param tokenId The id of the ship to retreive the travel data for
    /// @return travelData Ship travel data (after modules)
    function getShipTravelData(uint tokenId)
        external view 
        returns (ShipTravelData memory travelData);

    
    /// @dev Retrieve the travel data of a ship instance (after modules)
    /// @param tokenIds The ids of the ships to retreive the travel data for
    /// @return travelData1 The travel data of ship 1 (after modules)
    /// @return travelData2 The travel data of ship 2 (after modules)
    function getShipTravelData(TokenPair memory tokenIds)
        external view 
        returns (
            ShipTravelData memory travelData1, 
            ShipTravelData memory travelData2
        );


    /// @dev Retrieve the battle data of a ship instance (after modules)
    /// @param tokenId The id of the ship to retreive the battle data for
    /// @return battleData Ship battle data (after modules)
    function getShipBattleData(uint tokenId)
        external view 
        returns (ShipBattleData memory battleData);

    
    /// @dev Retrieve the battle data of a ship instance (after modules)
    /// @param tokenIds The ids of the ships to retreive the battle data for
    /// @return battleData1 The battle data of ship 1
    /// @return battleData2 The battle data of ship 2
    function getShipBattleData(TokenPair memory tokenIds)
        external view 
        returns (
            ShipBattleData memory battleData1,
            ShipBattleData memory battleData2 
        );

    
    /**
     * System functions
     */
    /// @dev Mints a starter ship to a player
    /// @param player address of the player
    /// @param faction player's faction
    /// @param locked If true the ship is equipted and can't be transferred
    /// @param tokenId the token id of the minted ship
    /// @param inventory the ship inventory space
    function __mintStarterShip(address player, Faction faction, bool locked)  
        external 
        returns (
            uint tokenId, 
            uint inventory
        );


    /// @dev Mints a ship to an address
    /// @param to address of the owner of the ship
    /// @param name Unique ship name
    function __mintTo(address to, bytes32 name) 
        external;

    
    /// @dev Lock `next` and release 'prev'
    /// @param prev The tokenId of the previously locked (equipted) ship
    /// @param next The tokenId of the ship that replaces `prev` and thus is being locked
    function __lock(uint prev, uint next)
        external; 
}