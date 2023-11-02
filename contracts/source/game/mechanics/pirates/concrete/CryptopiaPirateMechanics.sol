// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";

import "../IPirateMechanics.sol";
import "../../../maps/IMaps.sol";
import "../../../maps/types/MapEnums.sol";
import "../../../players/IPlayerRegister.sol";
import "../../../players/errors/PlayerErrors.sol";
import "../../../inventories/IInventories.sol";
import "../../../meta/MetaTransactions.sol";
import "../../../../tokens/ERC721/ships/IShips.sol";
import "../../../../errors/ArgumentErrors.sol";
import "../../../../game/errors/TimingErrors.sol";
import "../../../../accounts/multisig/IMultiSigWallet.sol";
import "../../../../accounts/multisig/errors/MultisigErrors.sol";

/// @title Cryptopia pirate game mechanics
/// @dev Provides the mechanics for the pirate gameplay
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaPirateMechanics is Initializable, NoncesUpgradeable, IPirateMechanics {

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

    struct Confrontation 
    {
        // Pirate
        address attacker;

        // Defender
        address defender;

        // Location intercept took place
        uint16 location;

        // Arrival timestamp of the defender (used to prevent multiple interceptions)
        uint64 arrival;

        // Deadline for the defender to respond
        uint64 deadline;

        // Timestamp after which the confrontation expires (can be extended by the defender)
        uint64 expiration;
    }


    /**
     * Storage
     */ 
    uint64 constant private MAX_RESPONSE_TIME = 600; // 10 minutes

    /// @dev target => Confrontation
    mapping(address => Confrontation) public confrontations;

    /// @dev attacker => target
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
    /// @param location The location at which the confrontation took place
    /// @param deadline The deadline for the defender to respond
    /// @param expiration Timestamp after which the confrontation expires (can be extended by the defender)
    event PirateConfrontationStart(address indexed attacker, address indexed target, uint16 indexed location, uint64 deadline, uint64 expiration);

    /// @dev Emits when a confrontation ends
    /// @param attacker The account of the attacker
    /// @param target The account of the defender
    /// @param location The location at which the confrontation took place
    event PirateConfrontationEnd(address indexed attacker, address indexed target, uint16 indexed location);


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

    /// @dev Revert if the target is idle (when not traveling)
    error TargetIsIdle(address target);

    /// @dev Revert if the target is not reachable from the attacker's location
    error TargetNotReachable(address attacker, address target);

    /// @dev Revert if target is already intercepted
    /// @param target The account of the defender
    error TargetAlreadyIntercepted(address target);

    /// @dev Revert if the confrontation is has ended
    /// @param attacker The account of the attacker
    /// @param target The account of the defender
    error ConfrontationNotFound(address attacker, address target);


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
        __Nonces_init();
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
    /// - The attacker must have enough fuel to intercept the target
    /// - The target must have entered the map
    /// - The target must be reachable from the attacker's location (either by route or location)
    /// - The target must not be idle (when not traveling)
    /// - The target must not be already intercepted
    function intercept(address target, uint indexInRoute) 
        public 
    {
        // Prevent self-interception
        if (msg.sender == target) 
        {
            revert ArgumentInvalid();
        }

        /**
         * Validate attacker conditions
         * 
         * - Ensure that the attacker entered map
         * - Ensure that the attacker is not traveling
         * - Ensure that the attacker's location is valid
         */
        (,
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
        if (confrontations[targets[msg.sender]].expiration > block.timestamp) 
        {
            revert AttackerAlreadyIntercepting(msg.sender);
        }


        /**
         * Validate target conditions
         * 
         * - Ensure that the target entered map
         * - Ensure that the target is reachable from the attacker's location
         * - Ensure that the target is not idle (when not traveling)
         * - Ensure that the target is not already intercepted
         */
        (
            bool targetIsIdle,
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

        // Ensure that the target is not idle 
        if (targetIsIdle) 
        {
            revert TargetIsIdle(target);
        }

        // Ensure that the target is not already intercepted
        Confrontation storage confrontation = confrontations[target];
        if (confrontation.expiration > block.timestamp) 
        {
            revert TargetAlreadyIntercepted(target);
        }

        // Ensure that the target has not been intercepted before on this voyage
        else if (confrontation.arrival == targetArrival) 
        {
            revert TargetAlreadyIntercepted(target);
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
                    .__deductFungibleToken(
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


        /**
         * Create confrontation
         */
        confrontation.attacker = msg.sender;
        confrontation.defender = target;
        confrontation.location = attackerTileIndex;
        confrontation.arrival = targetArrival;
        confrontation.deadline = uint64(block.timestamp) + MAX_RESPONSE_TIME;
        confrontation.expiration = confrontation.deadline + MAX_RESPONSE_TIME;

        // Link target to attacker
        targets[msg.sender] = target;

        // Emit event
        emit PirateConfrontationStart(msg.sender, target, attackerTileIndex, confrontation.deadline, confrontation.expiration);
    }


    /// @dev Attacker accepts the offer from the target to resolve the confrontation
    /// @param signatures Array of signatures authorizing the attacker to accept the offer
    /// @param inventories_from The inventories in which the assets are located
    /// @param inventories_to The inventories to which the assets will be moved
    /// @param assets The assets that the target is willing to offer
    /// @param amounts The amounts of the assets that the target is willing to offer
    /// @param tokenIds The ids of the assets that the target is willing to offer
    function acceptOffer(bytes[] memory signatures, Inventory[] memory inventories_from, Inventory[] memory inventories_to, address[] memory assets, uint[] memory amounts, uint[] memory tokenIds)
        public virtual override
    {
        address target = targets[msg.sender];
        Confrontation storage confrontation = confrontations[target];

        // Ensure that the confrontation has not ended
        if (confrontation.expiration < block.timestamp) 
        {
            revert ConfrontationNotFound(msg.sender, target);
        }

        // Ensure that the response time has not expired
        if (block.timestamp > confrontation.deadline) 
        {
            revert ResponseTimeExpired(target, confrontation.deadline);
        }

        // Validate signatures
        bytes32 _hash = keccak256(abi.encode(
            MetaTransactions.EIP712_TRANSFER_PROPOSAL_SCHEMA_HASH,
            target,
            msg.sender,
            keccak256(abi.encodePacked(inventories_from)),
            keccak256(abi.encodePacked(assets)),
            keccak256(abi.encodePacked(amounts)),
            keccak256(abi.encodePacked(tokenIds)),
            confrontation.deadline,
            _useNonce(target),
            address(this)
        ));

        if (!IMultiSigWallet(target).isValidSignatureSet(_hash, signatures)) 
        {
            revert InvalidSignatureSet(target);
        }

        // Move assets
        IInventories(intentoriesContract).__transfer(
            target, 
            msg.sender, 
            inventories_from, 
            inventories_to,
            assets, 
            amounts,
            tokenIds);

        // Mark confrontation as ended
        confrontation.expiration = 0;

        // Emit
        emit PirateConfrontationEnd(msg.sender, target, confrontation.location);
    }
}