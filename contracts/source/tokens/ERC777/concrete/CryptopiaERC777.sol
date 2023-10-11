// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../authentication/IAuthenticator.sol";
import "../../ERC20/retriever/TokenRetriever.sol";
import "../IERC777.sol";

/// @title Cryptopia ERC777 
/// @notice Token that extends Openzeppelin ERC777
/// @dev Implements the ERC777 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
abstract contract CryptopiaERC777 is ERC777Upgradeable, AccessControlUpgradeable, TokenRetriever, IERC777 {

    /// Refs
    IAuthenticator public authenticator;
    

    /// @dev Contract Initializer
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param defaultOperators These accounts are operators for all token holders, even if authorizeOperator was never called on them.
    /// @param _authenticator Whiteliste for transfer
    function __CryptopiaERC777_init(string memory name, string memory symbol, address[] memory defaultOperators, address _authenticator) 
        internal onlyInitializing
    {
        __AccessControl_init();
        __ERC777_init(name, symbol, defaultOperators);
        __CryptopiaERC777_init_unchained(_authenticator);
    }


    /// @dev Contract Initializer (unchained)
    /// @param _authenticator Whiteliste for transfer
    function __CryptopiaERC777_init_unchained(
        address _authenticator) 
        internal onlyInitializing
    {
        authenticator = IAuthenticator(_authenticator);

        // msg.sender becomes admin by default
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * @dev See {IERC20-transferFrom}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Note that operator and allowance concepts are orthogonal: operators cannot
     * call `transferFrom` (unless they have allowance), and accounts with
     * allowance cannot call `operatorSend` (unless they are operators).
     *
     * Emits {Sent}, {IERC20-Transfer} and {IERC20-Approval} events.
     */
    function transferFrom(address holder, address recipient, uint256 amount) 
        public virtual override 
        returns (bool) 
    {
        if (authenticator.authenticate(msg.sender)) 
        {
            _send(holder, recipient, amount, "", "", false);
            return true;
        }
        
        return super.transferFrom(holder, recipient, amount);
    }


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