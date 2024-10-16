// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../IMapsFeatures.sol";

/// @title Features extension for the Maps contract
/// @dev Responsible for managing the features on maps such as buildings
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaMapsFeatures is Initializable, IMapsFeatures {

    /**
     * Storage
     */
    address public mapsContract;


    /// @dev Initialize
    /// @param _mapsContract Maps contract
    function initialize(
        address _mapsContract)
        public initializer 
    {
        mapsContract = _mapsContract;
    }


    /**
     * Public functions
     */
}