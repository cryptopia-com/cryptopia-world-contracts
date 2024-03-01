// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <stefan.george@consensys.net> (modified by Frank Bonnet <frankbonnet@outlook.com>)
interface IMultiSigWallet {

    /// @dev Allows anyone to execute a transaction with off-chain signatures
    /// @param signatures Array of signatures
    /// @param deadline Deadline in unix timestamp
    /// @param destination Transaction target address
    /// @param value Transaction value in wei
    /// @param data Transaction data payload
    /// @return transactionId Returns transaction ID
    /// @return success Returns if the transaction was executed
    function executeTransaction(bytes[] memory signatures, uint deadline, address destination, uint value, bytes memory data)
        external 
        returns (uint transactionId, bool success);

    
    /// @dev Returns true if the signatures are valid and satisfy the requirements of the multisig wallet
    /// @param _hash Hash of the signed data
    /// @param signatures Array of signatures
    /// @return Returns true if enough valid signatures are provided
    function isValidSignatureSet(bytes32 _hash, bytes[] memory signatures)
        external view
        returns (bool);
}
