// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../../maps/IMaps.sol";
import "../../../players/IPlayerRegister.sol";
import "../../../players/errors/PlayerErrors.sol";
import "../IPirateMechanics.sol";

/// @title Cryptopia pirate game mechanics
/// @dev 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaPirateMechanics is Initializable, IPirateMechanics {

    // TODO
    // - Add intercept function that allows the attacker to intercept the defender
    //     - Determine if the attacker is able to intercept the defender
    //     - Deduct the required amount of fuel from the attacker
    //     - Generate an event that indicates that the defender has been intercepted
    //
    // - Add negotiate function that allows the attacker to negotiate with the defender
    // - Add a flee function that allows the defender to flee from the attacker
    // - Add quick auto resolution of battles
    // - Add manual resolution of battles

    struct Interception 
    {
        // Pirate
        address attacker;

        // Defender
        address defender;

        // Location intercept took place
        uint16 location;

        // Deadline for the defender to respond
        uint64 deadline;

         // Timestamp of the interception
        uint64 start;

        // Timestamp at which the interception ends (either by player action or timeout)
        uint64 end;
    }

    /**
     * Storage
     */ 
    uint64 constant private MAX_RESPONSE_TIME = 600; // 10 minutes

    /// @dev Interceptions (target => Interception)
    mapping(address => Interception) public interceptions;
    mapping(address => address) public targets;

    /// @dev Refs
    address public playerRegisterContract;
    address public assetRegisterContract;
    address public mapsContract;
    address public shipContract;


    /**
     * Events
     */
    /// @dev Emits when a pirate intercepts another player
    /// @param attacker The account of the attacker
    /// @param defender The account of the defender
    /// @param location The location at which the interception took place
    event PirateInterception(address indexed attacker, address indexed defender, uint16 indexed location);


    /**
     * Errors
     */
    /// @dev Revert if the attacker is already intercepting a target
    /// @param attacker The account of the attacker
    error AlreadyIntercepting(address attacker);

    /// @dev Revert if target is already intercepted
    /// @param target The account of the defender
    error AlreadyIntercepted(address target);


    /**
     * Public functions
     */
    /// @dev Constructor
    /// @param _playerRegisterContract The address of the player register
    /// @param _assetRegisterContract The address of the asset register
    /// @param _mapsContract The address of the maps contract
    /// @param _shipContract The address of the ship contract
    function initialize(
        address _playerRegisterContract,
        address _assetRegisterContract,
        address _mapsContract,
        address _shipContract
    ) 
        initializer public 
    {
        playerRegisterContract = _playerRegisterContract;
        assetRegisterContract = _assetRegisterContract;
        mapsContract = _mapsContract;
        shipContract = _shipContract;
    }

    
    /// @dev Intercepts the target at the specified location
    /// @param target The account of the defender
    /// @param indexInRoute The index of the tile in the route that the target is traveling
    /// 
    /// Requirements:
    /// - The attacker must have entered the map
    /// - The attacker must not be traveling
    /// - The attacker must be embarked
    /// - The attacker must not be already intercepting a target
    /// - The target must have entered the map
    /// - The target must be reachable from the attacker's location (either by route or location)
    /// - The target must not be already intercepted
    function intercept(address target, uint indexInRoute) 
        public 
    {
        /**
         * Validate attacker conditions
         * 
         * - Ensure that the attacker entered map
         * - Ensure that the attacker is not traveling
         * - Ensure that the attacker's location is valid
         */
        (
            bool attackerIsTraveling, 
            bool attackerIsEmbarked,
            uint16 attackerTileIndex,,
            uint64 attackerArrival
        ) = IMaps(mapsContract).getPlayerTravelData(target);

        // Ensure attacker entered map
        if (0 == attackerArrival) 
        {
            // Revert
        }

        // Ensure that the attacker is not traveling
        if (attackerIsTraveling) 
        {
            // Revert
        }

        // Ensure that the attacker's location is valid
        if (!attackerIsEmbarked) 
        {
            // Revert
        }

        // Ensure that the attacker is not already intercepting a target
        if (interceptions[targets[msg.sender]].end > 0 && 
            interceptions[targets[msg.sender]].end < block.timestamp) 
        {
            revert AlreadyIntercepting(msg.sender);
        }


        /**
         * Validate target conditions
         * 
         * - Ensure that the target entered map
         * - Ensure that the target is reachable from the attacker's location
         * - Ensure that the target is not already intercepted
         */
        (
            bool targetIsTraveling, 
            bool targetIsEmbarked,
            uint16 targetTileIndex, 
            bytes32 targetRoute, 
            uint64 targetArrival
        ) = IMaps(mapsContract).getPlayerTravelData(target);

        // Ensure that the target entered map
        if (0 == targetArrival) 
        {
            // Revert
        }

        // Ensure that the target's location is valid
        if (!targetIsEmbarked) 
        {
            // Revert
        }

        // Ensure that the target is reachable from the attacker's location
        if (attackerTileIndex != targetTileIndex)
        {
            if (targetIsTraveling) 
            {
                // Check route
                if (!IMaps(mapsContract).tileIsAlongRoute(attackerTileIndex, targetRoute)) 
                {
                    // Revert
                }
            }
            else 
            {
                // Check location
                if (!IMaps(mapsContract).tileIsAdjacentTo(attackerTileIndex, targetTileIndex)) 
                {
                    // Revert
                }
            }
        }

        // Ensure that the target is not already intercepted
        Interception storage interception = interceptions[target];
        if (interception.end > 0 && interception.end < block.timestamp) 
        {
            revert AlreadyIntercepting(msg.sender);
        }


        /**
         * Create interception
         */
        interception.attacker = msg.sender;
        interception.defender = target;
        interception.location = attackerTileIndex;
        interception.start = uint64(block.timestamp);
        interception.deadline = interception.start + MAX_RESPONSE_TIME;
        interception.end = 0; // TODO; Set

        // Link target to attacker
        targets[msg.sender] = target;

        // Emit event
        emit PirateInterception(msg.sender, target, attackerTileIndex);
    }
}