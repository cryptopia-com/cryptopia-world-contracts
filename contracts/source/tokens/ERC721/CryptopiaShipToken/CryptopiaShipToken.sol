// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../../game/players/CryptopiaPlayerRegister/ICryptopiaPlayerRegister.sol";
import "../../../game/GameEnums.sol";
import "../CryptopiaERC721.sol";
import "./ICryptopiaShipToken.sol";

/// @title Cryptopia Ship Token
/// @dev Non-fungible token (ERC721)
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaShipToken is ICryptopiaShipToken, CryptopiaERC721 {
    
    struct Ship
    {
        bool generic;
        GameEnums.Faction faction;
        GameEnums.SubFaction subFaction;
        GameEnums.Rarity rarity;
        uint24 modules;
        uint24 arbitrary;
        uint24 base_speed;
        uint24 base_attack;
        uint24 base_health;
        uint24 base_defence;
        uint base_inventory;
    }

    struct ShipInstance
    {
        bytes32 name;
        bool locked;
        uint24 speed;
        uint24 attack;
        uint24 health;
        uint24 defence;
        uint inventory;
    }


    /**
     * Storage
     */
    uint private _currentTokenId; 

    /// @dev name => Ship
    mapping(bytes32 => Ship) public ships;
    bytes32[] private shipsIndex;

    /// @dev tokenId => ShipInstance
    mapping (uint => ShipInstance) public shipInstances;


    /**
     * Roles
     */
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    /**
     * Modifiers
     */
    /// @dev Requires that an item with `name` exists
    /// @param name Unique token name
    modifier onlyExisting(bytes32 name)
    {
        require(_exists(name), "Non-existing token");
        _;
    }


    /**
     * Public functions
     */
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
        uint[7] memory stats = [uint(1), 0, 25, 15, 100, 100, 12_000_000_000_000_000_000_000];
        _setShip("Whitewake", false, GameEnums.Faction.Eco, GameEnums.SubFaction.None, GameEnums.Rarity.Common, stats);
        _setShip("Polaris", false, GameEnums.Faction.Tech, GameEnums.SubFaction.None, GameEnums.Rarity.Common, stats);
        _setShip("Kingfisher", false, GameEnums.Faction.Industrial, GameEnums.SubFaction.None, GameEnums.Rarity.Common, stats);
        _setShip("Socrates", false, GameEnums.Faction.Traditional, GameEnums.SubFaction.None, GameEnums.Rarity.Common, stats);
    }


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
    function getShips(uint skip, uint take) 
        public override view 
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
        )
    {
        name = new bytes32[](take);
        generic = new bool[](take);
        faction = new GameEnums.Faction[](take);
        subFaction = new GameEnums.SubFaction[](take);
        rarity = new GameEnums.Rarity[](take);
        modules = new uint24[](take);
        base_speed = new uint24[](take);
        base_attack = new uint24[](take);
        base_health = new uint24[](take);
        base_defence = new uint24[](take);
        base_inventory = new uint[](take);

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
    function getShip(bytes32 name) 
        public virtual override view 
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
        GameEnums.Faction[] memory 
        faction, GameEnums.SubFaction[] 
        memory subFaction, 
        GameEnums.Rarity[] memory rarity, 
        uint[7][] memory stats) 
        public virtual override 
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
    function getShipInstance(uint tokenId) 
        public virtual override view 
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
            GameEnums.Faction[] memory faction,
            GameEnums.SubFaction[] memory subFaction,
            GameEnums.Rarity[] memory rarity,
            uint24[] memory modules,
            uint24[] memory speed,
            uint24[] memory attack,
            uint24[] memory health,
            uint24[] memory defence,
            uint[] memory inventory
        )
    {
        name = new bytes32[](tokenIds.length);
        locked = new bool[](tokenIds.length);
        generic = new bool[](tokenIds.length);
        faction = new GameEnums.Faction[](tokenIds.length);
        subFaction = new GameEnums.SubFaction[](tokenIds.length);
        rarity = new GameEnums.Rarity[](tokenIds.length);
        modules = new uint24[](tokenIds.length);
        speed = new uint24[](tokenIds.length);
        attack = new uint24[](tokenIds.length);
        health = new uint24[](tokenIds.length);
        defence = new uint24[](tokenIds.length);
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
            GameEnums.Faction faction,
            GameEnums.SubFaction subFaction,
            uint inventory
        )
    {
        bytes32 name = shipInstances[tokenId].name;
        locked = shipInstances[tokenId].locked;
        generic = ships[name].generic;
        faction = ships[name].faction;
        subFaction = ships[name].subFaction;
        inventory = ships[name].base_inventory + shipInstances[tokenId].inventory;
    }


    /// @dev Mints a starter ship to a player
    /// @param player address of the player
    /// @param faction player's faction
    /// @param locked If true the ship is equipted and can't be transferred
    /// @param tokenId the token id of the minted ship
    /// @param inventory the ship inventory space
    function mintStarterShip(address player, GameEnums.Faction faction, bool locked)  
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
    function mintTo(address to, bytes32 name)  
        public virtual override 
        onlyRole(MINTER_ROLE) 
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
    function lock(uint prev, uint next)
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
    /// @param stats modules, arbitrary, base_speed, base_attack, base_health, base_defence, base_inventory
    function _setShip(bytes32 name, bool generic, GameEnums.Faction faction, GameEnums.SubFaction subFaction, GameEnums.Rarity rarity, uint[7] memory stats) 
        internal 
    {
        // Add ship
        if (!_exists(name))
        {
            shipsIndex.push(name);
        }

        // Set ship
        ships[name].generic = generic;
        ships[name].faction = faction;
        ships[name].subFaction = subFaction;
        ships[name].rarity = rarity;
        ships[name].modules = uint24(stats[0]);
        ships[name].arbitrary = uint24(stats[1]);
        ships[name].base_speed = uint24(stats[2]);
        ships[name].base_attack = uint24(stats[3]);
        ships[name].base_health = uint24(stats[4]);
        ships[name].base_defence = uint24(stats[5]);
        ships[name].base_inventory = stats[6];
    }


    /// @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
    /// used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
    ///
    /// Calling conditions:
    ///
    /// - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
    /// - When `from` is zero, the tokens will be minted for `to`.
    /// - When `to` is zero, ``from``'s tokens will be burned.
    /// - `from` and `to` are never both zero.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize) 
        internal virtual override  
    {
        require(
            !shipInstances[tokenId].locked, 
            "CryptopiaShipToken: Unable to transfer a locked ship"
        );

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}