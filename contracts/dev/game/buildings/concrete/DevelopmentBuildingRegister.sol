// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../source/game/buildings/concrete/CryptopiaBuildingRegister.sol";

/// @title Cryptopia Buildings Register
/// @notice This contract serves as the central registry for all buildings within Cryptopia, providing mechanisms 
/// to manage building data, instances, and construction progress.
/// 
/// The registry facilitates operations such as querying building data, retrieving construction details, 
/// and managing instances across tiles. Additionally, it supports system-level operations like initiating, 
/// progressing, and destroying constructions.
///
/// @dev Inherits from Initializable, AccessControlUpgradeable, and implements the IBuildingRegister interface.
/// It uses modular patterns to maintain code clarity and upgradeability, ensuring compatibility with evolving game requirements.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentBuildingRegister is CryptopiaBuildingRegister {

    /// @dev Clean building data
    /// @notice Does not implement batched removal because of the limited amount of items
    ///         in development and the upgradability of the contract
    function cleanBuildingData() 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        // Delete assets
        for (uint i = 0; i < buildingsIndex.length; i++) 
        {
            delete buildings[buildingsIndex[i]];
        }

        delete buildingsIndex;
    }


    /// @dev Removes all building instance data for `tileIndices`
    /// @param tileIndices The tile indices to clean
    function cleanBuildingInstanceData(uint16[] memory tileIndices) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < tileIndices.length; i++)
        {
            delete buildingInstances[tileIndices[i]];
        }
    }


    /// @dev Removes all mapping data for `tileGroupIndices`
    /// @param tileGroupIndices The tile group indices to clean
    function cleanGroupToDockData(uint16[] memory tileGroupIndices) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < tileGroupIndices.length; i++)
        {
            delete tileGroupToDock[tileGroupIndices[i]];
        }
    }
}