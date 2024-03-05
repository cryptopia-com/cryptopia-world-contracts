// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/// @title Cryptopia entry point
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaEntry is ContextUpgradeable {

    /**
     * Storage
     */
    struct ContractVersion 
    {
        uint8 major;
        uint8 minor;
        uint8 patch;
    }

    ContractVersion public version;


    /** 
     * Public functions
     */
    /// @dev Initialize the contract
    /// @param _version The version of the contract
    function initialize(ContractVersion memory _version) 
        public virtual initializer 
    {
        __Context_init();

        version = _version;
    }
}