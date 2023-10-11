// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title ITokenRetriever
/// @notice Interface for retrieving tokens from a contract.
/// @author Frank Bonnet
interface ITokenRetriever {

    /// @notice Extracts tokens from the contract.
    /// @param _tokenContract The address of the ERC20 compatible token.
    function retrieveTokens(address _tokenContract) external;
}