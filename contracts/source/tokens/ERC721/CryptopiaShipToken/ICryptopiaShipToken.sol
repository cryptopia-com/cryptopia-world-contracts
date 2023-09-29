// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../../game/GameEnums.sol";

/// @title ICryptopiaShipToken Token
/// @dev Non-fungible token (ERC721) 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICryptopiaShipToken {

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
    /// @return base_health Ship starting health (before modules)
    /// @return base_defence Ship starting defence (before modules)
    /// @return base_inventory Ship starting storage (before modules)
    function getShips(uint skip, uint take) 
        external view 
        returns (
            bytes32[] memory name,
            bool[] memory generic,
            GameEnums.Faction[] memory faction,
            GameEnums.SubFaction[] memory subFaction,
            GameEnums.Rarity[] memory rarity,
            uint24[] memory modules, 
            uint24[] memory base_speed,
            uint24[] memory base_attack,
            uint24[] memory base_health,
            uint24[] memory base_defence,
            uint[] memory base_inventory
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
    /// @return base_health Ship starting health (before modules)
    /// @return base_defence Ship starting defence (before modules)
    /// @return base_inventory Ship starting storage (before modules)
    function getShip(bytes32 name) 
        external view 
        returns (
            bool generic,
            GameEnums.Faction faction,
            GameEnums.SubFaction subFaction,
            GameEnums.Rarity rarity,
            uint24 modules, 
            uint24 base_speed,
            uint24 base_attack,
            uint24 base_health,
            uint24 base_defence,
            uint base_inventory
        );


    /// @dev Add or update ships
    /// @param name Ship name (unique)
    /// @param generic if true faction and subfaction are disregarded (any player can equipt)
    /// @param faction {Faction} (can only be equipted by this faction)
    /// @param subFaction {SubFaction} (pirate/bountyhunter)
    /// @param rarity Ship rarity {Rarity}
    /// @param stats modules, arbitrary, base_speed, base_attack, base_health, base_defence, base_inventory
    function setShips(
        bytes32[] memory name, 
        bool[] memory generic, 
        GameEnums.Faction[] memory faction, 
        GameEnums.SubFaction[] memory subFaction, 
        GameEnums.Rarity[] memory rarity, 
        uint[7][] memory stats) 
        external;


    /// @dev Retreive a ships by token id
    /// @param tokenId The id of the ship to retreive
    /// @return name Ship name (unique)
    /// @return locked True if the ship cannot be transferred
    /// @return generic True if faction and subfaction are disregarded (any player can equipt)
    /// @return faction {Faction} (can only be equipted by this faction)
    /// @return subFaction {SubFaction} (pirate/bountyhunter)
    /// @return rarity Ship rarity {Rarity}
    /// @return modules Amount of module slots
    /// @return speed Ship speed (after modules)
    /// @return attack Ship attack (after modules)
    /// @return health Ship health (after modules)
    /// @return defence Ship defence (after modules)
    /// @return inventory Ship storage (after modules)
    function getShipInstance(uint tokenId) 
        external view 
        returns (
            bytes32 name,
            bool locked,
            bool generic,
            GameEnums.Faction faction,
            GameEnums.SubFaction subFaction,
            GameEnums.Rarity rarity,
            uint24 modules,
            uint24 speed,
            uint24 attack,
            uint24 health,
            uint24 defence,
            uint inventory
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
    /// @return speed Ship speed (after modules)
    /// @return attack Ship attack (after modules)
    /// @return health Ship health (after modules)
    /// @return defence Ship defence (after modules)
    /// @return inventory Ship storage (after modules)
    function getShipInstances(uint[] memory tokenIds) 
        external view 
        returns (
            bytes32[] memory name,
            bool[] memory locked,
            bool[] memory generic,
            GameEnums.Faction[] memory faction,
            GameEnums.SubFaction[] memory subFaction,
            GameEnums.Rarity[] memory rarity,
            uint24[] memory modules,
            uint24[] memory speed,
            uint24[] memory attack,
            uint24[] memory health,
            uint24[] memory defence,
            uint[] memory inventory
        );


    /// @dev Retrieve equipt data for a ship instance
    /// @param tokenId The id of the ship to retreive the inventory data for
    /// @return locked If true the ship cannot be transferred
    /// @return generic if true faction and subfaction are disregarded (any player can equipt)
    /// @return faction {Faction} (can only be equipted by this faction)
    /// @return subFaction {SubFaction} (pirate/bountyhunter)
    /// @return inventory Ship storage (after modules)
    function getShipEquiptData(uint tokenId)
        external view 
        returns (
            bool locked,
            bool generic,
            GameEnums.Faction faction,
            GameEnums.SubFaction subFaction,
            uint inventory
        );

    
    /// @dev Mints a starter ship to a player
    /// @param player address of the player
    /// @param faction player's faction
    /// @param locked If true the ship is equipted and can't be transferred
    /// @param tokenId the token id of the minted ship
    /// @param inventory the ship inventory space
    function mintStarterShip(address player, GameEnums.Faction faction, bool locked)  
        external 
        returns (
            uint tokenId, 
            uint inventory
        );


    /// @dev Mints a ship to an address
    /// @param to address of the owner of the ship
    /// @param name Unique ship name
    function mintTo(address to, bytes32 name) 
        external;

    
    /// @dev Lock `next` and release 'prev'
    /// @param prev The tokenId of the previously locked (equipted) ship
    /// @param next The tokenId of the ship that replaces `prev` and thus is being locked
    function lock(uint prev, uint next)
        external; 
}