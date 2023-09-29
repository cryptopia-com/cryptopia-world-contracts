// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./ICryptopiaERC20.sol";

/// @title Cryptopia ERC20 
/// @notice Token that extends Openzeppelin ERC20Upgradeable
/// @dev Implements the ERC20 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
abstract contract CryptopiaERC20 is ICryptopiaERC20, Initializable, ERC20Upgradeable {

    /// @dev Contract initializer.
    /// @param name Token name (long).
    /// @param symbol Token ticker symbol (short).
    function __CryptopiaERC20_init(string memory name, string memory symbol) 
        internal onlyInitializing
    {
        __ERC20_init(name, symbol);
    }
}