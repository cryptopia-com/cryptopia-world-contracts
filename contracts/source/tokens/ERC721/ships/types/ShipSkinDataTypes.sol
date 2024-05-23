// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @dev Skin for a ship in Cryptopia
struct ShipSkin
{
    /// @dev Unique name identifier for the skin
    bytes32 name;

    /// @dev The name of the ship that this skin is for
    bytes32 ship;
}

/// @dev Skin instance for a ship in Cryptopia
struct ShipSkinInstance
{
    /// @dev The token id of the skin 
    uint tokenId;

    /// @dev The address that owns this skin 
    address owner;

    /// @dev The index of the skin
    uint16 index;

    /// @dev Unique name identifier for the skin
    bytes32 name;

    /// @dev The name of the ship that this skin is for
    bytes32 ship;
}