// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../CryptopiaERC777.sol";
import "../../assets/IAssetToken.sol";

/// @title Cryptopia Asset Token
/// @notice Cryptoipa asset such as natural resources.
/// @dev Implements the ERC777 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaAssetToken is CryptopiaERC777, IAssetToken {

    /**
     * Roles
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    /*
     * Public functions
     */
    /// @dev Contract Initializer
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param defaultOperators These accounts are operators for all token holders, even if authorizeOperator was never called on them.
    /// @param authenticator Whiteliste for transfer
    function initialize(string memory name, string memory symbol, address[] memory defaultOperators, address authenticator) 
        public initializer 
    {
        __CryptopiaERC777_init(name, symbol, defaultOperators, authenticator);
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