// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../game/players/IPlayerRegister.sol";
import "../../ships/IShips.sol";  
import "../../ships/IShipSkins.sol";  
import "../../ships/types/ShipDataTypes.sol";
import "../../ships/errors/ShipErrors.sol";  
import "../../ships/errors/ShipSkinErrors.sol";  
import "../CryptopiaERC721.sol";

/// @title Cryptopia Ship Token Contract
/// @notice Manages the creation, attributes, and interactions of ship tokens in Cryptopia.
/// This contract handles everything from ship minting, updating ship attributes, 
/// to managing different ship types and their specific characteristics like speed, 
/// health, and attack power. It supports various ship classes, aligns ships with 
/// game factions, and manages the special variants like pirate ships.
/// @dev Extends CryptopiaERC721, integrating ERC721 functionalities with game-specific mechanics.
/// It maintains a comprehensive dataset of ships through mappings, enabling intricate gameplay
/// strategies and in-game economics. The contract includes mechanisms for both the creation of 
/// new ship tokens and the dynamic modification of existing ships, reflecting the evolving nature 
/// of the in-game naval fleet.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaShipToken is CryptopiaERC721, IShips {

    /// @dev Ship in Cryptopia
    struct ShipData
    {
        /// @dev Index within the shipsIndex array
        uint index;

        /// @dev Indicates if the ship is generic, allowing it to be equipped by any player regardless of faction
        bool generic;

        /// @dev Faction type (Eco, Tech, Traditional, Industrial) 
        Faction faction;

        /// @dev SubFaction type (None/Pirate/BountyHunter) 
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


    /**
     * Storage
     */
    uint private _currentTokenId; 

    /// @dev name => ShipData
    mapping(bytes32 => ShipData) public ships;
    bytes32[] internal shipsIndex;

    /// @dev tokenId => ShipInstance
    mapping (uint => ShipInstance) public shipInstances;

    /// @dev Faction => ship name
    mapping (Faction => bytes32) public starterShips;

    // Refs
    address public skinContract;


    /**
     * Events
     */
    /// @dev Emitted when the ship with `tokenId` took `damage`
    /// @param ship The token id of the ship that took damage
    /// @param damage The amount of damage that was taken
    event ShipDamage(uint indexed ship, uint16 damage);

    /// @dev Update `ship` to it's pirate version
    /// @param ship The id of the ship to turn into a pirate
    event ShipTurnedPirate(uint indexed ship);

    /// @dev Emitted when a skin is applied to a ship
    /// @param ship The token id of the ship that the skin was applied to
    /// @param skinTokenId The token id of the skin that was applied
    /// @param skinIndex The index of the skin that was applied
    /// @param skinName The name of the skin that was applied
    event ShipSkinApplied(uint indexed ship, uint skinTokenId, uint16 skinIndex, bytes32 skinName);


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
    /// @param _name Unique token name
    modifier onlyExisting(bytes32 _name)
    {
        if (!_exists(_name)) 
        {
            revert ShipNotFound(_name);
        }
        _;
    }


    /// @dev Contract initializer sets shared base uri
    /// @param _authenticator Whitelist
    /// @param initialContractURI Location to contract info
    /// @param initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    function initialize(
        address _authenticator, 
        string memory initialContractURI, 
        string memory initialBaseTokenURI,
        address _skinContract) 
        public initializer 
    {
        __CryptopiaERC721_init(
            "Cryptopia Ships", "SHIP", _authenticator, initialContractURI, initialBaseTokenURI);

        // Set refs
        skinContract = _skinContract;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Ensure starter ships are created
        _createStarterShips();
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
    /// @param _name Ship name (unique)
    /// @return data a single ship 
    function getShip(bytes32 _name) 
        public virtual override view 
        returns (Ship memory data)
    {
        data = _getShip(_name);
    }


    /// @dev Retreive a rance of ships
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return ships_ Ship[] range of ships
    function getShips(uint skip, uint take)
        public virtual override view 
        returns (Ship[] memory ships_)
    {
        uint length = take;
        if (shipsIndex.length < skip + take) 
        {
            length = shipsIndex.length - skip;
        }

        ships_ = new Ship[](length);
        for (uint i = 0; i < length; i++)
        {
            ships_[i] = _getShip(shipsIndex[skip + i]);
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
        ShipData storage data = ships[shipInstances[tokenId].name];
        equipData = ShipEquipData({
            locked: shipInstances[tokenId].locked,
            generic: data.generic,
            faction: data.faction,
            subFaction: data.subFaction,
            inventory: data.base_inventory + shipInstances[tokenId].inventory
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


    /// @dev Apply a skin to a ship
    /// @notice The skin is burned and applied to the ship
    /// @param tokenId The id of the ship to apply the skin to
    /// @param skinTokenId The id of the skin to apply
    function applySkin(uint tokenId, uint skinTokenId)
        public virtual override 
    {
        address sender = _msgSender();

        // Check if ship is owned by the sender
        if (ownerOf(tokenId) != sender) 
        {
            revert ShipNotOwned(tokenId, sender);
        }

        // Get skin data
        ShipInstance memory ship = shipInstances[tokenId];
        ShipSkinInstance memory skin = IShipSkins(skinContract)
            .getSkinInstance(skinTokenId);

        // Check if skin is owned by the sender
        if (skin.owner != sender) 
        {
            revert ShipSkinNotOwned(skinTokenId, sender);
        }

        // Check if skin is applicable to ship
        if (skin.ship != ship.name) 
        {
            revert ShipSkinNotApplicable(skinTokenId, skin.name, tokenId, ship.name);
        }

        // Burn skin
        IShipSkins(skinContract).__burn(skinTokenId);

        // Apply skin
        shipInstances[tokenId].skinIndex = skin.index;

        // Emit
        emit ShipSkinApplied(tokenId, skinTokenId, skin.index, skin.name);
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
            uint inventory) 
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
    /// @param _name Unique ship name
    function __mintTo(address to, bytes32 _name)  
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        onlyExisting(_name) 
    {
        uint tokenId = _getNextTokenId();
        _mint(to, tokenId);
        _incrementTokenId();
        shipInstances[tokenId].name = _name;
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
    function _getNextTokenId() 
        private view 
        returns (uint) 
    {
        return _currentTokenId + 1;
    }


    /// @dev increments the value of _currentTokenId
    function _incrementTokenId() 
        private 
    {
        _currentTokenId++;
    }

    
    /// @dev True if a ship with `name` exists
    /// @param _name of the ship
    function _exists(bytes32 _name) 
        internal view 
        returns (bool) 
    {
        return ships[_name].base_speed != 0;
    }


    /// @dev Add or update a ship
    /// @param ship Ship data
    function _setShip(Ship memory ship) 
        internal 
    {
        assert(
            (ship.subFaction == SubFaction.None && ship.pirateVersion != bytes32(0)) || // Requires pirate version
            (ship.subFaction == SubFaction.Pirate && ship.pirateVersion == bytes32(0)) || // Is already pirate version
            (ship.subFaction == SubFaction.BountyHunter && ship.pirateVersion == bytes32(0)) // Can never turn pirate
        );

        // Add ship
        if (!_exists(ship.name))
        {
            ships[ship.name].index = shipsIndex.length;
            shipsIndex.push(ship.name);
        }

        // Set ship
        ShipData storage data = ships[ship.name];
        data.generic = ship.generic;
        data.faction = ship.faction;
        data.subFaction = ship.subFaction;
        data.rarity = ship.rarity;
        data.co2 = ship.co2;
        data.modules = ship.modules;
        data.base_speed = ship.base_speed;
        data.base_attack = ship.base_attack;
        data.base_health = ship.base_health;
        data.base_defence = ship.base_defence;
        data.base_inventory = ship.base_inventory;
        data.base_fuelConsumption = ship.base_fuelConsumption;
        data.pirateVersion = ship.pirateVersion;
    }


    /// @dev Retreive a ship by name
    /// @param _name Ship name (unique)
    /// @return ship a single ship
    function _getShip(bytes32 _name) 
        internal virtual view 
        returns (Ship memory ship)
    {
        ShipData memory data = ships[_name];
        ship = Ship({
            name: _name,
            generic: data.generic,
            rarity: data.rarity,
            faction: data.faction,
            subFaction: data.subFaction,
            co2: data.co2,
            modules: data.modules,
            base_speed: data.base_speed,
            base_attack: data.base_attack,
            base_health: data.base_health,
            base_defence: data.base_defence,
            base_inventory: data.base_inventory,
            base_fuelConsumption: data.base_fuelConsumption,
            pirateVersion: data.pirateVersion
        });
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
    

    /// @dev Create starter ships
    /// @notice Wihtout starter ships the game can't be played
    function _createStarterShips() 
        internal 
    {
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
}