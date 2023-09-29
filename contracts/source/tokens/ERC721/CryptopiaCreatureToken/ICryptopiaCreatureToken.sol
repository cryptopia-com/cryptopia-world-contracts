// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title ICryptopiaCreatureToken Token
/// @dev Non-fungible token (ERC721) 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICryptopiaCreatureToken {

    /// @dev Returns the amount of different creatures
    /// @return count The amount of different creatures
    function getCreatureCount() 
        external view 
        returns (uint);


    /// @dev Retreive a creature by name
    /// @param name Unique creature name
    /// @return fileHash hash of the 3d model
    /// @return rarity 0 = common, 1 = rare, 2 = legendary
    /// @return class CreatureClass used in competition 
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
        external view  
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
        );


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
        external view  
        returns (
            uint8 rarity,
            uint8 class,
            uint24 base_luck,
            uint24 base_speed,
            uint24 base_attack,
            uint24 base_health, 
            uint24 base_defence
        );


    /// @dev Retreive creature stats by name
    /// @param name Unique creature name
    /// @return rarity 0 = common, 1 = rare, 2 = legendary
    /// @return class 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @return strength Composed from luck, speed, attack and defence
    function getCreatureStrength(bytes32 name) 
        external view  
        returns (
            uint8 rarity,
            uint8 class,
            uint strength
        );

    
    /// @dev Retreive a rance of creatures
    /// @param skip Starting index
    /// @param take Amount of creatures
    /// @return name Creature name
    /// @return rarity 0 = common, 1 = rare, 2 = legendary
    /// @return class CreatureClass used in competition 
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
        external view  
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
        );


    /// @dev Add or update a creature
    /// @param names Creature name
    /// @param fileHashes sha256 hashe of the 3d object
    /// @param rarities 0 = common, 1 = rare, 2 = legendary
    /// @param classes CreatureClass used in compitition
    /// @param stats species, modules, arbitrary, base_xp, base_luck, base_charisma, base_speed, base_attack, base_health
    function setCreatures(bytes32[] memory names, bytes32[] memory fileHashes, uint8[] memory rarities, uint8[] memory classes, uint24[10][] memory stats) external;


    /// @dev Retreive an instance of a creature by `tokenId`
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
        external view  
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
        );

    
    /// @dev Mints a token to an address.
    /// @param to address of the future owner of the token
    /// @param creature name of the creature to mint
    /// @param sex 0 = female, 1 = male
    /// @return tokenId new token ID
    function mintTo(address to, bytes32 creature, uint8 sex) external returns (uint tokenId);

    
    /// @dev Mints a token to an address.
    /// @param to address of the future owner of the token
    /// @param creature name of the creature to mint
    /// @param sex 0 = female, 1 = male
    /// @param genes used if `_randomizeGenes` is false
    /// @return tokenId new token ID
    function mintTo(address to, bytes32 creature, uint8 sex, uint8 genes) external returns (uint tokenId);
}