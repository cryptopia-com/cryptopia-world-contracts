// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../../../game/types/GameEnums.sol";
import "../../../../game/types/FactionEnums.sol";
import "../../../../game/players/IPlayerRegister.sol";
import "../../ships/IShips.sol";  
import "../../ships/errors/ShipErrors.sol";  
import "../CryptopiaERC721.sol";

/// @title Cryptopia Ship Token
/// @dev Non-fungible token (ERC721)
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaShipToken is CryptopiaERC721, IShips {
    
    /// @dev Ship template
    struct Ship
    {
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
    }

    /// @dev Ship instance (equiptable by player)
    struct ShipInstance
    {
        /// @dev Ship name (maps to template)
        bytes32 name;

        /// @dev If true the ship cannot be transferred
        bool locked;

        /// @dev Speed (after modules)
        uint16 speed;

        /// @dev Attack (after modules)
        uint16 attack;

        /// @dev Health (after modules)
        uint16 health;

        /// @dev Defence (after modules)
        uint16 defence;

        /// @dev Storage (after modules)
        uint inventory;

        /// @dev Fuel consumption (after modules)
        uint fuelConsumption;
    }

    /// @dev Input argument
    struct ShipStatValues
    {
        /// @dev The number of module slots available on the ship
        uint8 modules;

        /// @dev The amount of CO2 that is outputted
        uint16 co2;

        /// @dev The base speed of the ship before any modules are applied
        uint16 speed;

        /// @dev The base attack power of the ship before any modules are applied
        uint16 attack;

        /// @dev The base health of the ship before any modules are applied
        uint16 health;

        /// @dev The base defence capability of the ship before any modules are applied
        uint16 defence;

        /// @dev The base storage capacity of the ship before any modules are applied
        uint inventory;

        /// @dev The base fuel consumption of the ship before any modules are applied
        uint fuelConsumption;
    }


    /**
     * Storage
     */
    uint private _currentTokenId; 

    /// @dev name => Ship
    mapping(bytes32 => Ship) private ships;
    bytes32[] private shipsIndex;

    /// @dev tokenId => ShipInstance
    mapping (uint => ShipInstance) private shipInstances;


    /**
     * Errors
     */
    /// @dev Emitted when `ship` does not exist
    /// @param ship The ship that does not exist
    error ShipNotFound(bytes32 ship);


    /**
     * Modifiers
     */
    /// @dev Requires that an item with `name` exists
    /// @param name Unique token name
    modifier onlyExisting(bytes32 name)
    {
        if (!_exists(name)) 
        {
            revert ShipNotFound(name);
        }
        _;
    }


    /// @dev Contract initializer sets shared base uri
    /// @param authenticator Whitelist
    /// @param initialContractURI Location to contract info
    /// @param initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    function initialize(
        address authenticator, 
        string memory initialContractURI, 
        string memory initialBaseTokenURI) 
        public initializer 
    {
        __CryptopiaERC721_init(
            "Cryptopia Ships", "SHIP", authenticator, initialContractURI, initialBaseTokenURI);

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Add starter ships
        _setShip("Whitewake", false, Faction.Eco, SubFaction.None, Rarity.Common, ShipStatValues({
            modules: 1,
            co2: 0,
            speed: 25,
            attack: 15,
            health: 100,
            defence: 100,
            inventory: 12_000_000_000_000_000_000_000,
            fuelConsumption: 1_000_000_000_000_000_000
        }));

        _setShip("Polaris", false, Faction.Tech, SubFaction.None, Rarity.Common, ShipStatValues({
            modules: 1,
            co2: 25,
            speed: 25,
            attack: 15,
            health: 100,
            defence: 100,
            inventory: 12_000_000_000_000_000_000_000,
            fuelConsumption: 1_000_000_000_000_000_000
        }));

        _setShip("Kingfisher", false, Faction.Industrial, SubFaction.None, Rarity.Common, ShipStatValues({
            modules: 1,
            co2: 50,
            speed: 25,
            attack: 15,
            health: 100,
            defence: 100,
            inventory: 12_000_000_000_000_000_000_000,
            fuelConsumption: 1_000_000_000_000_000_000
        }));

        _setShip("Socrates", false, Faction.Traditional, SubFaction.None, Rarity.Common, ShipStatValues({
            modules: 1,
            co2: 25,
            speed: 25,
            attack: 15,
            health: 100,
            defence: 100,
            inventory: 12_000_000_000_000_000_000_000,
            fuelConsumption: 1_000_000_000_000_000_000
        }));
    }


    /**
     * Public functions
     */
    /// @dev Returns the amount of different ships
    /// @return count The amount of different ships
    function getShipCount() 
        public virtual override view 
        returns (uint)
    {
        return shipsIndex.length;
    }


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
    /// @return base_fuelConsumption Ship starting fuel consumption (before modules)
    function getShips(uint skip, uint take) 
        public override view 
        returns (
            bytes32[] memory name,
            bool[] memory generic,
            Faction[] memory faction,
            SubFaction[] memory subFaction,
            Rarity[] memory rarity,
            uint8[] memory modules, 
            uint16[] memory base_speed,
            uint16[] memory base_attack,
            uint16[] memory base_health,
            uint16[] memory base_defence,
            uint[] memory base_inventory,
            uint[] memory base_fuelConsumption
        )
    {
        name = new bytes32[](take);
        generic = new bool[](take);
        faction = new Faction[](take);
        subFaction = new SubFaction[](take);
        rarity = new Rarity[](take);
        modules = new uint8[](take);
        base_speed = new uint16[](take);
        base_attack = new uint16[](take);
        base_health = new uint16[](take);
        base_defence = new uint16[](take);
        base_inventory = new uint[](take);
        base_fuelConsumption = new uint[](take);

        uint index = skip;
        for (uint i = 0; i < take; i++)
        {
            name[i] = shipsIndex[index];
            generic[i] = ships[name[i]].generic;
            faction[i] = ships[name[i]].faction;
            subFaction[i] = ships[name[i]].subFaction;
            rarity[i] = ships[name[i]].rarity;
            modules[i] = ships[name[i]].modules;
            base_speed[i] = ships[name[i]].base_speed;
            base_attack[i] = ships[name[i]].base_attack;
            base_health[i] = ships[name[i]].base_health;
            base_defence[i] = ships[name[i]].base_defence;
            base_inventory[i] = ships[name[i]].base_inventory;
            base_fuelConsumption[i] = ships[name[i]].base_fuelConsumption;
            index++;
        }
    }


    /// @dev Retreive a ships by name
    /// @param name Ship name (unique)
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
    /// @return base_fuelConsumption Ship starting fuel consumption (before modules)
    function getShip(bytes32 name) 
        public virtual override view 
        returns (
            bool generic,
            Faction faction,
            SubFaction subFaction,
            Rarity rarity,
            uint8 modules,
            uint16 base_speed,
            uint16 base_attack,
            uint16 base_health,
            uint16 base_defence,
            uint base_inventory,
            uint base_fuelConsumption
        )
    {
        generic = ships[name].generic;
        faction = ships[name].faction;
        subFaction = ships[name].subFaction;
        rarity = ships[name].rarity;
        modules = ships[name].modules;
        base_speed = ships[name].base_speed;
        base_attack = ships[name].base_attack;
        base_health = ships[name].base_health;
        base_defence = ships[name].base_defence;
        base_inventory = ships[name].base_inventory;
        base_fuelConsumption = ships[name].base_fuelConsumption;
    }


    /// @dev Add or update ships
    /// @param name Ship name (unique)
    /// @param generic if true faction and subfaction are disregarded (any player can equipt)
    /// @param faction {Faction} (can only be equipted by this faction)
    /// @param subFaction {SubFaction} (pirate/bountyhunter)
    /// @param stats modules, arbitrary, base_speed, base_attack, base_health, base_defence, base_inventory
    function setShips(
        bytes32[] memory name, 
        bool[] memory generic, 
        Faction[] memory 
        faction, SubFaction[] 
        memory subFaction, 
        Rarity[] memory rarity, 
        ShipStatValues[] memory stats) 
        public virtual  
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < name.length; i++)
        {
            _setShip(
                name[i], 
                generic[i], 
                faction[i], 
                subFaction[i],
                rarity[i],
                stats[i]);
        }
    }


    /// @dev Retreive a ships by token id
    /// @param tokenId The id of the ship to retreive
    /// @return name Ship name (unique)
    /// @return locked If true the ship cannot be transferred
    /// @return generic if true faction and subfaction are disregarded (any player can equipt)
    /// @return faction {Faction} (can only be equipted by this faction)
    /// @return subFaction {SubFaction} (pirate/bountyhunter)
    /// @return rarity Ship rarity {Rarity}
    /// @return modules the amount of module slots
    /// @return speed Ship speed (after modules)
    /// @return attack Ship attack (after modules)
    /// @return health Ship health (after modules)
    /// @return defence Ship defence (after modules)
    /// @return inventory Ship storage (after modules)
    /// @return fuelConsumption Ship fuel consumption (after modules)
    function getShipInstance(uint tokenId) 
        public virtual override view 
        returns (
            bytes32 name,
            bool locked,
            bool generic,
            Faction faction,
            SubFaction subFaction,
            Rarity rarity,
            uint8 modules,
            uint16 speed,
            uint16 attack,
            uint16 health,
            uint16 defence,
            uint inventory,
            uint fuelConsumption
        )
    {
        name = shipInstances[tokenId].name;
        locked = shipInstances[tokenId].locked;
        generic = ships[name].generic;
        faction = ships[name].faction;
        subFaction = ships[name].subFaction;
        rarity = ships[name].rarity;
        modules = ships[name].modules;
        speed = ships[name].base_speed + shipInstances[tokenId].speed;
        attack = ships[name].base_attack + shipInstances[tokenId].attack;
        health = ships[name].base_health + shipInstances[tokenId].health;
        defence = ships[name].base_defence + shipInstances[tokenId].defence;
        inventory = ships[name].base_inventory + shipInstances[tokenId].inventory;
        fuelConsumption = ships[name].base_fuelConsumption + shipInstances[tokenId].fuelConsumption;
    }


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
        public virtual override view 
        returns (
            bytes32[] memory name,
            bool[] memory locked,
            bool[] memory generic,
            Faction[] memory faction,
            SubFaction[] memory subFaction,
            Rarity[] memory rarity,
            uint8[] memory modules,
            uint16[] memory speed,
            uint16[] memory attack,
            uint16[] memory health,
            uint16[] memory defence,
            uint[] memory inventory
        )
    {
        name = new bytes32[](tokenIds.length);
        locked = new bool[](tokenIds.length);
        generic = new bool[](tokenIds.length);
        faction = new Faction[](tokenIds.length);
        subFaction = new SubFaction[](tokenIds.length);
        rarity = new Rarity[](tokenIds.length);
        modules = new uint8[](tokenIds.length);
        speed = new uint16[](tokenIds.length);
        attack = new uint16[](tokenIds.length);
        health = new uint16[](tokenIds.length);
        defence = new uint16[](tokenIds.length);
        inventory = new uint[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; i++)
        {
            name[i] = shipInstances[tokenIds[i]].name;
            locked[i] = shipInstances[tokenIds[i]].locked;
            generic[i] = ships[name[i]].generic;
            faction[i] = ships[name[i]].faction;
            subFaction[i] = ships[name[i]].subFaction;
            rarity[i] = ships[name[i]].rarity;
            modules[i] = ships[name[i]].modules;
            speed[i] = ships[name[i]].base_speed + shipInstances[tokenIds[i]].speed;
            attack[i] = ships[name[i]].base_attack + shipInstances[tokenIds[i]].attack;
            health[i] = ships[name[i]].base_health + shipInstances[tokenIds[i]].health;
            defence[i] = ships[name[i]].base_defence + shipInstances[tokenIds[i]].defence;
            inventory[i] = ships[name[i]].base_inventory + shipInstances[tokenIds[i]].inventory;
        }
    }


    /// @dev Retrieve equipt data for a ship instance
    /// @param tokenId The id of the ship to retreive the inventory data for
    /// @return locked If true the ship cannot be transferred
    /// @return generic if true faction and subfaction are disregarded (any player can equipt)
    /// @return faction {Faction} (can only be equipted by this faction)
    /// @return subFaction {SubFaction} (pirate/bountyhunter)
    /// @return inventory Ship storage (after modules)
    function getShipEquiptData(uint tokenId)
        public virtual override view 
        returns (
            bool locked,
            bool generic,
            Faction faction,
            SubFaction subFaction,
            uint inventory
        )
    {
        Ship storage ship = ships[shipInstances[tokenId].name];
        locked = shipInstances[tokenId].locked;
        generic = ship.generic;
        faction = ship.faction;
        subFaction = ship.subFaction;
        inventory = ship.base_inventory + shipInstances[tokenId].inventory;
    }


    /// @dev Retrieve the speed of a ship instance (after modules)
    /// @param tokenId The id of the ship to retreive the speed for
    /// @return speed Ship speed (after modules)
    function getShipSpeed(uint tokenId) 
        public virtual override view  
        returns (uint16 speed)
    {
        speed = ships[shipInstances[tokenId].name].base_speed + shipInstances[tokenId].speed;
    }

    
    /// @dev Retrieve the fuel consumption of a ship instance (after modules)
    /// @param tokenId The id of the ship to retreive the fuel consumption for
    /// @return fuelConsumption Ship fuel consumption (after modules)
    function getShipFuelConsumption(uint tokenId) 
        public virtual override view  
        returns (uint fuelConsumption)
    {
        fuelConsumption = ships[shipInstances[tokenId].name].base_fuelConsumption + shipInstances[tokenId].fuelConsumption;
    }


    /// @dev Retrieve the travel data of a ship instance (after modules)
    /// @param tokenId The id of the ship to retreive the travel data for
    /// @return speed Ship speed (after modules)
    /// @return fuelConsumption Ship fuel consumption (after modules)
    function getShipTravelData(uint tokenId)
        public virtual override view
        returns (
            uint16 speed,
            uint fuelConsumption
        )
    {
        Ship storage ship = ships[shipInstances[tokenId].name];
        speed = ship.base_speed + shipInstances[tokenId].speed;
        fuelConsumption = ship.base_fuelConsumption + shipInstances[tokenId].fuelConsumption;
    }


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
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        returns (
            uint tokenId, 
            uint inventory
        ) 
    {
        tokenId = _getNextTokenId();
        _mint(player, tokenId);
        _incrementTokenId();
        shipInstances[tokenId].name = shipsIndex[uint(faction)];
        shipInstances[tokenId].locked = locked;
        inventory = ships[shipInstances[tokenId].name].base_inventory;
    }


    /// @dev Mints a ship to an address
    /// @param to address of the owner of the ship
    /// @param name Unique ship name
    function __mintTo(address to, bytes32 name)  
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        onlyExisting(name) 
    {
        uint tokenId = _getNextTokenId();
        _mint(to, tokenId);
        _incrementTokenId();
        shipInstances[tokenId].name = name;
    }


    /// @dev Lock `next` and release 'prev'
    /// @param prev The tokenId of the previously locked (equipted) ship
    /// @param next The tokenId of the ship that replaces `prev` and thus is being locked
    function __lock(uint prev, uint next)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        shipInstances[prev].locked = false;
        shipInstances[next].locked = true;
    }


    /**
     * Private functions
     */
    /// @dev calculates the next token ID based on value of _currentTokenId
    /// @return uint for the next token ID
    function _getNextTokenId() private view returns (uint) {
        return _currentTokenId + 1;
    }


    /// @dev increments the value of _currentTokenId
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    
    /// @dev True if a ship with `name` exists
    /// @param name of the ship
    function _exists(bytes32 name) internal view returns (bool) 
    {
        return ships[name].base_speed != 0;
    }


    /// @dev Add or update ships
    /// @param name Ship name (unique)
    /// @param generic if true faction and subfaction are disregarded (any player can equipt)
    /// @param faction {Faction} (can only be equipted by this faction)
    /// @param subFaction {SubFaction} (pirate/bountyhunter)
    /// @param rarity Ship rarity {Rarity}
    /// @param stats modules, c02, base_speed, base_attack, base_health, base_defence, base_inventory
    function _setShip(bytes32 name, bool generic, Faction faction, SubFaction subFaction, Rarity rarity, ShipStatValues memory stats) 
        internal 
    {
        // Add ship
        if (!_exists(name))
        {
            shipsIndex.push(name);
        }

        // Set ship
        Ship storage ship = ships[name];
        ship.generic = generic;
        ship.faction = faction;
        ship.subFaction = subFaction;
        ship.rarity = rarity;
        ship.co2 = stats.co2;
        ship.modules = stats.modules;
        ship.base_speed = stats.speed;
        ship.base_attack = stats.attack;
        ship.base_health = stats.health;
        ship.base_defence = stats.defence;
        ship.base_inventory = stats.inventory;
        ship.base_fuelConsumption = stats.fuelConsumption;
    }


    /// @dev See {ERC721-_update}
    /// @param to address of the new owner of the ship
    /// @param tokenId the token id of the ship to transfer
    /// @param auth The address that is authorized to transfer the ship
    /// @return address of the new owner of the ship
    function _update(address to,uint tokenId,address auth) 
        internal virtual override 
        returns (address)
    {
        // Check if ship is locked
        if (shipInstances[tokenId].locked) 
        {
            revert ShipLocked(tokenId);
        }

        return super._update(to, tokenId, auth);
    }
}