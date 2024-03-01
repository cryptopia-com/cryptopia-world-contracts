// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../source/game/maps/concrete/CryptopiaMaps.sol";

/// @title Cryptopia Maps
/// @dev Contains world data and player positions
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentMaps is CryptopiaMaps {

    /// @dev Remove map data
    /// @notice Cleaning all maps is feasaible currently becuase there is a limited number of maps in development
    function cleanMapData() 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < mapsIndex.length; i++) 
        {
            delete maps[mapsIndex[i]];
        }

        delete mapsIndex;
    }

    /// @dev Remove tile data
    /// @param skip The number of tiles
    /// @param take The number of tiles to clean
    function cleanTileData(uint16 skip, uint16 take) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint16 i = skip; i < skip + take; i++) 
        {
            for (uint j = 0; j < tileDataStatic[i].resourcesIndex.length; j++) 
            {
                Resource resource = tileDataStatic[i].resourcesIndex[j];
                delete tileDataStatic[i].resources[resource];
                delete tileDataDynamic[i].resources[resource];
            }

            delete tileDataStatic[i].resourcesIndex;

            delete tileDataStatic[i];
            delete tileDataDynamic[i];
            delete movementPenaltyCache[i];
        }
    }

    /// @dev Remove player data
    /// @param accounts The accounts to clean
    function cleanPlayerData(address[] calldata accounts) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < accounts.length; i++) 
        {
            delete playerData[accounts[i]];
        }
    }
}