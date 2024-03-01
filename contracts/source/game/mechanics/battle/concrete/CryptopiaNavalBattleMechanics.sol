// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../IBattleMechanics.sol";
import "../../../maps/IMaps.sol"; 
import "../../../players/IPlayerRegister.sol";
import "../../../utils/random/PseudoRandomness.sol";
import "../../../../types/boxes/uint24/Uint24Box2.sol";
import "../../../../tokens/ERC721/ships/IShips.sol";

/// @title Cryptopia Naval Battle Mechanics
/// @notice This contract is at the heart of naval combat within Cryptopia, 
/// orchestrating the complexities of ship-to-ship battles. It manages the intricate details of naval 
/// engagements, including attack effectiveness, defense mechanisms, and the influence of luck and 
/// environmental factors like tile safety. The contract ensures a dynamic and strategic battle environment, 
/// where each player's decisions, ship attributes, and tile locations significantly impact the battle outcomes.
/// It integrates closely with ship and player data contracts to fetch relevant information for calculating battle dynamics. 
/// This contract provides a framework for players to engage in exciting naval battles, enhancing their gaming experience 
/// with unpredictable and thrilling combat scenarios.
/// @dev Inherits from Initializable, AccessControlUpgradeable, and PseudoRandomness, and implements the IBattleMechanics interface.
/// The contract uses upgradeable patterns for scalability and future enhancement potential. It employs pseudo-randomness 
/// to generate unpredictable battle outcomes, adding excitement and unpredictability to the gameplay. 
/// It defines key battle parameters and utilizes them to calculate damage, turns until win, and ultimately determine the victor of naval battles.
/// The battle mechanics are designed to be fair yet challenging, ensuring that each battle is a unique experience.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaNavalBattleMechanics is Initializable, AccessControlUpgradeable, PseudoRandomness, IBattleMechanics {

    /**
     * Storage
     */
    uint constant private DEFENCE_PRECISION = 100; // Denominator
    uint constant private TILE_SAFETY_PRECISION = 100; // Denominator
    uint constant private ATTACK_EFFECTIVENESS_MARGIN_MIN = 90; // Min 90% attack effectiveness margin
    uint constant private ATTACK_EFFECTIVENESS_MARGIN_MAX = 110; // Max 110% attack effectiveness margin
    uint constant private ATTACK_EFFECTIVENESS_MARGIN_SPREAD = ATTACK_EFFECTIVENESS_MARGIN_MAX - ATTACK_EFFECTIVENESS_MARGIN_MIN; // Spread
    uint constant private ATTACK_EFFECTIVENESS_MARGIN_PRECISION = 100; // Denominator

    // Scaling factors
    uint16 constant private LUCK_SCALING_FACTOR = 20; // Max 20% influence (luck is 0-100) 

    // Refs
    address public playerRegisterContract;
    address public mapsContract;
    address public shipContract;


    /**
     * Roles
     */
    bytes32 constant private SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Events
     */
    /// @dev Emits when a battle ends
    /// @param player1 The account of the player1
    /// @param player1_ship The id of the player1's ship
    /// @param player1_damage The damage that the target has taken during the battle
    /// @param player2 The account of the player2
    /// @param player2_ship The id of the player2's ship
    /// @param player2_damage The damage that the attacker has taken during the battle
    /// @param victor The account of the victor
    event QuickNavalBattle(address indexed player1, uint player1_ship, uint16 player1_damage, address indexed player2, uint player2_ship, uint16 player2_damage, address victor);


    /// @dev Constructor
    /// @param _playerRegisterContract The address of the player register
    /// @param _mapsContract The address of the maps contract
    /// @param _shipContract The address of the ship contract
    function initialize(
        address _playerRegisterContract,
        address _mapsContract,
        address _shipContract
    ) 
        initializer public 
    {
        __AccessControl_init();
        __PseudoRandomness_init();

        // Refs
        playerRegisterContract = _playerRegisterContract;
        mapsContract = _mapsContract;
        shipContract = _shipContract;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * System functions
     */
    /// @dev Quick battle between two players
    /// @notice Player 1 is expected to be the initiator of the battle (msg.sender)
    /// @param player1 The account of the first player
    /// @param player2 The account of the second player
    /// @param location The location at which the battle takes place
    /// @return battleData The outcome of the battle
    function __quickBattle(address player1, address player2, uint16 location) 
        onlyRole(SYSTEM_ROLE) 
        public virtual 
        returns (BattleData memory battleData)
    {
        // Location data
        uint8 tileSafety = IMaps(mapsContract)
            .getTileSafety(location);

        // Ship data
        TokenPair memory ships = IPlayerRegister(playerRegisterContract)
            .getEquippedShips(player1, player2);
        (
            ShipBattleData memory player1BattleData,
            ShipBattleData memory player2BattleData
        ) = IShips(shipContract).getShipBattleData(ships);

        // Player data
        Uint24Box2 memory luckData = IPlayerRegister(playerRegisterContract)
            .getLuck(player1, player2);

        // Generate (pseudo) randomness
        (
            uint player1Randomness, 
            uint player2Randomness
        ) = _getRandomNumberPairAt(_generateRandomSeed(), 0, 1);

        // Take luck into account
        if (luckData.value1 != luckData.value2)
        {
            // Player2 has more luck
            if (luckData.value2 > luckData.value1)
            {
                player2Randomness += (luckData.value2 - luckData.value1) * LUCK_SCALING_FACTOR;
                if (player2Randomness > RANDOMNESS_PRECISION_FACTOR)
                {
                    player2Randomness = RANDOMNESS_PRECISION_FACTOR;
                }
            }

            // Player1 has more luck
            else 
            {
                player1Randomness += (luckData.value1 - luckData.value2) * LUCK_SCALING_FACTOR;
                if (player1Randomness > RANDOMNESS_PRECISION_FACTOR)
                {
                    player1Randomness = RANDOMNESS_PRECISION_FACTOR;
                }
            }
        }


        /// For clarity:
        /// safetyMultiplier = (tileSafetyInverse ? TILE_SAFETY_PRECISION - tileSafety : tileSafety) / TILE_SAFETY_PRECISION;
        /// effectivenessMultiplier = ATTACK_EFFECTIVENESS_MARGIN_MIN + (ATTACK_EFFECTIVENESS_MARGIN_SPREAD * ourRandomness / RANDOMNESS_PRECISION_FACTOR);
        /// defenseMultiplier = DEFENCE_PRECISION / theirDefence;
        /// effectiveAttack = attack * safetyMultiplier * effectivenessMultiplier * defenseMultiplier;
        battleData.player1_effectiveAttack = player1BattleData.attack 
            * DEFENCE_PRECISION // Take their defense score into account (ourAttack * 100 / theirDefense)
            * (player1BattleData.tileSafetyInverse ? TILE_SAFETY_PRECISION - tileSafety : tileSafety) // Take the tile safety into account    
            * (ATTACK_EFFECTIVENESS_MARGIN_MIN + (ATTACK_EFFECTIVENESS_MARGIN_SPREAD * player1Randomness / RANDOMNESS_PRECISION_FACTOR)) // Random effectiveness
            / (player2BattleData.defence * TILE_SAFETY_PRECISION * ATTACK_EFFECTIVENESS_MARGIN_PRECISION);

        battleData.player2_effectiveAttack = player2BattleData.attack 
            * DEFENCE_PRECISION // Take their defense score into account (ourAttack * 100 / theirDefense)
            * (player2BattleData.tileSafetyInverse ? TILE_SAFETY_PRECISION - tileSafety : tileSafety) // Take the tile safety into account
            * (ATTACK_EFFECTIVENESS_MARGIN_MIN + (ATTACK_EFFECTIVENESS_MARGIN_SPREAD * player2Randomness / RANDOMNESS_PRECISION_FACTOR)) // Random effectiveness
            / (player1BattleData.defence * TILE_SAFETY_PRECISION * ATTACK_EFFECTIVENESS_MARGIN_PRECISION);
        
        // Turns until 
        battleData.player1_turnsUntilWin = (battleData.player1_effectiveAttack - 1 + player2BattleData.health - player2BattleData.damage) / battleData.player1_effectiveAttack;
        battleData.player2_turnsUntilWin = (battleData.player2_effectiveAttack - 1 + player1BattleData.health - player1BattleData.damage) / battleData.player2_effectiveAttack;

        // Player2 wins
        if (battleData.player2_turnsUntilWin < battleData.player1_turnsUntilWin) // In case of tie player1 wins (msg.sender)
        {
            // Calculate damage
            battleData.player1_damageTaken = player1BattleData.health - player1BattleData.damage; // Completely damaged
            battleData.player2_damageTaken = player2BattleData.damage + (battleData.player2_turnsUntilWin * battleData.player1_effectiveAttack) <= player2BattleData.health 
                ? uint16(battleData.player2_turnsUntilWin * battleData.player1_effectiveAttack) 
                : player2BattleData.health - player2BattleData.damage;

            battleData.victor = player2;
        }

        // Player1 wins
        else 
        {
            // Calculate damage
            battleData.player2_damageTaken = player2BattleData.health - player2BattleData.damage; // Completely damaged
            battleData.player1_damageTaken = player1BattleData.damage + (battleData.player1_turnsUntilWin * battleData.player2_effectiveAttack) <= player1BattleData.health 
                ? uint16(battleData.player1_turnsUntilWin * battleData.player2_effectiveAttack) 
                : player1BattleData.health - player1BattleData.damage;
            
            battleData.victor = player1;
        }

        // Apply damage
        IShips(shipContract).__applyDamage(
            ships, battleData.player1_damageTaken, battleData.player2_damageTaken); 

        // Emit
        emit QuickNavalBattle(
            player1, ships.tokenId1, battleData.player1_damageTaken, // Player 1 
            player2, ships.tokenId2, battleData.player2_damageTaken, // Player 2
            battleData.victor);
    }
}