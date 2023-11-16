// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../inventories/types/InventoryEnums.sol";

/// @title Cryptopia pirate game mechanics
/// @dev Provides the mechanics for the pirate gameplay
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IPirateMechanics {

    /// @dev Get confrontation data
    /// @param target The account of the defender
    /// @return attacker The account of the pirate
    /// @return location The location at which the confrontation took place
    /// @return deadline The deadline for the target to respond
    /// @return expiration The timestamp after which the confrontation expires (can be extended by the target)
    function getConfrontation(address target)
        external view 
        returns (
            address attacker,
            uint16 location,
            uint64 deadline,
            uint64 expiration
        );
        

    /// @dev Intercepts the target at the specified location
    /// @param target The account of the defender
    /// @param indexInRoute The index of the tile in the route that the target is traveling
    /// 
    /// @notice Requirements:
    /// - The attacker must have entered the map
    /// - The attacker must not be traveling
    /// - The attacker must be embarked
    /// - The attacker must not be already intercepting a target
    /// - The attacker must have enough fuel to intercept the target
    /// - The target must have entered the map
    /// - The target must be reachable from the attacker's location (either by route or location)
    /// - The target must not be already intercepted
    function intercept(address target, uint indexInRoute) 
        external;

    
    /// @dev Attacker accepts the offer from the target to resolve the confrontation
    /// @param signatures Array of signatures authorizing the attacker to accept the offer
    /// @param inventories_from The inventories in which the assets are located
    /// @param inventories_to The inventories to which the assets will be moved
    /// @param assets The assets that the target is willing to offer
    /// @param amounts The amounts of the assets that the target is willing to offer
    /// @param tokenIds The ids of the assets that the target is willing to offer
    function acceptOffer(bytes[] memory signatures, Inventory[] memory inventories_from, Inventory[] memory inventories_to, address[] memory assets, uint[] memory amounts, uint[] memory tokenIds)
        external;


    /// @dev The escape calculation is based on a combination of randomness, ship speed differences, and 
    /// player luck differences. A base score is generated using a pseudo-random seed. To this base score, 
    /// we add the scaled difference in ship speeds and player luck values. 
    /// @notice The final score determines the outcome of the escape attempt:
    /// - If the score is greater than or equal to the BASE_ESCAPE_THRESHOLD, the escape is successful
    /// - Otherwise, the escape fails
    /// @notice Factors like ship speed and player luck play a crucial role in influencing the escape outcome, 
    /// ensuring that players with faster ships and higher luck values have a better chance of escaping
    function attemptEscape() 
        external;


    /// @dev Allows the target to start a quick battle to resolve the confrontation
    /// @notice The target is allowed to start a quick battle if the response time has not yet expired
    /// @notice The player that initiates the battle has and advantage over the other player in case of a tie
    function startQuickBattleAsTarget() 
       external;


    /// @dev Allows the pirate to start a quick battle to resolve the confrontation
    /// @notice The pirate is allowed to start a quick battle if the response time has expired
    /// @notice The player that initiates the battle has and advantage over the other player in case of a tie
    function startQuickBattleAsAttacker() 
       external;


    // function startTurnBasedBattle() 
    //     external;
}