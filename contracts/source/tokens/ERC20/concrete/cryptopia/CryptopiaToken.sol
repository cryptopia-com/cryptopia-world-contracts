// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../cryptopia/ICryptopiaToken.sol";
import "../CryptopiaERC20.sol";

/// @title Cryptopia Token 
/// @notice Game currency used in Cryptoipa
/// @dev Implements the ERC20 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaToken is CryptopiaERC20, ICryptopiaToken {

    /// @dev Contract Initializer
    function initialize() 
        public virtual initializer 
    {
        __CryptopiaERC20_init(
            "Cryptos", "TOS");
    }


    /**
     * System functions
     */
    /// @dev Mints 'amount' token to an address
    /// @param to Account to mint the tokens for
    /// @param amount Amount of tokens to mint
    function __mintTo(address to, uint amount) 
        public override 
        onlyRole(SYSTEM_ROLE) 
    {
        _mint(to, amount);
    }
}