// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @title Cryptopia Blueprints
/// @notice Non-fungible token that represends blueprints in Cryptopia
/// @dev Implements the ERC721 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IBlueprints {

    /**
     * Public functions
     */
    /// @dev Retrieves the building of the blueprint with `tokenId`
    /// @param tokenId The blueprint token ID
    /// @return structure unique name
    function getBuilding(uint tokenId) 
        external view
        returns(bytes32);


    /**
     * System functions
     */
    /// @dev Destroys `tokenId`.
    /// @notice The approval is cleared when the token is burned.
    /// @notice This is an internal function that does not check if the sender is authorized to operate on the token.
    /// @param tokenId The blueprint token ID 
    function __burn(uint tokenId) 
        external;
}