// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../source/CryptopiaEntry.sol";

/// @title Cryptopia entry point
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentEntry is CryptopiaEntry, AccessControlUpgradeable {

    /// @dev Initializer
    /// @param _version The version of the contract
    function initialize(ContractVersion memory _version)
        public override initializer 
    {
        CryptopiaEntry.initialize(_version);

        __AccessControl_init();

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    

    /// @dev Set the version of the contract
    /// @param _version The version of the contract
    function setVersion(ContractVersion calldata _version) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        version = _version;
    }
}