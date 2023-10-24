// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../CryptopiaERC20.sol";
import "../../assets/IAssetToken.sol";

/// @title Cryptopia Asset Token
/// @notice Cryptoipa asset such as natural resources.
/// @dev Implements the ERC20 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaAssetToken is CryptopiaERC20, IAssetToken {

    /// @dev Contract Initializer
    /// @param name Token name
    /// @param symbol Token symbol
    function initialize(string memory name, string memory symbol) 
        public initializer 
    {
        __CryptopiaERC20_init(name, symbol);
    }

    /// @dev Mints 'amount' token to an address
    /// @param to Account to mint the tokens for
    /// @param amount Amount of tokens to mint
    function mintTo(address to, uint amount) 
        public override 
        onlyRole(MINTER_ROLE) 
    {
        _mint(to, amount);
    }
}