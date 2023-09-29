// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../CryptopiaERC777.sol";

/// @title Cryptopia Token 
/// @notice Game currency used in Cryptoipa
/// @dev Implements the ERC777 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaToken is CryptopiaERC777 {

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


    /// @dev TODO: Implement security (access control: https://forum.openzeppelin.com/t/erc777-contract-best-practice/2912)
    /// @param account Account to mint the tokens for.
    /// @param amount Amount of tokens to mint.
    function mint(address account, uint256 amount) 
        public
    {
        _mint(account, amount, "", "");
    }
}