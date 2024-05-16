// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../../source/tokens/ERC721/concrete/ships/CryptopiaShipSkinToken.sol";

/// @title Cryptopia Ship Token Contract
/// @notice Skins that can be applied to ships to change their appearance
/// @dev Extends CryptopiaERC721, integrating ERC721 functionalities with game-specific mechanics.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentShipSkinToken is CryptopiaShipSkinToken {

    /// @dev Clean skin data
    /// @notice Does not implement batched removal because of the limited amount of items
    ///         in development and the upgradability of the contract
    function cleanShipData() 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < skinsIndex.length; i++) 
        {
            delete skins[skinsIndex[i]];
        }

        delete skinsIndex;
    }


    /// @dev Removes all token data for `skip` to `skip` + `take`
    /// @param skip The index to start cleaning from
    /// @param take The amount of items to clean
    function cleanTokenData(uint skip, uint take) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        skip = skip + 1; // Convert to 1-based token ids
        for (uint i = skip; i < skip + take; i++) 
        {
            delete skinInstances[i];
        }
    }
}