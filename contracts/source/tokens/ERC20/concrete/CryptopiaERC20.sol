// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./CryptopiaERC20Retriever.sol";

/// @title Cryptopia ERC20 
/// @notice Token that extends Openzeppelin ERC20Upgradeable
/// @dev Implements the ERC20 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
abstract contract CryptopiaERC20 is Initializable, ERC20Upgradeable, AccessControlUpgradeable, CryptopiaERC20Retriever {

    /**
     * Roles
     */
    bytes32 constant internal SYSTEM_ROLE = keccak256("SYSTEM_ROLE");
    

    /// @dev Contract initializer
    /// @param name Token name (long)
    /// @param symbol Token ticker symbol (short)
    function __CryptopiaERC20_init(string memory name, string memory symbol) 
        internal onlyInitializing
    {
        __AccessControl_init();
        __ERC20_init(name, symbol);
        __CryptopiaERC20_init_unchained();
    }


    /// @dev Contract Initializer (unchained)
    function __CryptopiaERC20_init_unchained() 
        internal onlyInitializing
    {
        // msg.sender becomes admin by default
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /** 
     * Admin functions
     */
    /// @dev Failsafe mechanism
    /// Allows the owner to retrieve tokens from the contract that 
    /// might have been send there by accident
    /// @param tokenContract The address of ERC20 compatible token
    function retrieveTokens(address tokenContract) 
        override public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        super.retrieveTokens(tokenContract);
    }
}