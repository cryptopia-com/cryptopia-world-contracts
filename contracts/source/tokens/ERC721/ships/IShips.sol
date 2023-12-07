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


    /// @dev Retreive a ships by name
    /// @param name Ship name (unique)
    /// @return ship a single ship 
    function getShip(bytes32 name) 
        external view 
        returns (Ship memory ship);


    /// @dev Retreive a rance of ships
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return ships range of ships
    function getShips(uint skip, uint take) 
        external view 
        returns (Ship[] memory ships);


    /// @dev Retreive a ships by token id
    /// @param tokenId The id of the ship to retreive
    /// @return instance a single ship instance
    function getShipInstance(uint tokenId) 
        external view 
        returns (ShipInstance memory instance);

    
    /// @dev Retreive ships by token ids
    /// @param tokenIds The ids of the ships to retreive
    /// @return instances a range of ship instances
    function getShipInstances(uint[] memory tokenIds) 
        external view 
        returns (ShipInstance[] memory instances);


    /// @dev Retrieve equipt data for a ship instance
    /// @param tokenId The id of the ship to retreive the inventory data for
    /// @return equipData Ship equip data
    function getShipEquipData(uint tokenId)
        external view 
        returns (ShipEquipData memory equipData);

    
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


    /// @dev Apply damage to a ship
    /// @param ships_ The ids of the ships to apply damage to
    /// @param damage1 The amount of damage to apply to ship 1
    /// @param damage2 The amount of damage to apply to ship 2
    function __applyDamage(TokenPair memory ships_, uint16 damage1, uint16 damage2)
        external;


    /// @dev Update `ship` to it's pirate version
    /// @param ship The id of the ship to turn into a pirate
    function __turnPirate(uint ship)
        external;
}