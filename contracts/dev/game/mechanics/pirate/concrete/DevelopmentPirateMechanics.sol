// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../../../source/game/mechanics/pirate/concrete/CryptopiaPirateMechanics.sol";

/// @title Cryptopia Pirate Game Mechanics
/// @notice This contract governs the core pirate interactions within Cryptopia. 
/// It orchestrates various pirate-related activities such as intercepting targets, negotiating confrontations,
/// attempting escapes, and executing plunder operations. The contract integrates advanced game mechanics 
/// and decision-making processes, enhancing the immersive pirate experience for players.
/// The mechanics ensure a dynamic and strategic environment where players' decisions and actions 
/// significantly impact their gaming journey. This contract, being a central piece of the Cryptopia gaming ecosystem,
/// interacts with multiple other contracts for managing player data, inventory, map movements, and battle outcomes.
/// @dev Inherits from Initializable, NoncesUpgradeable, PseudoRandomness, and implements IPirateMechanics interface.
/// It utilizes upgradable patterns for long-term scalability and improvement, ensuring future compatibility 
/// with evolving game features. The contract also incorporates pseudo-randomness for unpredictable game outcomes,
/// adding an element of surprise and challenge. The contract's functions are designed to handle complex game interactions 
/// efficiently, maintaining game integrity and fairness.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentPirateMechanics is CryptopiaPirateMechanics, AccessControlUpgradeable {

    /// @dev Initializer
    /// @param _navalBattleMechanicsContract The address of the naval battle mechanics contract
    /// @param _playerRegisterContract The address of the player register
    /// @param _assetRegisterContract The address of the asset register
    /// @param _mapsContract The address of the maps contract
    /// @param _shipContract The address of the ship contract
    /// @param _fuelContact The address of the fuel contract
    /// @param _intentoriesContract The address of the inventories contract
    function initialize(
        address _navalBattleMechanicsContract,
        address _playerRegisterContract,
        address _assetRegisterContract,
        address _mapsContract,
        address _shipContract,
        address _fuelContact,
        address _intentoriesContract) 
        public override initializer 
    {
        CryptopiaPirateMechanics.initialize(
            _navalBattleMechanicsContract,
            _playerRegisterContract,
            _assetRegisterContract,
            _mapsContract,
            _shipContract,
            _fuelContact,
            _intentoriesContract);

        __AccessControl_init();

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /// @dev Remove the data 
    /// @param accounts The accounts to remove data from
    function clean(address[] calldata accounts) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < accounts.length; i++) 
        {
            delete targets[accounts[i]];
            delete confrontations[accounts[i]];
        }
    }
}