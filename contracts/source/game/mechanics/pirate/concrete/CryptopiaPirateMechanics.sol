// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";

import "../IPirateMechanics.sol";
import "../../battle/IBattleMechanics.sol";
import "../../../maps/IMaps.sol";
import "../../../maps/types/MapEnums.sol";
import "../../../players/IPlayerRegister.sol";
import "../../../players/errors/PlayerErrors.sol";
import "../../../players/control/IPlayerFreezeControl.sol";
import "../../../inventories/IInventories.sol";
import "../../../meta/MetaTransactions.sol";
import "../../../utils/random/PseudoRandomness.sol";
import "../../../../types/boxes/uint24/Uint24Box2.sol";
import "../../../../tokens/ERC721/ships/IShips.sol";
import "../../../../errors/ArgumentErrors.sol";
import "../../../../game/errors/TimingErrors.sol";
import "../../../../accounts/multisig/IMultiSigWallet.sol";
import "../../../../accounts/multisig/errors/MultisigErrors.sol";

/// @title Cryptopia pirate game mechanics
/// @dev Provides the mechanics for the pirate gameplay
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaPirateMechanics is Initializable, NoncesUpgradeable, PseudoRandomness, IPirateMechanics {

    /**
     * Storage
     */
    // Settings
    uint64 constant private MAX_RESPONSE_TIME = 600; // 10 minutes
    uint constant private BASE_XP_REWARD = 100; // 100 XP

    // Scaling factors
    uint constant private MAX_LUCK = 100; // Denominator
    uint constant private MAX_CHARISMA = 100; // Denominator

    uint16 constant private SPEED_SCALING_FACTOR = 50; // Capped at 30% influence (speed is unknown)
    uint16 constant private LUCK_SCALING_FACTOR = 20; // Max 20% influence (luck is 0-100) 

    uint constant private SPEED_INFLUENCE_CAP = 3_000; // Max 30% influence (speed is unknown)

    // Negociation factors
    uint constant private BASE_NEGOCIATION_DEDUCTION_FACTOR = 50; // 50%
    uint constant private BASE_NEGOCIATION_DEDUCTION_FACTOR_PRECISION = 100; // Denominator

    // Plunder factors
    uint constant private BASE_PLUNDER_DEDUCTION_FACTOR = 50; // 50%
    uint constant private BASE_PLUNDER_DEDUCTION_FACTOR_PRECISION = 100; // Denominator

    // Randomness
    uint constant private BASE_ESCAPE_THRESHOLD = 5_000; // 50%
    uint constant private BASE_PLUNDER_THRESHOLD = 5_000; // 50%
    
    /// @dev pirate => target
    mapping(address => address) public targets;

    /// @dev target => Confrontation
    mapping(address => Confrontation) public confrontations;

    /// @dev pirate => target => Plunder
    mapping(address => mapping(address => Plunder)) public plunders;

    // Refs
    address public navalBattleMechanicsContract;
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
    /// @param target The account of the target
    /// @param attacker The account of the attacker
    /// @param location The location at which the confrontation took place
    /// @param deadline The deadline for the target to respond
    /// @param expiration Timestamp after which the confrontation expires (can be extended by the target)
    event PirateConfrontationStart(address indexed target, address indexed attacker, uint16 indexed location, uint64 deadline, uint64 expiration);

    /// @dev Emits when a confrontation ends
    /// @param target The account of the target
    /// @param attacker The account of the attacker
    /// @param location The location at which the confrontation took place
    event PirateConfrontationEnd(address indexed target, address indexed attacker, uint16 indexed location);

    /// @dev Emits when a negotiation succeeds
    /// @param target The account of the target
    /// @param attacker The account of the attacker
    /// @param location The location at which the confrontation took place
    event NegotiationSuccess(address indexed target, address indexed attacker, uint16 indexed location);

    /// @dev Emits when an escape attempt succeeds
    /// @param target The account of the target
    /// @param attacker The account of the attacker
    /// @param location The location at which the confrontation took place
    event EscapeSuccess(address indexed target, address indexed attacker, uint16 indexed location);

    /// @dev Emits when an escape attempt fails
    /// @param target The account of the target
    /// @param attacker The account of the attacker
    /// @param location The location at which the confrontation took place
    event EscapeFail(address indexed target, address indexed attacker, uint16 indexed location);

    /// @dev Emits when a plunder attempt succeeds
    /// @param target The account of the target
    /// @param attacker The account of the attacker
    /// @param assets The assets that the pirate is looting
    /// @param amounts The amounts of the assets that the pirate is looting (in case of fungible assets)
    /// @param tokenIds The ids of the assets that the pirate is looting (in case of non-fungible assets)
    event PiratePlunderSuccess(address indexed target, address indexed attacker, address[] assets, uint[] amounts, uint[] tokenIds);


    /**
     * Errors
     */
    /// @dev Revert if the confrontation is has ended
    /// @param target The account of the target
    /// @param attacker The account of the attacker
    error ConfrontationNotFound(address target, address attacker);

    /// @dev Revert if the attacker is already intercepting a target
    /// @param attacker The account of the attacker
    error AttackerAlreadyIntercepting(address attacker);

    /// @dev Revert if the attacker has not entered the map
    /// @param attacker The account of the attacker
    error AttackerNotInMap(address attacker);

    /// @dev Revert if the attacker is currently traveling
    /// @param attacker The account of the attacker
    error AttackerIsTraveling(address attacker);

    /// @dev Revert if the attacker's location is not valid (not embarked)
    /// @param attacker The account of the attacker
    error AttackerNotEmbarked(address attacker);

    /// @dev Revert if the target has not entered the map
    /// @param target The account of the target
    error TargetNotInMap(address target);

    /// @dev Revert if the target's location is not valid (not embarked)
    /// @param target The account of the target
    error TargetNotEmbarked(address target);

    /// @dev Revert if the target is idle (when not traveling)
    /// @param target The account of the target
    error TargetIsIdle(address target);

    /// @dev Revert if the target is a pirate
    /// @param target The account of the target
    error TargetIsPirate(address target);

    /// @dev Revert if the target is not reachable from the attacker's location
    /// @param target The account of the target
    /// @param attacker The account of the attacker
    error TargetNotReachable(address target, address attacker);

    /// @dev Revert if target is already intercepted
    /// @param target The account of the target
    error TargetAlreadyIntercepted(address target);

    /// @dev Revert if target has already attempted escape
    /// @param target The account of the target
    error TargetAlreadyAttemptedEscape(address target);

    /// @dev Revert if the target was already plundered
    /// @param target The account of the target
    error TargetAlreadyPlundered(address target);   


    /// @dev Constructor
    /// @param _navalBattleMechanicsContract The address of the naval battle mechanics contract
    /// @param _playerRegisterContract The address of the player register
    /// @param _assetRegisterContract The address of the asset register
    /// @param _mapsContract The address of the maps contract
    /// @param _shipContract The address of the ship contract
    /// @param _fuelContact The address of the fuel contract
    /// @param _intentoriesContract The address of the inventories contract
    function initialize(
        address _navalBattleMechanicsContract,
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
        navalBattleMechanicsContract = _navalBattleMechanicsContract;
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
    /// @return Confrontation data
    function getConfrontation(address target)
        public override virtual view 
        returns (Confrontation memory)
    {
        return confrontations[target];
    }


    /// @dev Get plunder data
    /// @param attacker The account of the pirate
    /// @param target The account of the defender
    /// @return Plunder data
    function getPlunder(address attacker, address target)
        public override virtual view 
        returns (Plunder memory)
    {
        return plunders[attacker][target];
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

        // Ensure that the attacker is not already plundering the target
        if (plunders[msg.sender][target].deadline > block.timestamp) 
        {
            revert TargetAlreadyPlundered(target);
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
                    revert TargetNotReachable(target, msg.sender);
                }

                uint shipTokenId = IPlayerRegister(playerRegisterContract).getEquippedShip(msg.sender);
                uint fuelConsumption = IShips(shipContract).getShipFuelConsumption(shipTokenId);

                // Handle fuel consumption
                IInventories(intentoriesContract)
                    .__deductFungibleTokenUnchecked(
                        msg.sender, 
                        Inventory.Ship, 
                        fuelContact, 
                        fuelConsumption,
                        true);
            }
            else 
            {
                // Check location
                if (!IMaps(mapsContract).tileIsAdjacentTo(attackerTileIndex, targetTileIndex)) 
                {
                    revert TargetNotReachable(target, msg.sender);
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
        emit PirateConfrontationStart(target, msg.sender, attackerTileIndex, confrontation.deadline, confrontation.expiration);
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
            revert ConfrontationNotFound(target, msg.sender);
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
                        deduct,
                        true);
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
        emit NegotiationSuccess(target, msg.sender, confrontation.location);
        emit PirateConfrontationEnd(target, msg.sender, confrontation.location);
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
            revert ConfrontationNotFound(msg.sender, address(0));
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

        // Player data; value1 = target luck, value2 = attacker luck
        Uint24Box2 memory luckData = IPlayerRegister(playerRegisterContract)
            .getLuck(msg.sender, attacker);

        // Handle fuel consumption
        IInventories(intentoriesContract)
            .__deductFungibleTokenUnchecked(
                msg.sender, 
                Inventory.Ship, 
                fuelContact, 
                targetShipTravelData.fuelConsumption, 
                true);

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
            emit EscapeSuccess(msg.sender, attacker, confrontation.location);
            emit PirateConfrontationEnd(msg.sender, attacker, confrontation.location);
        }

        // Failed escape
        else 
        {
            // Mark escape attempt
            confrontation.escapeAttempted = true;

            // Emit 
            emit EscapeFail(msg.sender, attacker, confrontation.location);
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
            revert ConfrontationNotFound(msg.sender, address(0));
        }

        // Ensure that the response time has not expired (target)
        if (block.timestamp > confrontation.deadline) 
        {
            revert ResponseTimeExpired(msg.sender, confrontation.deadline);
        }

        // Do battle
        BattleData memory battleOutcome = IBattleMechanics(navalBattleMechanicsContract)
            .__quickBattle(msg.sender, confrontation.attacker, confrontation.location);

        // Attacker wins
        if (battleOutcome.victor == confrontation.attacker)
        {
            // Allow pirate to plunder
            plunders[confrontation.attacker][msg.sender].deadline = uint64(block.timestamp) + MAX_RESPONSE_TIME;

            // Extend freeze
            IPlayerFreezeControl(mapsContract).__freeze(msg.sender, confrontation.attacker, plunders[confrontation.attacker][msg.sender].deadline);
            IPlayerFreezeControl(intentoriesContract).__freeze(msg.sender, plunders[confrontation.attacker][msg.sender].deadline); 

            // Award XP
            IPlayerRegister(playerRegisterContract)
                .__award(confrontation.attacker, battleOutcome.player1_damageTaken, 0);
        }

        // Target wins
        else 
        {
            // Unfreeze players
            IPlayerFreezeControl(mapsContract).__unfreeze(msg.sender, confrontation.attacker);
            IPlayerFreezeControl(intentoriesContract).__unfreeze(msg.sender);

            // Award XP
            IPlayerRegister(playerRegisterContract)
                .__award(msg.sender, battleOutcome.player2_damageTaken, 0); 
        }

        // Mark confrontation as ended
        confrontations[msg.sender].expiration = 0;

        // Emit
        emit PirateConfrontationEnd(msg.sender, confrontation.attacker, confrontations[msg.sender].location);
    }


    /// @dev Allows the attacker to start a quick battle to resolve the confrontation
    /// @notice The attacker is allowed to start a quick battle if the response time has expired
    /// @notice The player that initiates the battle has and advantage over the other player in case of a tie
    function startQuickBattleAsAttacker()
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
            revert ResponseTimeNotExpired(target, confrontation.deadline);
        }

        // Do battle
        BattleData memory battleOutcome = IBattleMechanics(navalBattleMechanicsContract)
            .__quickBattle(msg.sender, target, confrontation.location);

        // Attacker wins
        if (battleOutcome.victor == msg.sender) 
        {
            // Allow attacker to plunder
            plunders[msg.sender][target].deadline = uint64(block.timestamp) + MAX_RESPONSE_TIME;

            // Extend freeze
            IPlayerFreezeControl(mapsContract).__freeze(target, msg.sender, plunders[msg.sender][target].deadline);
            IPlayerFreezeControl(intentoriesContract).__freeze(target, plunders[msg.sender][target].deadline);

            // Award XP
            IPlayerRegister(playerRegisterContract)
                .__award(msg.sender, battleOutcome.player2_damageTaken, 0);
        }

        // Target wins
        else 
        {
            // Unfreeze players
            IPlayerFreezeControl(mapsContract).__unfreeze(target, msg.sender);
            IPlayerFreezeControl(intentoriesContract).__unfreeze(target);

            // Award XP
            IPlayerRegister(playerRegisterContract)
                .__award(target, battleOutcome.player1_damageTaken, 0);
        }

        // Mark confrontation as ended
        confrontations[target].expiration = 0;

        // Emit
        emit PirateConfrontationEnd(target, msg.sender, confrontations[target].location);
    }


    /// @dev Allows the pirate to loot the target after winning a battle
    /// @param target The account of the target to plunder
    /// @param inventories_from The inventories in which the assets are located
    /// @param inventories_to The inventories to which the assets will be moved
    /// @param assets The assets that the pirate is looting
    /// @param amounts The amounts of the assets that the pirate is looting (in case of fungible assets)
    /// @param tokenIds The ids of the assets that the pirate is looting (in case of non-fungible assets)
    function plunder(address target, Inventory[] memory inventories_from, Inventory[] memory inventories_to, address[] memory assets, uint[] memory amounts, uint[] memory tokenIds)
        public override 
    {
        Plunder storage plunder_ = plunders[msg.sender][target]; 

        // Ensure that the response time has not expired
        if (block.timestamp > plunder_.deadline) 
        {
            revert ResponseTimeExpired(target, plunder_.deadline); 
        }

        // Ensure that the target was not already plundered
        if (plunder_.loot_hot > block.timestamp) 
        {
            revert TargetAlreadyPlundered(target);
        }

        // Generate randomness
        bytes32 randomness = _generateRandomSeed();

        // Luck plays a factor in the plunder
        uint luck = IPlayerRegister(playerRegisterContract)
            .getLuck(msg.sender);

        // Determine what to deduct from the plunder (drops in the ocean)
        uint score;
        for (uint i = 0; i < assets.length; i++) 
        {
            score = _getRandomNumberAt(randomness, i) + luck * LUCK_SCALING_FACTOR;
            if (score >= RANDOMNESS_PRECISION_FACTOR)
            {
                continue; // Nothing drops in the ocean
            }

            // Non-fungible asset
            if (0 != tokenIds[i]) 
            {
                if (score < BASE_PLUNDER_THRESHOLD)
                {
                    // Send to treasury
                    IInventories(intentoriesContract)
                        .__deductNonFungibleTokenUnchecked(
                            target, 
                            inventories_from[i], 
                            assets[i], 
                            tokenIds[i],
                            true); 

                    // Deduct from plunder
                    tokenIds[i] = 0;
                }
            }

            // Fungible asset
            else 
            {
                // Deduct from plunder based on score
                uint deduct = amounts[i] 
                    * BASE_PLUNDER_DEDUCTION_FACTOR 
                    * (RANDOMNESS_PRECISION_FACTOR - score) 
                    / (BASE_PLUNDER_DEDUCTION_FACTOR_PRECISION * RANDOMNESS_PRECISION_FACTOR);

                if (deduct > 0) 
                {
                    // Deduct from plunder
                    amounts[i] -= deduct;

                    // Send to treasury
                    IInventories(intentoriesContract)
                        .__deductFungibleTokenUnchecked(
                            target, 
                            inventories_from[i], 
                            assets[i], 
                            deduct, 
                            true);
                }
            }
        }

        // Create a hash of the loot mark the target as plundered
        plunder_.loot_hash = keccak256(abi.encode(
            keccak256(abi.encodePacked(assets)),
            keccak256(abi.encodePacked(amounts)),
            keccak256(abi.encodePacked(tokenIds))
        ));

        // Allows target to place a bounty on the pirate
        plunder_.deadline = uint64(block.timestamp) + MAX_RESPONSE_TIME;
        plunder_.loot_hot = plunder_.deadline; 

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

        // Unfreeze players
        IPlayerFreezeControl(mapsContract).__unfreeze(target, msg.sender);
        IPlayerFreezeControl(intentoriesContract).__unfreeze(target);

        // Emit
        emit PiratePlunderSuccess(target, msg.sender, assets, amounts, tokenIds);
    }
}