// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @title Cryptopia pirate game mechanics
/// @dev Provides the mechanics for the pirate gameplay
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IPirateMechanics {

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
        external;
}