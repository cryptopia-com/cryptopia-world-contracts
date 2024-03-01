// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../source/game/inventories/concrete/CryptopiaInventories.sol";

/// @title Cryptopia Inventories Contract
/// @notice Manages player and ship inventories in Cryptopia, handling both fungible (ERC20) and non-fungible (ERC721) assets.
/// It allows for transferring, assigning, and deducting assets from inventories while managing their weight and capacity limits.
/// Integrates with ERC20 and ERC721 contracts for robust asset management within the game's ecosystem.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentInventories is CryptopiaInventories {

    /// @dev Remove inventory player data
    /// @param accounts The accounts to remove data from
    function cleanPlayerData(address[] calldata accounts) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < accounts.length; i++) 
        {
            _cleanInventorySpace(playerInventories[accounts[i]]);
            delete playerInventories[accounts[i]];
            delete playerToShip[accounts[i]];
            delete playerData[accounts[i]];
        }
    }


    /// @dev Remove inventory ship data
    /// @param tokenIds The ships to remove data from
    function cleanShipData(uint[] calldata tokenIds) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < tokenIds.length; i++) 
        {
            _cleanInventorySpace(shipInventories[tokenIds[i]]);
            delete shipInventories[tokenIds[i]];
        }
    }

    
    /// @dev Remove inventory asset data
    function cleanAssetData()
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        // Delete fungible assets
        for (uint i = 0; i < fungibleIndex.length; i++) 
        {
            delete fungible[fungibleIndex[i]];
        }

        delete fungibleIndex;

        // Delete non-fungible assets
        for (uint i = 0; i < nonFungibleIndex.length; i++) 
        {
            delete nonFungible[nonFungibleIndex[i]];
        }

        delete nonFungibleIndex;
    }


    /// @dev Remove inventory data
    /// @param space The inventory space to remove data from
    function _cleanInventorySpace(InventorySpaceData storage space) 
        internal 
    {
        for (uint i = 0; i < fungibleIndex.length; i++) 
        {
            delete space.fungible[fungibleIndex[i]];
        }

        for (uint i = 0; i < nonFungibleIndex.length; i++) 
        {
            address asset = nonFungibleIndex[i];
            NonFungibleTokenInventorySpaceData storage nftSpace = space.nonFungible[asset];
            for (uint j = 0; j < nftSpace.tokensIndex.length; j++) 
            {
                uint tokenId = nftSpace.tokensIndex[j];
                delete nonFungibleTokenDatas[asset][tokenId];
                delete nftSpace.tokens[tokenId];
                delete nftSpace.tokensIndex;
            }

            delete space.nonFungible[asset];
        }
    }
}