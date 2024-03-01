// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../source/game/assets/concrete/CryptopiaAssetRegister.sol";

/// @title Cryptopia asset register
/// @dev Cryptopia assets register that holds refs to assets such as natural resources and fabricates
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentAssetRegister is CryptopiaAssetRegister {

    /// @dev Remove the data from the register
    function clean() 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        // Delete assets
        for (uint i = 0; i < assetsIndex.length; i++) 
        {
            delete assets[assetsIndex[i]];
        }

        delete assetsIndex;

        // Delete resources
        for (uint i = 0; i <= uint(type(Resource).max); i++) 
        {
            delete resources[Resource(i)];
        }
    }
}