// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @title IERC20Retriever
/// @notice Interface for retrieving tokens from a contract.
/// @author Frank Bonnet
interface IERC20Retriever {

    /// @notice Extracts tokens from the contract.
    /// @param _tokenContract The address of the ERC20 compatible token.
    function retrieveTokens(address _tokenContract) external;
}