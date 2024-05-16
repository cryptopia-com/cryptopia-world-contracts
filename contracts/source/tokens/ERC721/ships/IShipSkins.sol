// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "./types/ShipSkinDataTypes.sol";

/// @title Cryptopia Ship Skin Token Contract
/// @notice Skins that can be allpied to ships to change their appearance
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IShipSkins {

    /**
     * Public functions
     */
    /// @dev Returns the amount of different skins
    /// @return count The amount of different skins
    function getSkinCount() 

        external view 
        returns (uint);


    /// @dev Retreive a skin by name
    /// @param _name Skin name (unique)
    /// @return skin a single skin 
    function getSkin(bytes32 _name) 
        external view 
        returns (ShipSkin memory skin);


    /// @dev Retreive a skin by index
    /// @param index The index of the skin to retreive
    /// @return skin a single skin
    function getSkinAt(uint index) 
        external view 
        returns (ShipSkin memory skin);


    /// @dev Retreive a rance of skins
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return skins range of skins
    function getSkins(uint skip, uint take) 
        external view 
        returns (ShipSkin[] memory skins);


    /// @dev Retreive a skin by token id
    /// @param tokenId The id of the skin to retreive
    /// @return instance a single skin instance
    function getSkinInstance(uint tokenId) 
        external view 
        returns (ShipSkinInstance memory instance);

    
    /// @dev Retreive skins by token ids
    /// @param tokenIds The ids of the skins to retreive
    /// @return instances a range of skin instances
    function getSkinInstances(uint[] memory tokenIds) 
        external view 
        returns (ShipSkinInstance[] memory instances);


    /**
     * System functions
     */
    /// @dev Burn a skin
    /// @param tokenId The id of the skin to burn
    function __burn(uint tokenId)
        external;
}