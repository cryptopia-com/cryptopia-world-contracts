// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../../source/tokens/ERC721/concrete/blueprints/CryptopiaBlueprintToken.sol";

/// @title Cryptopia Blueprints
/// @notice Non-fungible token that represends blueprints in Cryptopia
/// @dev Implements the ERC721 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentBlueprintToken is CryptopiaBlueprintToken {

    /// @dev Removes all token data for `skip` to `skip` + `take`
    /// @param skip The index to start cleaning from
    /// @param take The amount of items to clean
    function cleanTokenData(uint skip, uint take)
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        skip = skip + 1; // Convert to 1-based token ids
        for (uint i = skip; i < skip + take; i++) 
        {
            delete blueprintInstances[i];
        }
    }
}