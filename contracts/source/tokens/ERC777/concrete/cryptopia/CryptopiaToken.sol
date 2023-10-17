// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../cryptopia/ICryptopiaToken.sol";
import "../CryptopiaERC777.sol";

/// @title Cryptopia Token 
/// @notice Game currency used in Cryptoipa
/// @dev Implements the ERC777 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaToken is CryptopiaERC777, ICryptopiaToken {

    /**
     * Roles
     */
    bytes32 constant private MINTER_ROLE = keccak256("MINTER_ROLE");


    /*
     * Public functions
     */
    /// @dev Contract Initializer
    /// @param defaultOperators These accounts are operators for all token holders, even if authorizeOperator was never called on them
    /// @param authenticator Whiteliste for transfer
    function initialize(address[] memory defaultOperators, address authenticator) 
        public initializer 
    {
        __CryptopiaERC777_init(
            "Cryptopia Token", "CRT", defaultOperators, authenticator);
    }


    /// @dev Mints 'amount' token to an address
    /// @param to Account to mint the tokens for
    /// @param amount Amount of tokens to mint
    function mintTo(address to, uint amount) 
        public override 
        onlyRole(MINTER_ROLE) 
    {
        _mint(to, amount, "", "");
    }
}