// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../../source/tokens/ERC721/concrete/ships/CryptopiaShipToken.sol";

/// @title Cryptopia Ship Token Contract
/// @notice Manages the creation, attributes, and interactions of ship tokens in Cryptopia.
/// This contract handles everything from ship minting, updating ship attributes, 
/// to managing different ship types and their specific characteristics like speed, 
/// health, and attack power. It supports various ship classes, aligns ships with 
/// game factions, and manages the special variants like pirate ships.
/// @dev Extends CryptopiaERC721, integrating ERC721 functionalities with game-specific mechanics.
/// It maintains a comprehensive dataset of ships through mappings, enabling intricate gameplay
/// strategies and in-game economics. The contract includes mechanisms for both the creation of 
/// new ship tokens and the dynamic modification of existing ships, reflecting the evolving nature 
/// of the in-game naval fleet.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentShipToken is CryptopiaShipToken {

    /// @dev Clean ship data
    /// @notice Does not implement batched removal because of the limited amount of items
    ///         in development and the upgradability of the contract
    function cleanShipData() 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < shipsIndex.length; i++) 
        {
            delete ships[shipsIndex[i]];
        }

        delete shipsIndex;
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
            delete shipInstances[i];
        }
    }
}