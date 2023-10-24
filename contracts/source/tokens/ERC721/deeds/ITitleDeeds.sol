// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @title ITitleDeeds
/// @notice Non-fungible token that represends land ownership in Cryptopia
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ITitleDeeds {

    /// @dev Increase the max supply
    /// @param increment Number to increment max supply with
    function increaseLimit(uint increment) 
        external;


    /// @dev Retrieves the zero based tile index of the title deed with `tokenId`
    /// @param tokenId The title deed token ID
    /// @return tile index (zero based)
    function getTile(uint tokenId) 
        external view 
        returns(uint32);


    /// @dev Retrieve a range of owners
    /// @param skip Starting index
    /// @param take Amount of owners
    /// @return owners Token owners
    function getOwners(uint skip, uint take) 
        external view 
        returns (address[] memory owners);


    /// @dev Mints a token to msg.sender. Coordinates can be found with (x, y) = (index % mapwidth, index / mapWidth) 
    /// @param tokenId Unique token id and tile identifier.
    function claim(uint tokenId) 
        external;


    /// @dev Mints a token to account. Coordinates can be found with (x, y) = (index % mapwidth, index / mapWidth) 
    /// @param tokenId Unique token id and tile identifier.
    /// @param account Account to mint the token to
    function claimFor(uint tokenId, address account) 
        external;
}