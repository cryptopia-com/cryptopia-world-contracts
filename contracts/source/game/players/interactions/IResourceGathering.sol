// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../assets/types/AssetEnums.sol";

/// @title Allows players to gather resoures from the map
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IResourceGathering {

    /// @dev Returns the timestamp at which `player` can mint `resource` again
    /// @param player The account to retrieve the cooldown timestamp for
    /// @param resource The resource to retrieve the cooldown timestamp for
    /// @return uint Cooldown timestamp at which `player` can mint `resource` again
    function getCooldown(address player, ResourceType resource) 
        external view 
        returns (uint);
 

    /// @dev Mint `asset` to sender's inventory
    /// @param resource The {AssetEnums} to mint 
    /// @param tool The token ID of the tool used to mint the resource (0 means no tool)
    /// @param max The maximum amount of tokens to mint (limit to prevent full backpack)
    function mint(ResourceType resource, uint tool, uint max) 
        external; 
}