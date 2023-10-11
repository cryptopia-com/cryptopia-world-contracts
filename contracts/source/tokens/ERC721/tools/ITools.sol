// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../../game/types/GameEnums.sol";
import "../../../game/assets/types/AssetEnums.sol";

/// @title Tools 
/// @dev Non-fungible token (ERC721) 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ITools {

    /// @dev Returns the amount of different tools
    /// @return count The amount of different tools
    function getToolCount() 
        external view 
        returns (uint);


    /// @dev Retreive a tools by name
    /// @param name Tool name (unique)
    /// @return rarity Tool rarity {Rarity}
    /// @return level Tool level (determins where the tool can be used and by who)
    /// @return durability The higher the durability the less damage is taken each time the tool is used
    /// @return multiplier_cooldown The lower the multiplier_cooldown the faster an action can be repeated
    /// @return multiplier_xp The base amount of XP is multiplied by this value every time the tool is used
    /// @return multiplier_effectiveness The effect that the tool has is multiplied by this value. Eg. a value of 2 while fishing at a depth of 3 will give the user 6 fish
    /// @return value1 Tool specific value 
    /// @return value2 Tool specific value 
    function getTool(bytes32 name) 
        external view 
        returns (
            Rarity rarity,
            uint8 level, 
            uint24 durability,
            uint24 multiplier_cooldown,
            uint24 multiplier_xp,
            uint24 multiplier_effectiveness,
            uint24 value1,
            uint24 value2
        );


    /// @dev Retreive a rance of tools
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return name Tool name (unique)
    /// @return rarity Tool rarity {Rarity}
    /// @return level Tool level (determins where the tool can be used and by who)
    /// @return durability The higher the durability the less damage is taken each time the tool is used
    /// @return multiplier_cooldown The lower the multiplier_cooldown the faster an action can be repeated
    /// @return multiplier_xp The base amount of XP is multiplied by this value every time the tool is used
    /// @return multiplier_effectiveness The effect that the tool has is multiplied by this value. Eg. a value of 2 while fishing at a depth of 3 will give the user 6 fish
    /// @return value1 Tool specific value 
    /// @return value2 Tool specific value 
    function getTools(uint skip, uint take) 
        external view 
        returns (
            bytes32[] memory name,
            Rarity[] memory rarity,
            uint8[] memory level, 
            uint24[] memory durability,
            uint24[] memory multiplier_cooldown,
            uint24[] memory multiplier_xp,
            uint24[] memory multiplier_effectiveness,
            uint24[] memory value1,
            uint24[] memory value2
        );


    /// @dev Add or update tools
    /// @param name Tool name (unique)
    /// @param rarity Tool rarity {Rarity}
    /// @param level Tool level (determins where the tool can be used and by who)
    /// @param stats durability, multiplier_cooldown, multiplier_xp, multiplier_effectiveness
    /// @param minting_resources The resources {ResourceType} that can be minted with the tool
    /// @param minting_amounts The max amounts of resources that can be minted with the tool
    function setTools(
        bytes32[] memory name, 
        Rarity[] memory rarity, 
        uint8[] memory level,
        uint24[7][] memory stats,
        ResourceType[][] memory minting_resources,
        uint[][] memory minting_amounts) 
        external;


    /// @dev Retreive a tools by token id
    /// @param tokenId The id of the tool to retreive
    /// @return name Tool name (unique)
    /// @return rarity Tool rarity {Rarity}
    /// @return level Tool level (determins where the tool can be used and by who)
    /// @return damage The amount of damage the tool has taken (100_00 renders the tool unusable)
    /// @return durability The higher the durability the less damage is taken each time the tool is used
    /// @return multiplier_cooldown The lower the multiplier_cooldown the faster an action can be repeated
    /// @return multiplier_xp The base amount of XP is multiplied by this value every time the tool is used
    /// @return multiplier_effectiveness The effect that the tool has is multiplied by this value. Eg. a value of 2 while fishing at a depth of 3 will give the user 6 fish
    /// @return value1 Tool specific value 
    /// @return value2 Tool specific value 
    function getToolInstance(uint tokenId) 
        external view 
        returns (
            bytes32 name,
            Rarity rarity,
            uint8 level, 
            uint24 damage,
            uint24 durability,
            uint24 multiplier_cooldown,
            uint24 multiplier_xp,
            uint24 multiplier_effectiveness,
            uint24 value1,
            uint24 value2
        );


    /// @dev Applies tool effects to the `cooldown` period and the `amount` of `resource` that's being minted by `player`
    /// @param player The account that's using the tool for minting
    /// @param toolId The token ID of the tool being used to mint 
    /// @param resource The resource {ResourceType} that's being minted
    /// @param amount The amount of tokens to be minted; checked against value1
    function useForMinting(address player, uint toolId, ResourceType resource, uint amount) 
        external  
        returns (
            uint24 multiplier_cooldown,
            uint24 multiplier_xp,
            uint24 multiplier_effectiveness
        );
}