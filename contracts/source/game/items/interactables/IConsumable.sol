// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../assets/types/AssetEnums.sol";

/// @title Allows players to consume 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IConsumable {

    /// @dev Consume an item
    /// @param tokenId The id of the item to consume
    function consume(uint tokenId) 
        external; 
}