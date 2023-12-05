// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../../../game/players/IPlayerRegister.sol";
import "../../ships/IShips.sol";  
import "../../ships/types/ShipDataTypes.sol";
import "../../ships/errors/ShipErrors.sol";  
import "../CryptopiaERC721.sol";

/// @title Cryptopia Ship Token
/// @dev Non-fungible token (ERC721)
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaShipToken is CryptopiaERC721, IShips {

    /**
     * Storage
     */
    uint private _currentTokenId; 

    /// @dev name => Ship
    mapping(bytes32 => Ship) private ships;
    bytes32[] private shipsIndex;

    /// @dev tokenId => ShipInstance
    mapping (uint => ShipInstance) private shipInstances;

    /// @dev Faction => ship name
    mapping (Faction => bytes32) private starterShips;


    /**
     * Events
     */
    /// @dev Emitted when the ship with `tokenId` took `damage`
    /// @param tokenId The id of the ship that took damage
    /// @param damage The amount of damage that was taken
    event ShipDamage(uint indexed tokenId, uint16 damage);

    /// @dev Update `ship` to it's pirate version
    /// @param ship The id of the ship to turn into a pirate
    event ShipTurnedPirate(uint indexed ship);


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

        // Shared base 
        Ship memory data = Ship({
            name: bytes32("Raptor"),
            generic: false,
            rarity: Rarity.Common,
            faction: Faction.Eco,
            subFaction: SubFaction.Pirate,
            co2: 0,
            modules: 1,
            base_speed: 25,
            base_attack: 15,
            base_health: 250,
            base_defence: 100,
            base_inventory: 12_000_000_000_000_000_000_000,
            base_fuelConsumption: 1_000_000_000_000_000_000,
            pirateVersion: bytes32(0)
        }); 


        // Add Eco starter ships
        _setShip(data);

        data.name = bytes32("Whitewake");
        data.subFaction = SubFaction.None;
        data.pirateVersion = bytes32("Raptor");
        _setShip(data);


        // Add Tech starter ships
        data.name = bytes32("Hammerhead");
        data.co2 = 25;
        data.faction = Faction.Tech;
        data.subFaction = SubFaction.Pirate;
        data.pirateVersion = bytes32(0);
        _setShip(data);

        data.name = bytes32("Polaris");
        data.subFaction = SubFaction.None;
        data.pirateVersion = bytes32("Hammerhead");
        _setShip(data);


        // Add Traditional starter ships
        data.name = bytes32("Yangfang");
        data.faction = Faction.Traditional;
        data.subFaction = SubFaction.Pirate;
        data.pirateVersion = bytes32(0);
        _setShip(data);

        data.name = bytes32("Socrates");
        data.subFaction = SubFaction.None;
        data.pirateVersion = bytes32("Yangfang");
        _setShip(data);


        // Add Industrial starter ships
        data.name = bytes32("Orca");
        data.co2 = 50;
        data.faction = Faction.Industrial;
        data.subFaction = SubFaction.Pirate;
        data.pirateVersion = bytes32(0);
        _setShip(data);

        data.name = bytes32("Kingfisher");
        data.subFaction = SubFaction.None;
        data.pirateVersion = bytes32("Orca");
        _setShip(data); 


        // Set starter ships
        starterShips[Faction.Eco] = "Whitewake";
        starterShips[Faction.Tech] = "Polaris";
        starterShips[Faction.Traditional] = "Socrates";
        starterShips[Faction.Industrial] = "Kingfisher";
    }


    /**
     * Admin functions
     */
    /// @dev Add or update ships
    /// @param data Ship data
    function setShips(Ship[] memory data) 
        public virtual  
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < data.length; i++)
        {
            _setShip(data[i]);
        }
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


    /// @dev Retreive a ships by name
    /// @param name Ship name (unique)
    /// @return data a single ship 
    function getShip(bytes32 name) 
        public virtual override view 
        returns (Ship memory data)
    {
        data = ships[name];
    }


    /// @dev Retreive a rance of ships
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return data Ship[] range of ship templates
    function getShips(uint skip, uint take)
        public virtual override view 
        returns (Ship[] memory data)
    {
        uint length = take;
        if (length > shipsIndex.length - skip) {
            length = shipsIndex.length - skip;
        }

        data = new Ship[](length);
        for (uint i = 0; i < length; i++)
        {
            data[i] = ships[shipsIndex[i]];
        }
    }


    /// @dev Retreive a ships by token id
    /// @param tokenId The id of the ship to retreive
    /// @return instance a single ship instance
    function getShipInstance(uint tokenId) 
        public virtual override view 
        returns (ShipInstance memory instance)
    {
        instance = shipInstances[tokenId];
    }


    /// @dev Retreive ships by token ids
    /// @param tokenIds The ids of the ships to retreive
    /// @return instances a range of ship instances
    function getShipInstances(uint[] memory tokenIds) 
        public virtual override view 
        returns (ShipInstance[] memory instances)
    {
        instances = new ShipInstance[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++)
        {
            instances[i] = shipInstances[tokenIds[i]];

        }
    }


    /// @dev Retrieve equipt data for a ship instance
    /// @param tokenId The id of the ship to retreive the inventory data for
    /// @return equipData Ship equip data
    function getShipEquipData(uint tokenId)
        public virtual override view  
        returns (ShipEquipData memory equipData)
    {
        Ship storage ship = ships[shipInstances[tokenId].name];
        equipData = ShipEquipData({
            locked: shipInstances[tokenId].locked,
            generic: ship.generic,
            faction: ship.faction,
            subFaction: ship.subFaction,
            inventory: ship.base_inventory + shipInstances[tokenId].inventory
        });
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
    /// @return travelData Ship travel data (after modules)
    function getShipTravelData(uint tokenId)
        external view 
        returns (ShipTravelData memory travelData)
    {
        return ShipTravelData({
            speed: ships[shipInstances[tokenId].name].base_speed + shipInstances[tokenId].speed,
            fuelConsumption: ships[shipInstances[tokenId].name].base_fuelConsumption + shipInstances[tokenId].fuelConsumption
        });
    }


    /// @dev Retrieve the travel data of a ship instance (after modules)
    /// @param tokenIds The ids of the ships to retreive the travel data for
    /// @return travelData1 The travel data of ship 1 (after modules)
    /// @return travelData2 The travel data of ship 2 (after modules)
    function getShipTravelData(TokenPair memory tokenIds)
        public virtual override view 
        returns (
            ShipTravelData memory travelData1, 
            ShipTravelData memory travelData2
        )
    {
        travelData1 = ShipTravelData({
            speed: ships[shipInstances[tokenIds.tokenId1].name].base_speed + shipInstances[tokenIds.tokenId1].speed,
            fuelConsumption: ships[shipInstances[tokenIds.tokenId1].name].base_fuelConsumption + shipInstances[tokenIds.tokenId1].fuelConsumption
        });

        travelData2 = ShipTravelData({
            speed: ships[shipInstances[tokenIds.tokenId2].name].base_speed + shipInstances[tokenIds.tokenId2].speed,
            fuelConsumption: ships[shipInstances[tokenIds.tokenId2].name].base_fuelConsumption + shipInstances[tokenIds.tokenId2].fuelConsumption
        });
    }


    /// @dev Retrieve the battle data of a ship instance (after modules)
    /// @param tokenId The id of the ship to retreive the battle data for
    /// @return battleData Ship battle data (after modules)
    function getShipBattleData(uint tokenId) 
        public virtual override view
        returns (ShipBattleData memory battleData)
    {
        battleData = ShipBattleData({
            damage: shipInstances[tokenId].damage,
            attack: ships[shipInstances[tokenId].name].base_attack + shipInstances[tokenId].attack,
            health: ships[shipInstances[tokenId].name].base_health + shipInstances[tokenId].health,
            defence: ships[shipInstances[tokenId].name].base_defence + shipInstances[tokenId].defence,
            tileSafetyInverse: ships[shipInstances[tokenId].name].subFaction == SubFaction.Pirate
        });
    }


    /// @dev Retrieve the battle data of a ship instance (after modules)
    /// @param tokenIds The ids of the ships to retreive the battle data for
    /// @return battleData1 The battle data of ship 1
    /// @return battleData2 The battle data of ship 2
    function getShipBattleData(TokenPair memory tokenIds)
        external view 
        returns (
            ShipBattleData memory battleData1,
            ShipBattleData memory battleData2 
        )
    {
        battleData1 = ShipBattleData({
            damage: shipInstances[tokenIds.tokenId1].damage,
            attack: ships[shipInstances[tokenIds.tokenId1].name].base_attack + shipInstances[tokenIds.tokenId1].attack,
            health: ships[shipInstances[tokenIds.tokenId1].name].base_health + shipInstances[tokenIds.tokenId1].health,
            defence: ships[shipInstances[tokenIds.tokenId1].name].base_defence + shipInstances[tokenIds.tokenId1].defence,
            tileSafetyInverse: ships[shipInstances[tokenIds.tokenId1].name].subFaction == SubFaction.Pirate
        });

        battleData2 = ShipBattleData({
            damage: shipInstances[tokenIds.tokenId2].damage,
            attack: ships[shipInstances[tokenIds.tokenId2].name].base_attack + shipInstances[tokenIds.tokenId2].attack,
            health: ships[shipInstances[tokenIds.tokenId2].name].base_health + shipInstances[tokenIds.tokenId2].health,
            defence: ships[shipInstances[tokenIds.tokenId2].name].base_defence + shipInstances[tokenIds.tokenId2].defence,
            tileSafetyInverse: ships[shipInstances[tokenIds.tokenId2].name].subFaction == SubFaction.Pirate
        });
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
        shipInstances[tokenId].name = starterShips[faction];
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


    /// @dev Apply damage to a ship
    /// @param ships_ The ids of the ships to apply damage to
    /// @param damage1 The amount of damage to apply to ship 1
    /// @param damage2 The amount of damage to apply to ship 2
    function __applyDamage(TokenPair memory ships_, uint16 damage1, uint16 damage2)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        shipInstances[ships_.tokenId1].damage += damage1;
        shipInstances[ships_.tokenId2].damage += damage2;

        // Emit 
        emit ShipDamage(ships_.tokenId1, damage1);
        emit ShipDamage(ships_.tokenId2, damage2);
    }


    /// @dev Update `ship` to it's pirate version
    /// @param ship The id of the ship to turn into a pirate
    function __turnPirate(uint ship)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        if (!_exists(ships[shipInstances[ship].name].pirateVersion)) 
        {
            revert ShipNotFound(shipInstances[ship].name);
        }

        shipInstances[ship].name = ships[shipInstances[ship].name].pirateVersion;

        // Emit
        emit ShipTurnedPirate(ship);
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
    /// @param data Ship data
    function _setShip(Ship memory data) 
        internal 
    {
        assert(
            (data.subFaction == SubFaction.None && data.pirateVersion != bytes32(0)) || // Requires pirate version
            (data.subFaction == SubFaction.Pirate && data.pirateVersion == bytes32(0)) || // Is already pirate version
            (data.subFaction == SubFaction.BountyHunter && data.pirateVersion == bytes32(0)) // Can never turn pirate
        );

        // Add ship
        if (!_exists(data.name))
        {
            shipsIndex.push(data.name);
        }

        // Set ship
        ships[data.name] = data;
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