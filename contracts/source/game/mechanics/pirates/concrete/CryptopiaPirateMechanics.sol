// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

import "../../../maps/IMaps.sol";
import "../../../maps/types/MapEnums.sol";
import "../../../players/IPlayerRegister.sol";
import "../../../players/errors/PlayerErrors.sol";
import "../../../inventories/IInventories.sol";
import "../../../../tokens/ERC721/ships/IShips.sol";
import "../IPirateMechanics.sol";

/// @title Cryptopia pirate game mechanics
/// @dev Provides the mechanics for the pirate gameplay
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaPirateMechanics is Initializable, IPirateMechanics {

    // TODO
    // * Add intercept function that allows the attacker to intercept the defender
    //     * Determine if the attacker is able to intercept the defender
    //     - Deduct the required amount of fuel from the attacker
    //     * Generate an event that indicates that the defender has been intercepted
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
    address public treasury;
    address public playerRegisterContract;
    address public assetRegisterContract;
    address public mapsContract;
    address public shipContract;
    address public fuelContact;
    address public intentoriesContract;


    /**
     * Events
     */
    /// @dev Emits when a pirate intercepts another player
    /// @param attacker The account of the attacker
    /// @param target The account of the defender
    /// @param location The location at which the interception took place
    event PirateInterception(address indexed attacker, address indexed target, uint16 indexed location);


    /**
     * Errors
     */
    /// @dev Revert if the attacker is already intercepting a target
    /// @param attacker The account of the attacker
    error AttackerAlreadyIntercepting(address attacker);

    /// @dev Revert if the attacker has not entered the map
    error AttackerNotInMap(address attacker);

    /// @dev Revert if the attacker is currently traveling
    error AttackerIsTraveling(address attacker);

    /// @dev Revert if the attacker's location is not valid (not embarked)
    error AttackerNotEmbarked(address attacker);

    /// @dev Revert if the target has not entered the map
    error TargetNotInMap(address target);

    /// @dev Revert if the target's location is not valid (not embarked)
    error TargetNotEmbarked(address target);

    /// @dev Revert if the target is not reachable from the attacker's location
    error TargetNotReachable(address attacker, address target);

    /// @dev Revert if target is already intercepted
    /// @param target The account of the defender
    error TargetAlreadyIntercepted(address target);


    /**
     * Public functions
     */
    /// @dev Constructor
    /// @param _treasury The address of the treasury
    /// @param _playerRegisterContract The address of the player register
    /// @param _assetRegisterContract The address of the asset register
    /// @param _mapsContract The address of the maps contract
    /// @param _shipContract The address of the ship contract
    /// @param _fuelContact The address of the fuel contract
    /// @param _intentoriesContract The address of the inventories contract
    function initialize(
        address _treasury,
        address _playerRegisterContract,
        address _assetRegisterContract,
        address _mapsContract,
        address _shipContract,
        address _fuelContact,
        address _intentoriesContract
    ) 
        initializer public 
    {
        treasury = _treasury;
        playerRegisterContract = _playerRegisterContract;
        assetRegisterContract = _assetRegisterContract;
        mapsContract = _mapsContract;
        shipContract = _shipContract;
        fuelContact = _fuelContact;
        intentoriesContract = _intentoriesContract;
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
        ) = IMaps(mapsContract).getPlayerTravelData(msg.sender);

        // Ensure attacker entered map
        if (0 == attackerArrival) 
        {
            revert AttackerNotInMap(msg.sender);
        }

        // Ensure that the attacker is not traveling
        if (attackerIsTraveling) 
        {
            revert AttackerIsTraveling(msg.sender);
        }

        // Ensure that the attacker's location is valid
        if (!attackerIsEmbarked) 
        {
            revert AttackerNotEmbarked(msg.sender);
        }

        // Ensure that the attacker is not already intercepting a target
        if (interceptions[targets[msg.sender]].end > block.timestamp) 
        {
            revert AttackerAlreadyIntercepting(msg.sender);
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
            revert TargetNotInMap(target);
        }

        // Ensure that the target's location is valid
        if (!targetIsEmbarked) 
        {
            revert TargetNotEmbarked(target);
        }

        // Ensure that the target is reachable from the attacker's location
        if (attackerTileIndex != targetTileIndex)
        {
            if (targetIsTraveling) 
            {
                // Check route
                if (!IMaps(mapsContract).tileIsAlongRoute(attackerTileIndex, targetRoute, indexInRoute, targetTileIndex, targetArrival, RoutePosition.Current)) 
                {
                    revert TargetNotReachable(msg.sender, target);
                }

                uint shipTokenId = IPlayerRegister(playerRegisterContract).getEquiptedShip(msg.sender);
                uint fuelConsumption = IShips(shipContract).getShipFuelConsumption(shipTokenId);

                // Handle fuel consumption
                IInventories(intentoriesContract)
                    .deductFungibleToken(
                        msg.sender, 
                        Inventory.Ship, 
                        fuelContact, 
                        fuelConsumption);
            }
            else 
            {
                // Check location
                if (!IMaps(mapsContract).tileIsAdjacentTo(attackerTileIndex, targetTileIndex)) 
                {
                    revert TargetNotReachable(msg.sender, target);
                }
            }
        }

        // Ensure that the target is not already intercepted
        Interception storage interception = interceptions[target];
        if (interception.end > block.timestamp) 
        {
            revert TargetAlreadyIntercepted(target);
        }


        /**
         * Create interception
         */
        interception.attacker = msg.sender;
        interception.defender = target;
        interception.location = attackerTileIndex;
        interception.start = uint64(block.timestamp);
        interception.deadline = interception.start + MAX_RESPONSE_TIME;
        interception.end = interception.deadline + MAX_RESPONSE_TIME;

        // Link target to attacker
        targets[msg.sender] = target;

        // Emit event
        emit PirateInterception(msg.sender, target, attackerTileIndex);
    }
}