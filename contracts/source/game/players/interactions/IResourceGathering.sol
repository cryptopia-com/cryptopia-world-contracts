// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../assets/types/AssetEnums.sol";

/// @title Allows players to gather resoures from the map
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IResourceGathering {

    /// @dev Mint `asset` to sender's inventory
    /// @param resource The {AssetEnums} to mint 
    /// @param tool The token ID of the tool used to mint the resource (0 means no tool)
    /// @param max The maximum amount of tokens to mint (limit to prevent full backpack)
    function mint(Resource resource, uint tool, uint max) 
        external; 
}