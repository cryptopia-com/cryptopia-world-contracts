// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../CryptopiaERC721.sol";
import "./ICryptopiaCreatureToken.sol";

/// @title Cryptopia Creature Token
/// @dev Non-fungible token (ERC721)
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaCreatureToken is ICryptopiaCreatureToken, CryptopiaERC721 {
    
    struct Creature 
    {
        bytes32 fileHash;
        uint8 rarity;
        uint8 class;
        uint24 species;
        uint24 modules;
        uint24 arbitrary;
        uint24 base_xp;
        uint24 base_luck;
        uint24 base_charisma;
        uint24 base_speed;
        uint24 base_attack;
        uint24 base_health;
        uint24 base_defence;
    }

    struct CreatureInstance
    {
        bytes32 creature;
        uint8 sex; // 0 = female, 1 = male
        uint8 genes; // 0 - 5
        uint8 level; // Current level
        uint24 xp; // XP towards next level; base_xp * ((100 + XP_FACTOR) / XP_DENOMINATOR)**(level - 1)
        uint24 luck; // base_luck + (base_luck * (genes + random(0, 5)) / 100) + (luck * (STATS_FACTOR / STATS_DENOMINATOR) * (level - 1))
        uint24 charisma; // base_charisma + (base_charisma * (genes + random(0, 5)) / 100) + (charisma * (STATS_FACTOR / STATS_DENOMINATOR) * (level - 1))
        uint24 speed; // base_speed + (base_speed * (genes + random(0, 5)) / 100) + (speed * (STATS_FACTOR / STATS_DENOMINATOR) * (level - 1))
        uint24 attack; // base_attack + (base_attack * (genes + random(0, 5)) / 100) + (attack * (STATS_FACTOR / STATS_DENOMINATOR) * (level - 1))
        uint24 health; // base_health + (base_health * (genes + random(0, 5)) / 100) + (health * (STATS_FACTOR / STATS_DENOMINATOR) * (level - 1))
        uint24 defence; // base_defence + (base_defence * (genes + random(0, 5)) / 100) + (defence * (STATS_FACTOR / STATS_DENOMINATOR) * (level - 1))
    }


    /**
     * Roles
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    /**
     * Storage
     */
    uint public constant MAX_LEVEL = 50;
    uint public constant XP_FACTOR = 10;
    uint public constant XP_DENOMINATOR = 100;
    uint public constant STATS_FACTOR = 10;
    uint public constant STATS_DENOMINATOR = 100;

    uint private _currentTokenId;
    bytes32 private _currentRandomSeed;

    /// @dev creature name => Creature
    mapping(bytes32 => Creature) public creatures;
    bytes32[] private creaturesIndex;

    /// @dev tokenId => CreatureInstance
    mapping (uint => CreatureInstance) public creatureInstances;


    /**
     * Modifiers
     */
    /// @dev Requires that a creature with `name` exists
    /// @param name Creature's name
    modifier onlyExistingCreature(bytes32 name)
    {
        require(_exists(name), "Non-existing creature");
        _;
    }


    /**
     * Public functions
     */
    /// @dev Contract initializer sets shared base uri
    /// @param proxyAuthenticator Whitelist for easy trading
    /// @param initialContractURI Location to contract info
    /// @param initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    function initialize(
        address proxyAuthenticator, 
        string memory initialContractURI, 
        string memory initialBaseTokenURI) 
        public initializer 
    {
        __CryptopiaERC721_init(
            "Cryptopia Creatures", "CREATURE", proxyAuthenticator, initialContractURI, initialBaseTokenURI);
    }


    /// @dev Returns the amount of different creatures
    /// @return count The amount of different creatures
    function getCreatureCount() 
        public virtual override view 
        returns (uint)
    {
        return creaturesIndex.length;
    }


    /// @dev Retreive a creature by name
    /// @param name Unique creature name
    /// @return fileHash hash of the 3d model
    /// @return rarity 0 = common, 1 = rare, 2 = legendary
    /// @return class 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @return species family to which the creature belongs
    /// @return modules the amount of module slots
    /// @return base_xp the base xp of the creature
    /// @return base_luck the base amount of luck that the creature adds
    /// @return base_charisma the base amount of charisma that the creature adds
    /// @return base_speed the base speed of the creature
    /// @return base_attack the base attack power of the creature
    /// @return base_health the base health of the creature
    /// @return base_defence the base defence of the creature
    function getCreature(bytes32 name) 
        public virtual override view 
        returns (
            bytes32 fileHash,
            uint8 rarity,
            uint8 class,
            uint24 species,
            uint24 modules,
            uint24 base_xp,
            uint24 base_luck,
            uint24 base_charisma,
            uint24 base_speed,
            uint24 base_attack,
            uint24 base_health, 
            uint24 base_defence
        )
    {
        fileHash = creatures[name].fileHash;
        rarity = creatures[name].rarity;
        class = creatures[name].class;
        species = creatures[name].species;
        modules = creatures[name].modules;
        base_xp = creatures[name].base_xp;
        base_luck = creatures[name].base_luck;
        base_charisma = creatures[name].base_charisma;
        base_speed = creatures[name].base_speed;
        base_attack = creatures[name].base_attack;
        base_health = creatures[name].base_health;
        base_defence = creatures[name].base_defence;
    }


    /// @dev Retreive creature stats by name
    /// @param name Unique creature name
    /// @return rarity 0 = common, 1 = rare, 2 = legendary
    /// @return class 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @return base_luck the base amount of luck that the creature adds
    /// @return base_speed the base speed of the creature
    /// @return base_attack the base attack power of the creature
    /// @return base_health the base health of the creature
    /// @return base_defence the base defence of the creature
    function getCreatureStats(bytes32 name) 
        public virtual override view 
        returns (
            uint8 rarity,
            uint8 class,
            uint24 base_luck,
            uint24 base_speed,
            uint24 base_attack,
            uint24 base_health, 
            uint24 base_defence
        )
    {
        rarity = creatures[name].rarity;
        class = creatures[name].class;
        base_luck = creatures[name].base_luck;
        base_speed = creatures[name].base_speed;
        base_attack = creatures[name].base_attack;
        base_health = creatures[name].base_health;
        base_defence = creatures[name].base_defence;
    }


    /// @dev Retreive creature stats by name
    /// @param name Unique creature name
    /// @return rarity 0 = common, 1 = rare, 2 = legendary
    /// @return class 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @return strength Composed from luck, speed, attack and defence
    function getCreatureStrength(bytes32 name) 
        public virtual override view  
        returns (
            uint8 rarity,
            uint8 class,
            uint strength
        )
    {
        rarity = creatures[name].rarity;
        class = creatures[name].class;
        strength = creatures[name].base_luck + creatures[name].base_speed + creatures[name].base_attack + creatures[name].base_defence;
    }


    /// @dev Retreive a rance of creatures
    /// @param skip Starting index
    /// @param take Amount of creatures
    /// @return name Creature name
    /// @return rarity 0 = common, 1 = rare, 2 = legendary
    /// @return class 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @return species family to which the creature belongs
    /// @return modules the amount of module slots
    /// @return base_xp the base xp of the creature
    /// @return base_luck the base amount of luck that the creature adds
    /// @return base_charisma the base amount of charisma that the creature adds
    /// @return base_speed the base speed of the creature
    /// @return base_attack the base attack power of the creature
    /// @return base_health the base health of the creature
    /// @return base_defence the base defence of the creature
    function getCreatures(uint skip, uint take) 
        public virtual override view  
        returns (
            bytes32[] memory name,
            uint8[] memory rarity,
            uint8[] memory class,
            uint24[] memory species,
            uint24[] memory modules,
            uint24[] memory base_xp,
            uint24[] memory base_luck,
            uint24[] memory base_charisma,
            uint24[] memory base_speed,
            uint24[] memory base_attack,
            uint24[] memory base_health,
            uint24[] memory base_defence
        )
    {
        name = new bytes32[](take);
        rarity = new uint8[](take);
        class = new uint8[](take);
        species = new uint24[](take);
        modules = new uint24[](take);
        base_xp = new uint24[](take);
        base_luck = new uint24[](take);
        base_charisma = new uint24[](take);
        base_speed = new uint24[](take);
        base_attack = new uint24[](take);
        base_health = new uint24[](take);
        base_defence = new uint24[](take);

        uint index = skip;
        for (uint i = 0; i < take; i++)
        {
            name[i] = creaturesIndex[index];
            rarity[i] = creatures[name[i]].rarity;
            class[i] = creatures[name[i]].class;
            species[i] = creatures[name[i]].species;
            modules[i] = creatures[name[i]].modules;
            base_xp[i] = creatures[name[i]].base_xp;
            base_luck[i] = creatures[name[i]].base_luck;
            base_charisma[i] = creatures[name[i]].base_charisma;
            base_speed[i] = creatures[name[i]].base_speed;
            base_attack[i] = creatures[name[i]].base_attack;
            base_health[i] = creatures[name[i]].base_health;
            base_defence[i] = creatures[name[i]].base_defence;
            index++;
        }
    }


    /// @dev Add or update a creature
    /// @param names Creature name
    /// @param fileHashes sha256 hashe of the 3d object
    /// @param rarities 0 = common, 1 = rare, 2 = legendary
    /// @param classes 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @param stats species, modules, arbitrary, base_xp, base_luck, base_charisma, base_speed, base_attack, base_health
    function setCreatures(bytes32[] memory names, bytes32[] memory fileHashes, uint8[] memory rarities, uint8[] memory classes, uint24[10][] memory stats) 
        public virtual override 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < names.length; i++)
        {
            // Add creature
            if (!_exists(names[i]))
            {
                creaturesIndex.push(names[i]);
            }

            // Set creature
            creatures[names[i]].fileHash = fileHashes[i];
            creatures[names[i]].rarity = rarities[i];
            creatures[names[i]].class = classes[i];
            creatures[names[i]].species = stats[i][0];
            creatures[names[i]].modules = stats[i][1];
            creatures[names[i]].arbitrary = stats[i][2];
            creatures[names[i]].base_xp = stats[i][3];
            creatures[names[i]].base_luck = stats[i][4];
            creatures[names[i]].base_charisma = stats[i][5];
            creatures[names[i]].base_speed = stats[i][6];
            creatures[names[i]].base_attack = stats[i][7];
            creatures[names[i]].base_health = stats[i][8];
            creatures[names[i]].base_defence = stats[i][9];
        }
    }


    /// @dev Retreive an instance of a creature by `_tokenId`
    /// @param tokenId the token ID of the creature instance
    /// @return creature unique name of the creature
    /// @return sex 0 = female, 1 = male
    /// @return genes 0 - 5 gene quality
    /// @return level current level
    /// @return xp towards next level; base_xp * ((100 + XP_FACTOR) / XP_DENOMINATOR)**(level - 1)
    /// @return luck base_luck + (base_luck * (genes + random(0, 5)) / 100) + (luck * (STATS_FACTOR / STATS_DENOMINATOR) * (level - 1))
    /// @return charisma base_charisma + (base_charisma * (genes + random(0, 5)) / 100) + (charisma * (STATS_FACTOR / STATS_DENOMINATOR) * (level - 1))
    /// @return speed base_speed + (base_speed * (genes + random(0, 5)) / 100) + (speed * (STATS_FACTOR / STATS_DENOMINATOR) * (level - 1))
    /// @return attack base_attack + (base_attack * (genes + random(0, 5)) / 100) + (attack * (STATS_FACTOR / STATS_DENOMINATOR) * (level - 1))
    /// @return health base_health + (base_health * (genes + random(0, 5)) / 100) + (health * (STATS_FACTOR / STATS_DENOMINATOR) * (level - 1))
    /// @return defence base_defence + (base_defence * (genes + random(0, 5)) / 100) + (defence * (STATS_FACTOR / STATS_DENOMINATOR) * (level - 1))
    function getCreatureInstance(uint tokenId) 
        public virtual override view 
        returns (
            bytes32 creature,
            uint8 sex,
            uint8 genes,
            uint8 level,
            uint24 xp,
            uint24 luck,
            uint24 charisma,
            uint24 speed,
            uint24 attack,
            uint24 health,
            uint24 defence
        )
    {
        creature = creatureInstances[tokenId].creature;
        sex = creatureInstances[tokenId].sex;
        genes = creatureInstances[tokenId].genes;
        level = creatureInstances[tokenId].level;
        xp = creatureInstances[tokenId].xp;
        luck = creatureInstances[tokenId].luck;
        charisma = creatureInstances[tokenId].charisma;
        speed = creatureInstances[tokenId].speed;
        attack = creatureInstances[tokenId].attack;
        health = creatureInstances[tokenId].health;
        defence = creatureInstances[tokenId].defence;
    }


    /// @dev Mints a token to an address.
    /// @param to address of the future owner of the token
    /// @param creature name of the creature to mint
    /// @param sex 0 = female, 1 = male
    /// @return tokenId new token ID
    function mintTo(address to, bytes32 creature, uint8 sex)  
        public override 
        onlyRole(MINTER_ROLE) 
        onlyExistingCreature(creature) 
        returns (uint tokenId) 
    {
        tokenId = _getNextTokenId();
        _mint(to, tokenId);
        _incrementTokenId();

        bytes32 random = _random();
        Creature storage _creature = creatures[creature];
        creatureInstances[tokenId].creature = creature;
        creatureInstances[tokenId].sex = sex; // 0 = female, 1 = male
        creatureInstances[tokenId].genes = uint8(_randomAt(random, 0, 6)); // between 0 and 5
        creatureInstances[tokenId].luck = _creature.base_luck + (_creature.base_luck * (creatureInstances[tokenId].genes + uint8(_randomAt(random, 1, 6))) / 100);
        creatureInstances[tokenId].charisma = _creature.base_charisma + (_creature.base_charisma * (creatureInstances[tokenId].genes + uint8(_randomAt(random, 2, 6))) / 100);
        creatureInstances[tokenId].speed = _creature.base_speed + (_creature.base_speed * (creatureInstances[tokenId].genes + uint8(_randomAt(random, 3, 6))) / 100);
        creatureInstances[tokenId].attack = _creature.base_attack + (_creature.base_attack * (creatureInstances[tokenId].genes + uint8(_randomAt(random, 4, 6))) / 100);
        creatureInstances[tokenId].health = _creature.base_health + (_creature.base_health * (creatureInstances[tokenId].genes + uint8(_randomAt(random, 5, 6))) / 100);
        return tokenId;
    }


    /// @dev Mints a token to an address
    /// @param to address of the future owner of the token
    /// @param creature name of the creature to mint
    /// @param sex 0 = female, 1 = male
    /// @param genes used if `_randomizeGenes` is false
    /// @return tokenId new token ID
    function mintTo(address to, bytes32 creature, uint8 sex, uint8 genes) 
        public override 
        onlyRole(MINTER_ROLE) 
        onlyExistingCreature(creature) 
        returns (uint tokenId) 
    {
        // Validate genes
        require(genes <= 5, "Invalid gene input");
        
        tokenId = _getNextTokenId();
        _mint(to, tokenId);
        _incrementTokenId();

        bytes32 random = _random();
        Creature storage _creature = creatures[creature];
        creatureInstances[tokenId].creature = creature;
        creatureInstances[tokenId].sex = sex; // 0 = female, 1 = male
        creatureInstances[tokenId].genes = genes; // between 0 and 5
        creatureInstances[tokenId].luck = _creature.base_luck + (_creature.base_luck * (creatureInstances[tokenId].genes + uint8(_randomAt(random, 1, 6))) / 100);
        creatureInstances[tokenId].charisma = _creature.base_charisma + (_creature.base_charisma * (creatureInstances[tokenId].genes + uint8(_randomAt(random, 2, 6))) / 100);
        creatureInstances[tokenId].speed = _creature.base_speed + (_creature.base_speed * (creatureInstances[tokenId].genes + uint8(_randomAt(random, 3, 6))) / 100);
        creatureInstances[tokenId].attack = _creature.base_attack + (_creature.base_attack * (creatureInstances[tokenId].genes + uint8(_randomAt(random, 4, 6))) / 100);
        creatureInstances[tokenId].health = _creature.base_health + (_creature.base_health * (creatureInstances[tokenId].genes + uint8(_randomAt(random, 5, 6))) / 100);
        return tokenId;
    }


    /**
     * Private functions
     */
    /// @dev True if a creature with `name` exists
    /// @param name name of the creature
    function _exists(bytes32 name) internal view returns (bool) 
    {
        return creatures[name].fileHash != 0;
    }


    /// @dev calculates the next token ID based on value of currentTokenId
    /// @return uint for the next token ID
    function _getNextTokenId() private view returns (uint) {
        return _currentTokenId + 1;
    }


    /// @dev increments the value of currentTokenId
    function _incrementTokenId() private {
        _currentTokenId++;
    }


    /// @dev Pseudo-random hash generator
    /// @return bytes32 Random hash
    function _random() internal returns (bytes32) {
        _currentRandomSeed = keccak256(
            abi.encodePacked(blockhash(block.number - 1), 
            _msgSender(), 
            _currentRandomSeed));
        return _currentRandomSeed;
    }


    /// @dev Get a number from a random `seed` at `index`
    /// @param _hash Randomly generated hash 
    /// @param _index Used as salt
    function _randomAt(bytes32 _hash, uint _index, uint _inverseBasePoint) private pure returns(uint) {
        return uint(keccak256(abi.encodePacked(_hash, _index))) % _inverseBasePoint;
    }
}