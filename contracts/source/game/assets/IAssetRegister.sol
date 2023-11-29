// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "./types/AssetEnums.sol";

/// @title Cryptopia asset register
/// @dev Cryptopia assets register that holds refs to assets such as natural resources and fabricates
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IAssetRegister {

    /**
     * Public functions
     */
    /// @dev Retreives the amount of assets.
    /// @return count Number of assets.
    function getAssetCount()
        external view 
        returns (uint count);


    /// @dev Retreives the asset at `index`.
    /// @param index Asset index.
    /// @return contractAddress Address of the asset.
    function getAssetAt(uint index)
        external view 
        returns (address contractAddress);


    /// @dev Retreives the assets from `cursor` to `cursor` plus `length`.
    /// @param cursor Starting index.
    /// @param length Amount of assets to return.
    /// @return contractAddresses Addresses of the assets.
    function getAssets(uint cursor, uint length)
        external view 
        returns (address[] memory contractAddresses);


    /// @dev Retreives asset and balance info for `account` from the asset at `index`.
    /// @param index Asset index.
    /// @param accounts Accounts to retrieve the balances for.
    /// @return contractAddress Address of the asset.
    /// @return name Address of the asset.
    /// @return symbol Address of the asset.
    /// @return balances Ballances of `accounts` the asset.
    function getAssetInfoAt(uint index, address[] memory accounts)
        external view 
        returns (
            address contractAddress, 
            string memory name, string 
            memory symbol, 
            uint[] memory balances);


    /// @dev Retreives asset and balance infos for `accounts` from the assets from `cursor` to `cursor` plus `length`. Has limitations to avoid experimental.
    /// @param cursor Starting index.
    /// @param length Amount of asset infos to return.
    /// @param accounts Accounts to retrieve the balances for.
    /// @return contractAddresses Address of the asset.
    /// @return names Address of the asset.
    /// @return symbols Address of the asset.
    /// @return balances1 Asset balances of accounts[0].
    /// @return balances2 Asset balances of accounts[1].
    /// @return balances3 Asset balances of accounts[2].
    function getAssetInfos(uint cursor, uint length, address[] memory accounts)
        external view 
        returns (
            address[] memory contractAddresses, 
            bytes32[] memory names, 
            bytes32[] memory symbols, 
            uint[] memory balances1, 
            uint[] memory balances2, 
            uint[] memory balances3);

        
    /// @dev Getter for resources
    /// @param resource {Resource}
    /// @return address The resource asset contract address 
    function getAssetByResrouce(Resource resource) 
        external view   
        returns (address);


    /**
     * System functions
     */
    /// @dev Register an asset
    /// @param asset Contact address
    /// @param isResource true if `asset` is a resource
    /// @param resource {Resource}
    function __registerAsset(address asset, bool isResource, Resource resource) 
        external;
}