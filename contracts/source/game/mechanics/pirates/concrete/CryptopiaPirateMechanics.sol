// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";

import "../IPirateMechanics.sol";
import "../../../maps/IMaps.sol";
import "../../../maps/types/MapEnums.sol";
import "../../../players/IPlayerRegister.sol";
import "../../../players/errors/PlayerErrors.sol";
import "../../../players/control/IPlayerFreezeControl.sol";
import "../../../inventories/IInventories.sol";
import "../../../meta/MetaTransactions.sol";
import "../../../utils/random/PseudoRandomness.sol";
import "../../../../types/boxes/UintBox2.sol";
import "../../../../tokens/ERC721/ships/IShips.sol";
import "../../../../errors/ArgumentErrors.sol";
import "../../../../game/errors/TimingErrors.sol";
import "../../../../accounts/multisig/IMultiSigWallet.sol";
import "../../../../accounts/multisig/errors/MultisigErrors.sol";


/// @title Cryptopia pirate game mechanics
/// @dev Provides the mechanics for the pirate gameplay
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaPirateMechanics is Initializable, NoncesUpgradeable, PseudoRandomness, IPirateMechanics {

    struct Confrontation 
    {
        // Pirate
        address attacker;

        // Location intercept took place
        uint16 location;

        // Arrival timestamp of the target (used to prevent multiple interceptions)
        uint64 arrival;

        // Deadline for the target to respond
        uint64 deadline;

        // Timestamp after which the confrontation expires (can be extended by the target)
        uint64 expiration;

        // Escape attempt (can only be attempted once)
        bool escapeAttempted;
    }

    struct Plunder  
    {
        // Deadline for the pirate to loot
        uint64 deadline;

        // Assets that the pirate has looted
        bytes32 assets;
    }


    /**
     * Storage
     */
    uint constant private MAX_CHARISMA = 100; // Denominator
    
    // Settings
    uint64 constant private MAX_RESPONSE_TIME = 600; // 10 minutes

    // Scaling factors
    uint16 constant private SPEED_SCALING_FACTOR = 50; // Capped at 30% influence (speed is unknown)
    uint16 constant private LUCK_SCALING_FACTOR = 20; // Max 20% influence (luck is 0-100) 

    uint constant private SPEED_INFLUENCE_CAP = 3_000; // Max 30% influence (speed is unknown)

    // Other factors
    uint constant private BASE_NEGOCIATION_DEDUCTION_FACTOR = 50; // 50%
    uint constant private BASE_NEGOCIATION_DEDUCTION_FACTOR_PRECISION = 100; // Denominator

    // Randomness
    uint constant private BASE_ESCAPE_THRESHOLD = 5_000; // 50%
    
    // Battle
    uint8 constant private MAX_DAMAGE = 250;
    uint constant private DEFENCE_PRECISION = 100; // Denominator
    uint constant private TILE_SAFETY_PRECISION = 100; // Denominator
    uint constant private ATTACK_EFFECTIVENESS_MARGIN_MIN = 90; // Min 90% attack effectiveness margin
    uint constant private ATTACK_EFFECTIVENESS_MARGIN_MAX = 110; // Max 110% attack effectiveness margin
    uint constant private ATTACK_EFFECTIVENESS_MARGIN_SPREAD = ATTACK_EFFECTIVENESS_MARGIN_MAX - ATTACK_EFFECTIVENESS_MARGIN_MIN; // Spread
    uint constant private ATTACK_EFFECTIVENESS_MARGIN_PRECISION = 100; // Denominator
    
    /// @dev attacker => target
    mapping(address => address) public targets;

    /// @dev target => Confrontation
    mapping(address => Confrontation) public confrontations;

    /// @dev target => Plunder
    mapping(address => Plunder) public plunders;

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
    /// @param target The account of the target
    /// @param location The location at which the confrontation took place
    /// @param deadline The deadline for the target to respond
    /// @param expiration Timestamp after which the confrontation expires (can be extended by the target)
    event PirateConfrontationStart(address indexed attacker, address indexed target, uint16 indexed location, uint64 deadline, uint64 expiration);

    /// @dev Emits when a confrontation ends
    /// @param attacker The account of the attacker
    /// @param target The account of the target
    /// @param location The location at which the confrontation took place
    event PirateConfrontationEnd(address indexed attacker, address indexed target, uint16 indexed location);

    /// @dev Emits when a negotiation succeeds
    /// @param attacker The account of the attacker
    /// @param target The account of the target
    /// @param location The location at which the confrontation took place
    event NegotiationSuccess(address indexed attacker, address indexed target, uint16 indexed location);

    /// @dev Emits when an escape attempt succeeds
    /// @param attacker The account of the attacker
    /// @param target The account of the target
    /// @param location The location at which the confrontation took place
    event EscapeSuccess(address indexed attacker, address indexed target, uint16 indexed location);

    /// @dev Emits when an escape attempt fails
    /// @param attacker The account of the attacker
    /// @param target The account of the target
    /// @param location The location at which the confrontation took place
    event EscapeFail(address indexed attacker, address indexed target, uint16 indexed location);

    /// @dev Emits when a battle starts
    /// @param target The account of the target
    /// @param targetShip The id of the target's ship
    /// @param attacker The account of the attacker
    /// @param attackerShip The id of the attacker's ship
    event NavalBattleStart(address indexed target, uint targetShip,address indexed attacker, uint attackerShip);

    /// @dev Emits when a battle ends
    /// @param target The account of the target
    /// @param targetShip The id of the target's ship
    /// @param targetDamage The damage that the target has taken during the battle
    /// @param attacker The account of the attacker
    /// @param attackerShip The id of the attacker's ship
    /// @param attackerDamage The damage that the attacker has taken during the battle
    /// @param attackerWins True if the pirate wins
    event NavalBattleEnd(
        address indexed target, uint targetShip, uint8 targetDamage, 
        address indexed attacker, uint attackerShip, uint8 attackerDamage, 
        bool attackerWins);


    /**
     * Errors
     */
    /// @dev Revert if the confrontation is has ended
    /// @param attacker The account of the attacker
    /// @param target The account of the target
    error ConfrontationNotFound(address attacker, address target);

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

    /// @dev Revert if the target is a pirate
    error TargetIsPirate(address target);

    /// @dev Revert if the target is not reachable from the attacker's location
    error TargetNotReachable(address attacker, address target);

    /// @dev Revert if target is already intercepted
    /// @param target The account of the target
    error TargetAlreadyIntercepted(address target);

    /// @dev Revert if target has already attempted escape
    /// @param target The account of the target
    error TargetAlreadyAttemptedEscape(address target);


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
        __PseudoRandomness_init();
        treasury = _treasury;
        playerRegisterContract = _playerRegisterContract;
        assetRegisterContract = _assetRegisterContract;
        mapsContract = _mapsContract;
        shipContract = _shipContract;
        fuelContact = _fuelContact;
        intentoriesContract = _intentoriesContract;
    }


    /**
     * Public functions
     */
    /// @dev Get confrontation data
    /// @param target The account of the defender
    /// @return attacker The account of the pirate
    /// @return location The location at which the confrontation took place
    /// @return deadline The deadline for the target to respond
    /// @return expiration The timestamp after which the confrontation expires (can be extended by the target)
    function getConfrontation(address target)
        public override virtual view 
        returns (
            address attacker,
            uint16 location,
            uint64 deadline,
            uint64 expiration
        )
    {
        Confrontation storage confrontation = confrontations[target];
        attacker = confrontation.attacker;
        location = confrontation.location;
        deadline = confrontation.deadline;
        expiration = confrontation.expiration;
    }

    
    /// @dev Intercepts the target at the specified location
    /// @param target The account of the target
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
        public virtual override 
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

        // Ensure that the target is not a pirate
        if (IPlayerRegister(playerRegisterContract).isPirate(target))
        {
            revert TargetIsPirate(target);
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

                uint shipTokenId = IPlayerRegister(playerRegisterContract).getEquippedShip(msg.sender);
                uint fuelConsumption = IShips(shipContract).getShipFuelConsumption(shipTokenId);

                // Handle fuel consumption
                IInventories(intentoriesContract)
                    .__deductFungibleTokenUnchecked(
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
         * Ensure attacker turns pirate
         */ 
        IPlayerRegister(playerRegisterContract)
            .__turnPirate(msg.sender);


        /**
         * Create confrontation
         */
        confrontation.attacker = msg.sender;
        confrontation.location = attackerTileIndex;
        confrontation.arrival = targetArrival;
        confrontation.deadline = uint64(block.timestamp) + MAX_RESPONSE_TIME;
        confrontation.expiration = confrontation.deadline + MAX_RESPONSE_TIME;

        // Link target to attacker
        targets[msg.sender] = target;

        // Freeze players
        IPlayerFreezeControl(mapsContract).__freeze(target, msg.sender, confrontation.expiration);
        IPlayerFreezeControl(intentoriesContract).__freeze(target, confrontation.expiration);

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

        // Take charisma into account
        uint charisma = IPlayerRegister(playerRegisterContract)
            .getCharisma(target);

        if (charisma < MAX_CHARISMA)
        {
            for (uint i = 0; i < assets.length; i++) 
            {
                if (0 != tokenIds[i]) 
                {
                    continue;
                }

                // Deduct from offer based on charisma
                uint deduct = amounts[i] 
                    * BASE_NEGOCIATION_DEDUCTION_FACTOR 
                    * (MAX_CHARISMA + 1 - charisma) 
                    / (MAX_CHARISMA * BASE_NEGOCIATION_DEDUCTION_FACTOR_PRECISION);

                // Deduct from offer
                amounts[i] -= deduct;

                // Send to treasury
                IInventories(intentoriesContract)
                    .__deductFungibleTokenUnchecked(
                        target, 
                        inventories_from[i], 
                        assets[i], 
                        deduct);
            }
        }

        // Transfer assets to attacker
        IInventories(intentoriesContract)
            .__transferUnchecked(
                target, 
                msg.sender, 
                inventories_from, 
                inventories_to,
                assets, 
                amounts,
                tokenIds);

        // Mark confrontation as ended
        confrontation.expiration = 0;

        // Unfreeze players
        IPlayerFreezeControl(mapsContract).__unfreeze(target, msg.sender);
        IPlayerFreezeControl(intentoriesContract).__unfreeze(target);

        // Emit
        emit NegotiationSuccess(msg.sender, target, confrontation.location);
        emit PirateConfrontationEnd(msg.sender, target, confrontation.location);
    }


    /// @dev The escape calculation is based on a combination of randomness, ship speed differences, and 
    /// player luck differences. A base score is generated using a pseudo-random seed. To this base score, 
    /// we add the scaled difference in ship speeds and player luck values. 
    /// @notice The final score determines the outcome of the escape attempt:
    /// - If the score is greater than or equal to the BASE_ESCAPE_THRESHOLD, the escape is successful
    /// - Otherwise, the escape fails
    /// @notice Factors like ship speed and player luck play a crucial role in influencing the escape outcome, 
    /// ensuring that players with faster ships and higher luck values have a better chance of escaping
    function attemptEscape() 
        public virtual override 
    {
        Confrontation storage confrontation = confrontations[msg.sender];
        address attacker = confrontation.attacker;

        // Ensure that the confrontation has not ended
        if (confrontation.expiration < block.timestamp) 
        {
            revert ConfrontationNotFound(address(0), msg.sender);
        }

        // Ensure that the response time has not expired
        if (block.timestamp > confrontation.deadline) 
        {
            revert ResponseTimeExpired(msg.sender, confrontation.deadline);
        }

        // Ensure that the escape attempt has not been attempted before
        if (confrontation.escapeAttempted)
        {
            revert TargetAlreadyAttemptedEscape(msg.sender);
        }

        // Ship data
        (
            ShipTravelData memory targetShipTravelData,
            ShipTravelData memory attackerShipTravelData
        ) = IShips(shipContract).getShipTravelData(
            IPlayerRegister(playerRegisterContract)
                .getEquippedShips(msg.sender, attacker));

        // Player data
        Uint24Box2 memory luckData = IPlayerRegister(playerRegisterContract)
            .getLuck(msg.sender, attacker);

        // Handle fuel consumption
        IInventories(intentoriesContract)
            .__deductFungibleTokenUnchecked(
                msg.sender, 
                Inventory.Ship, 
                fuelContact, 
                targetShipTravelData.fuelConsumption);

        // Generate randomness
        uint score = _getRandomNumberAt(_generateRandomSeed(), 0);

        // Take ship speed into account
        if (targetShipTravelData.speed != attackerShipTravelData.speed) 
        {
            // Target has more speed
            uint speedDifference;
            if (targetShipTravelData.speed > attackerShipTravelData.speed) 
            {
                speedDifference = (targetShipTravelData.speed - attackerShipTravelData.speed) * SPEED_SCALING_FACTOR;
                if (speedDifference > SPEED_INFLUENCE_CAP) 
                {
                    speedDifference = SPEED_INFLUENCE_CAP;
                }

                score += speedDifference;
            }

            // Attacker has more speed
            else if (attackerShipTravelData.speed > targetShipTravelData.speed) 
            {
                speedDifference = (attackerShipTravelData.speed - targetShipTravelData.speed) * SPEED_SCALING_FACTOR;
                if (speedDifference > SPEED_INFLUENCE_CAP) 
                {
                    speedDifference = SPEED_INFLUENCE_CAP;
                }

                if (score > speedDifference) 
                {
                    score -= speedDifference;
                }
                else 
                {
                    score = 0;
                }
            }
        }

        // Take luck into account
        if (luckData.value1 != luckData.value2) 
        {
            // Target has more luck
            if (luckData.value1 > luckData.value2) 
            {
                score += (luckData.value1 - luckData.value2) * LUCK_SCALING_FACTOR;
            }

            // Attacker has more luck
            else if (luckData.value2 > luckData.value1) 
            {
                uint luckDifference = (luckData.value2 - luckData.value1) * LUCK_SCALING_FACTOR;
                if (score > luckDifference) 
                {
                    score -= luckDifference;
                }
                else 
                {
                    score = 0;
                }
            }
        }

        // Successful escape
        if(score >= BASE_ESCAPE_THRESHOLD)
        {
            // Mark confrontation as ended
            confrontation.expiration = 0;

            // Unfreeze players
            IPlayerFreezeControl(mapsContract).__unfreeze(msg.sender, attacker);
            IPlayerFreezeControl(intentoriesContract).__unfreeze(msg.sender);

            // Emit
            emit EscapeSuccess(attacker, msg.sender, confrontation.location);
            emit PirateConfrontationEnd(attacker, msg.sender, confrontation.location);
        }

        // Failed escape
        else 
        {
            // Mark escape attempt
            confrontation.escapeAttempted = true;

            // Emit 
            emit EscapeFail(attacker, msg.sender, confrontation.location);
        }
    }


    /// @dev Allows the target to start a quick battle to resolve the confrontation
    /// @notice The target is allowed to start a quick battle if the response time has not yet expired
    /// @notice The player that initiates the battle has and advantage over the other player in case of a tie
    function startQuickBattleAsTarget() 
       public override
    {
        // Ensure that the confrontation has not ended
        Confrontation storage confrontation = confrontations[msg.sender];
        if (confrontation.expiration < block.timestamp) 
        {
            revert ConfrontationNotFound(address(0), msg.sender);
        }

        // Ensure that the response time has not expired (target)
        if (block.timestamp > confrontation.deadline) 
        {
            revert ResponseTimeExpired(msg.sender, confrontation.deadline);
        }

        _resolveQuickBattle(msg.sender, confrontation.attacker);
    }


    /// @dev Allows the pirate to start a quick battle to resolve the confrontation
    /// @notice The pirate is allowed to start a quick battle if the response time has expired
    /// @notice The player that initiates the battle has and advantage over the other player in case of a tie
    function startQuickBattleAsPirate() 
       public override 
    {
        address target = targets[msg.sender];
        Confrontation storage confrontation = confrontations[target];

        // Ensure that the confrontation has not ended
        if (confrontation.expiration < block.timestamp) 
        {
            revert ConfrontationNotFound(address(0), msg.sender);
        }

        // Ensure that the response time has not expired (target)
        if (block.timestamp <= confrontation.deadline) 
        {
            revert ResponseTimeNotExpired(msg.sender, confrontation.deadline);
        }

        _resolveQuickBattle(target, msg.sender);
    }


    // function loot(Inventory[] memory inventory, address[] memory asset, uint[] memory amount, uint[] memory tokenId)
    //     public virtual override
    // {
    //     // TODO in case pirate won the battle they can loot the target within a certain time frame
    // }


    /**
     * Internal functions
     */
    /// @dev Resolves the confrontation by starting a quick battle
    /// @param target The account of the target
    /// @param attacker The account of the attacker
    function _resolveQuickBattle(address target, address attacker)
        internal 
    {
        TokenPair memory ships = IPlayerRegister(playerRegisterContract)
            .getEquippedShips(target, attacker);

        // Ship data
        (
            ShipBattleData memory targetBattleData,
            ShipBattleData memory attackerBattleData
            
        ) = IShips(shipContract).getShipBattleData(ships);

        // Player data
        Uint24Box2 memory luckData = IPlayerRegister(playerRegisterContract)
            .getLuck(target, attacker);

        // Tile data
        uint8 tileSafety = IMaps(mapsContract).getTileSafety(
            confrontations[target].location);

        // Generate (pseudo) randomness
        (
            uint targetRandomness, 
            uint attackerRandomness
        ) = _getRandomNumberPairAt(_generateRandomSeed(), 0, 1);

        // Take luck into account
        if (luckData.value1 != luckData.value2)
        {
            // Attacker has more luck
            if (luckData.value2 > luckData.value1)
            {
                attackerRandomness += (luckData.value2 - luckData.value1) * LUCK_SCALING_FACTOR;
                if (attackerRandomness > RANDOMNESS_PRECISION_FACTOR)
                {
                    attackerRandomness = RANDOMNESS_PRECISION_FACTOR;
                }
            }

            // Target has more luck
            else 
            {
                targetRandomness += (luckData.value1 - luckData.value2) * LUCK_SCALING_FACTOR;
                if (targetRandomness > RANDOMNESS_PRECISION_FACTOR)
                {
                    targetRandomness = RANDOMNESS_PRECISION_FACTOR;
                }
            }
        }

        /// For clarity:
        /// safetyMultiplier = (isPirate ? TILE_SAFETY_PRECISION - tileSafety : tileSafety) / TILE_SAFETY_PRECISION;
        /// attackEffectiveness = ATTACK_EFFECTIVENESS_MARGIN_MIN + (ATTACK_EFFECTIVENESS_MARGIN_SPREAD * targetRandomness / RANDOMNESS_PRECISION_FACTOR);
        /// attackAfterDefense = (attackerShipAttack * DEFENCE_PRECISION / targetShipDefense) / ATTACK_EFFECTIVENESS_MARGIN_PRECISION;
        /// attackEffective = safetyMultiplier * attackAfterDefense * attackEffectiveness;
        UintBox2 memory effectiveAttack = UintBox2(

            // Target 
            targetBattleData.attack 
            * tileSafety // Take the tile safety into account
            * DEFENCE_PRECISION // Take their defense score into account (ourAttack * 100 / theirDefense)
            * (ATTACK_EFFECTIVENESS_MARGIN_MIN + (ATTACK_EFFECTIVENESS_MARGIN_SPREAD * targetRandomness / RANDOMNESS_PRECISION_FACTOR)) // Random effectiveness
            / TILE_SAFETY_PRECISION
            / (attackerBattleData.defence * ATTACK_EFFECTIVENESS_MARGIN_PRECISION), 

            // Pirate
            attackerBattleData.attack 
            * (TILE_SAFETY_PRECISION - tileSafety) // Take the tile safety into account
            * DEFENCE_PRECISION // Take their defense score into account (ourAttack * 100 / theirDefense)
            * (ATTACK_EFFECTIVENESS_MARGIN_MIN + (ATTACK_EFFECTIVENESS_MARGIN_SPREAD * attackerRandomness / RANDOMNESS_PRECISION_FACTOR)) // Random effectiveness
            / TILE_SAFETY_PRECISION
            / (targetBattleData.defence * ATTACK_EFFECTIVENESS_MARGIN_PRECISION));
        
        // Calculate turns it takes to win
        UintBox2 memory turnsUntilWin = UintBox2(
            (effectiveAttack.value1 - 1 + MAX_DAMAGE - attackerBattleData.damage) / effectiveAttack.value1, // Target
            (effectiveAttack.value2 - 1 + MAX_DAMAGE - targetBattleData.damage) / effectiveAttack.value2); // Pirate

        // Emit
        emit NavalBattleStart(
            target, ships.tokenId1, // Target 
            attacker, ships.tokenId2); // Attacker

        // Pirate wins
        if (turnsUntilWin.value2 < turnsUntilWin.value1 || 
           (turnsUntilWin.value2 == turnsUntilWin.value1 && msg.sender == attacker)) // In case of tie, msg.sender wins
        {
            // Apply damage
            IShips(shipContract).__applyDamage(ships, 
                MAX_DAMAGE - targetBattleData.damage, // Target damage (completely damaged)
                uint8(turnsUntilWin.value2 * effectiveAttack.value1)); // Attacker damage

            // Allow attacker to plunder
            plunders[attacker].deadline = uint64(block.timestamp) + MAX_RESPONSE_TIME;

            // Extend freeze
            IPlayerFreezeControl(mapsContract).__freeze(target, attacker, plunders[attacker].deadline);
            IPlayerFreezeControl(intentoriesContract).__freeze(target, plunders[attacker].deadline);

            // Emit
            emit NavalBattleEnd(
                target, ships.tokenId1, MAX_DAMAGE - targetBattleData.damage, // Target 
                attacker, ships.tokenId2, uint8(turnsUntilWin.value2 * effectiveAttack.value1), // Attacker 
                true); // Pirate wins
        }

        // Target wins
        else 
        {
            // Apply damage
            IShips(shipContract).__applyDamage(ships, 
                uint8(turnsUntilWin.value1 * effectiveAttack.value2), // Target damage 
                MAX_DAMAGE - attackerBattleData.damage); // Attacker damage (completely damaged)

            // Unfreeze players
            IPlayerFreezeControl(mapsContract).__unfreeze(target, attacker);
            IPlayerFreezeControl(intentoriesContract).__unfreeze(target);

            // Emit
            emit NavalBattleEnd(
                target, ships.tokenId1, uint8(turnsUntilWin.value1 * effectiveAttack.value2), // Target 
                attacker, ships.tokenId2, MAX_DAMAGE - attackerBattleData.damage, // Attacker 
                false); // Target wins
        }

        // Mark confrontation as ended
        confrontations[target].expiration = 0;

        // Emit
        emit PirateConfrontationEnd(attacker, target, confrontations[target].location);
    }
}