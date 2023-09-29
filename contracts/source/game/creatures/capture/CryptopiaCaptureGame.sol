// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

import "../../GameEnums.sol";
import "../../map/CryptopiaMap/ICryptopiaMap.sol";
import "../../../tokens/ERC20/retriever/TokenRetriever.sol";
import "../../../tokens/ERC721/CryptopiaCaptureToken/ICryptopiaCaptureToken.sol";
import "../../../tokens/ERC721/CryptopiaCreatureToken/ICryptopiaCreatureToken.sol";

/// @title Cryptopia Creature Token Capture Factory 
/// @dev Non-fungible token (ERC721) factory that is used for capturing creatures
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaCaptureGame is OwnableUpgradeable, TokenRetriever {

    /**
     * Storage
     */
    uint public constant INVERSE_BASIS_POINT = 10_000; 
    uint public constant INVERSE_BASIS_POINT_SCALER = 100; 

    uint public constant RARITY_SCORE_COMMON = 200;
    uint public constant RARITY_SCORE_RARE = 100000;
    uint public constant RARITY_SCORE_LEGENDARY = 5000000;
    uint public constant RARITY_SCORE_MASTER = 100000000;

    uint public constant RARITY_MULTIPLIER_COMMON = 1;
    uint public constant RARITY_MULTIPLIER_RARE = 100;
    uint public constant RARITY_MULTIPLIER_LEGENDARY = 1000;
    uint public constant RARITY_MULTIPLIER_MASTER = 10000;

    uint public constant DEFICATED_CLASS_MULTIPLIER = 2;

    // State
    address public map;
    address public creatureToken;
    address public captureToken;
    bytes32 private _currentRandomSeed;


    /**
     * Events
     */
    /// @dev Emitted when a capture action succeeded (player wins)
    /// @param player The player address
    /// @param creature The name of the creature 
    /// @param creatureTokenId The tokenId of the creature 
    /// @param captureTokenId The capture token used to capture the creature with
    event CreatureCaptured(address indexed player, bytes32 creature, uint indexed creatureTokenId,  uint captureTokenId);


    /// @dev Emitted when a capture action failed (creature wins)
    /// @param player The player address
    /// @param creature The name of the creature 
    /// @param captureTokenId The capture token used to try and capture the creature with
    event CreatureEscaped(address indexed player, bytes32 indexed creature, uint captureTokenId);


    /**
     * Public Functions
     */
    /// @dev Setup the factory
    /// @param mapContract Map that contains wildlife
    /// @param creatureTokenContract Creatures that are captured
    /// @param captureTokenContract Tokens that are used to capture creatures with
    function initialize(address mapContract, address creatureTokenContract, address captureTokenContract) 
        public initializer 
    {
        __Ownable_init();
        map = mapContract;
        creatureToken = creatureTokenContract;
        captureToken = captureTokenContract;
    }


    /// @dev Allows a player to try and capture a creature
    /// - Calculates difficulty based on creature, player and tile stats
    /// - Uses pseudo randomness to determin success 
    /// - Validates if caller is allowed to interact with the creature in the map
    /// @param creature The type of creature to capture 
    /// @param sex The sex of the creature to capture
    /// @param captureTokenId The capture item used to capture the creature
    function capture(bytes32 creature, uint8 sex, uint captureTokenId) public 
    {
        // Enforce that msg.sender is token owner
        require(msg.sender == IERC721Upgradeable(captureToken).ownerOf(captureTokenId), "CryptopiaCaptureGame: Only token owner");

        // Enforce that creature exists as wildlife in the tile that msg.sender is at
        (bool canInteract, uint map_difficulty) = ICryptopiaMap(map).getPlayerWildlifeData(msg.sender, creature);
        require(canInteract, "CryptopiaCaptureGame: Unable to interact with creature");

        // Creature
        (uint8 creature_rarity, 
        uint8 creature_class, 
        uint creature_strength) = ICryptopiaCreatureToken(creatureToken)
            .getCreatureStrength(creature);

        // Player
        (uint8 player_rarity, 
        uint8 player_class, 
        uint240 player_strength) = ICryptopiaCaptureToken(captureToken)
            .getItemByTokenId(captureTokenId);

        // Burn capture token (always burned)
        ICryptopiaCaptureToken(captureToken)
            .burn(captureTokenId);

        // Enforce class rule
        require(player_class == 255 || player_class == creature_class, "CryptopiaCaptureGame: Class missmatch");

        // Try capture creature (0 - 10_000)
        uint captureDifficulty = _calculateDifficulty(
            creature_rarity, 
            creature_strength, 
            player_rarity,
            player_class == creature_class, 
            player_strength,
            map_difficulty);

        // Failure (creature wins)
        if (_randomAt(_random(), 0) < captureDifficulty)
        {
            emit CreatureEscaped(msg.sender, creature, captureTokenId);
            return;
        }

        // Success (player wins)
        uint creatureTokenId = ICryptopiaCreatureToken(creatureToken).mintTo(
            msg.sender, creature, sex);

        emit CreatureCaptured(msg.sender, creature, creatureTokenId, captureTokenId);
    }


    /// @dev Calculates difficutly when capturing a creature
    /// @param creature The type of creature to capture 
    /// @param captureTokenId The capture item used to capture the creature
    /// @param account Acount that would capture the creature
    function getCaptureData(bytes32 creature, uint captureTokenId, address account) 
        public view 
        returns (bool canCapture, uint difficulty)
    {
         // Enforce that creature exists as wildlife in the tile that account is at
        (bool canInteract, uint map_difficulty) = ICryptopiaMap(map)
            .getPlayerWildlifeData(account, creature);

        // Creature
        (uint8 creature_rarity, 
        uint8 creature_class, 
        uint creature_strength) = ICryptopiaCreatureToken(creatureToken)
            .getCreatureStrength(creature);

        // Player
        (uint8 player_rarity, 
        uint8 player_class, 
        uint240 player_strength) = ICryptopiaCaptureToken(captureToken)
            .getItemByTokenId(captureTokenId);

        // Try capture creature (0 - 10_000)
        difficulty = _calculateDifficulty(
            creature_rarity, 
            creature_strength, 
            player_rarity,
            player_class == creature_class, 
            player_strength,
            map_difficulty);

        canCapture = canInteract;
    } 


    /// @dev Failsafe mechanism
    /// Allows the owner to retrieve tokens from the contract that 
    /// might have been send there by accident
    /// @param _tokenContract The address of ERC20 compatible token
    function retrieveTokens(address _tokenContract) 
        override public 
        onlyOwner
    {
        super.retrieveTokens(_tokenContract);
    }


    /**
     * Internal Functions
     */
    /// @dev Returns a value between 0 and INVERSE_BASIS_POINT that represents the chance of failure 
    /// (a higher number means a higher chance of the creature escaping)
    /// @param creature_rarity Rarity of the creature
    /// @param creature_strength Strength of the creature (derrived from speed, attack and defence)
    /// @param player_rarity Rarity of the player
    /// @param player_dedicatedClass if true the dedicated class bonus is applied
    /// @param player_strength Strength of the player (derrived from skill and level)
    /// @return difficulty The value that represents the chance of failure
    function _calculateDifficulty(uint8 creature_rarity, uint creature_strength, uint8 player_rarity, bool player_dedicatedClass, uint player_strength, uint map_difficulty) 
        internal pure 
        returns (uint)
    {
        uint creatureScore = _getScore(creature_rarity, false, creature_strength + map_difficulty);
        return (creatureScore / (creatureScore + _getScore(player_rarity, player_dedicatedClass, player_strength))) * INVERSE_BASIS_POINT_SCALER;
    } 


    /// @dev Returns a score based on rarity and strength
    /// @param rarity Common, Rare, Legendary or Master
    /// @param dedicatedClass if true the dedicated class bonus is applied
    /// @param difficulty Composed difficulty value
    /// @return score based on rarity and strength
    function _getScore(uint8 rarity, bool dedicatedClass, uint difficulty) 
        internal pure 
        returns (uint)
    {
        (uint rarityScore, uint rarityMultiplier) = _getRarityValues(rarity);
        if (dedicatedClass)
        {
            // Apply dedicated class bonus
            rarityScore *= DEFICATED_CLASS_MULTIPLIER;
        }

        return rarityScore + difficulty * rarityMultiplier;
    }
    

    /// @dev Returns the score and multiplier for `_rarity`
    /// @param rarity Common, Rare, Legendary or Master
    /// @return score Rarity base score
    /// @return multiplier Rarity multiplier (used to muliply strength with)
    function _getRarityValues(uint8 rarity) 
        internal pure 
        returns (uint score, uint multiplier)
    {
        if (uint8(GameEnums.Rarity.Common) == rarity)
        {
            // Common
            score = RARITY_SCORE_COMMON;
            multiplier = RARITY_MULTIPLIER_COMMON;
        }
        else if (uint8(GameEnums.Rarity.Rare) == rarity)
        {
            // Rare
            score = RARITY_SCORE_RARE;
            multiplier = RARITY_MULTIPLIER_RARE;
        }
        else if (uint8(GameEnums.Rarity.Legendary) == rarity)
        {
            // Legendary
            score = RARITY_SCORE_LEGENDARY;
            multiplier = RARITY_MULTIPLIER_LEGENDARY;
        }
        else 
        {
            // Master
            score = RARITY_SCORE_MASTER;
            multiplier = RARITY_MULTIPLIER_MASTER;
        }
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
    /// @param hash Randomly generated hash 
    /// @param index Used as salt
    /// @return uint32 Random number
    function _randomAt(bytes32 hash, uint index) private pure returns(uint32) {
        return uint32(uint(keccak256(abi.encodePacked(hash, index))) % INVERSE_BASIS_POINT);
    }
}