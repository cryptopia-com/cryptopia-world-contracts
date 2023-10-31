// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../../errors/ArgumentErrors.sol";
import "../../multisig/IMultiSigWallet.sol";

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <stefan.george@consensys.net> (modified by Frank Bonnet <frankbonnet@outlook.com>)
contract MultiSigWallet is Initializable, EIP712Upgradeable, ReentrancyGuard, IMultiSigWallet, IERC1271 {

    struct Transaction 
    {
        /// @dev true if the transaction has been executed (and succeeded)
        bool executed;

        /// @dev address of the destination for the transaction
        address destination;

        /// @dev amount of native tokens in wei sent with the transaction
        uint value;

        /// @dev data of the transaction
        bytes data;
    }

    /** 
     * Storage
     */
    uint constant internal MAX_OWNER_COUNT = 5;

    /// @dev bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;

    /// @dev Execute transaction with signatures
    bytes32 constant internal EIP712_TRANSACTION_SCHEMA_HASH = keccak256(
        "ExecuteTransaction(address account, address destination, uint value, bytes data, uint nonce, uint deadline)");

    // Config
    uint public required;
    uint public transactionCount;
    uint public dailyLimit;
    uint public lastDay;
    uint public spentToday;
    uint public nonce;

    // Transaction ID => Transaction
    mapping (uint => Transaction) public transactions;

    // Transaction ID => Owner => Confirmed
    mapping (uint => mapping (address => bool)) public confirmations;

    // Owners
    mapping (address => bool) public isOwner;
    address[] public owners;


    /** 
     *  Events
     */
    /// @dev Emitted when a confirmation is added by an owner
    /// @param sender The sender of the confirmation
    /// @param transactionId The transaction id of the transaction that was confirmed
    event Confirmation(address indexed sender, uint indexed transactionId);

    /// @dev Emitted when a confirmation is revoked by an owner
    /// @param sender The sender of the revocation
    /// @param transactionId The transaction id of the transaction that was revoked
    event Revocation(address indexed sender, uint indexed transactionId);

    /// @dev Emitted when a transaction is submitted
    /// @param transactionId The transaction id of the transaction that was submitted
    event Submission(uint indexed transactionId);

    /// @dev Emitted when a transaction is executed after being confirmed
    /// @param transactionId The transaction id of the transaction that was executed
    event Execution(uint indexed transactionId);

    /// @dev Emitted when a transaction fails execution
    /// @param transactionId The transaction id of the transaction that failed execution
    event ExecutionFailure(uint indexed transactionId);

    /// @dev Emitted when native tokens are deposited
    /// @param sender The sender of the native tokens
    /// @param value The amount of native tokens that were deposited
    event Deposit(address indexed sender, uint value);

    /// @dev Emitted when an owner is added
    /// @param owner The address of the owner that was added
    event OwnerAddition(address indexed owner);

    /// @dev Emitted when an owner is removed
    /// @param owner The address of the owner that was removed
    event OwnerRemoval(address indexed owner);

    /// @dev Emitted when the required number of confirmations is changed
    /// @param required The new number of required confirmations
    event RequirementChange(uint required);

    /// @dev Emitted when the daily limit is changed
    /// @param dailyLimit The new daily limit
    event DailyLimitChange(uint dailyLimit);


    /**
     * Errors
     */
    /// @dev Raised when a function is called by any address other than the multisig wallet itself
    error OnlyWalletAllowed();

    /// @dev Raised when trying to add an owner that already exists
    /// @param owner The address of the owner that already exists
    error OwnerAlreadyExists(address owner);

    /// @dev Raised when an operation requires an existing owner, but the address isn't an owner
    /// @param owner The address of the owner that doesn't exist
    error OwnerDoesNotExist(address owner);

    /// @dev Raised when owner count or required confirmations are not set correctly
    /// @param ownerCount The amount of owners
    error RequirementInvalid(uint ownerCount, uint required);

    /// @dev Raised when referencing a transaction that doesn't exist
    /// @param transactionId The transaction ID that doesn't exist
    error TransactionDoesNotExist(uint transactionId);

    /// @dev Raised when a transaction has already been confirmed by an owner
    /// @param transactionId The transaction ID that has already been confirmed
    /// @param owner The owner that has already confirmed the transaction
    error TransactionAlreadyConfirmed(uint transactionId, address owner);

    /// @dev Raised when an owner tries to confirm a transaction that they haven't confirmed yet
    /// @param transactionId The transaction ID that hasn't been confirmed yet
    /// @param owner The owner that hasn't confirmed the transaction yet
    error TransactionNotYetConfirmed(uint transactionId, address owner);

    /// @dev Raised when trying to execute a transaction that has already been executed
    /// @param transactionId The transaction ID that has already been executed
    error TransactionAlreadyExecuted(uint transactionId);


    /**
     * Modifiers
     */
    /// @dev Ensures the function is only called by the multisig wallet itself
    modifier onlyWallet() 
    {
        if (msg.sender != address(this)) 
        {
            revert OnlyWalletAllowed();
        }
        _;
    }


    /// @dev Ensures the specified address is not the multisig wallet itself
    /// @param account The address to validate
    modifier notWallet(address account) 
    {
        if (account == address(this)) 
        {
            revert ArgumentInvalid();
        }
        _;
    }


    /// @dev Ensures the specified address is not already an owner
    /// @param owner The address to validate
    modifier ownerDoesNotExist(address owner) 
    {
        if (isOwner[owner]) 
        {
            revert OwnerAlreadyExists(owner);
        }
        _;
    }


    /// @dev Ensures the specified address is an existing owner
    /// @param owner The address to validate
    modifier ownerExists(address owner) 
    {
        if (!isOwner[owner]) 
        {
            revert OwnerDoesNotExist(owner);
        }
        _;
    }


    /// @dev Ensures the transaction ID references an existing transaction
    /// @param transactionId The transaction ID to validate
    modifier transactionExists(uint transactionId) 
    {
        if (transactions[transactionId].destination == address(0)) 
        {
            revert TransactionDoesNotExist(transactionId);
        }
        _;
    }


    /// @dev Ensures the transaction has been confirmed by the specified owner
    /// @param transactionId The transaction ID to validate
    /// @param owner The owner to validate
    modifier transactionConfirmed(uint transactionId, address owner) 
    {
        if (!confirmations[transactionId][owner]) 
        {
            revert TransactionNotYetConfirmed(transactionId, owner);
        }
        _;
    }


    /// @dev Ensures the transaction has not been confirmed by the specified owner
    /// @param transactionId The transaction ID to validate
    /// @param owner The owner to validate
    modifier transactionNotConfirmed(uint transactionId, address owner) 
    {
        if (confirmations[transactionId][owner]) 
        {
            revert TransactionAlreadyConfirmed(transactionId, owner);
        }
        _;
    }


    /// @dev Ensures the specified transaction hasn't been executed yet
    /// @param transactionId The transaction ID to validate
    modifier transactionNotExecuted(uint transactionId) 
    {
        if (transactions[transactionId].executed) 
        {
            revert TransactionAlreadyExecuted(transactionId);
        }
        _;
    }


    /// @dev Ensures the provided address is non-zero
    /// @param account The address to validate
    modifier notNull(address account) 
    {
        if (account == address(0)) 
        {
            revert ArgumentZeroAddress(account);
        }
        _;
    }


    /// @dev Validates the requirements for owner count and confirmations needed
    /// @param ownerCount The amount of owners
    /// @param _required The amount of confirmations needed
    modifier validRequirement(uint ownerCount, uint _required) 
    {
        if (ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0) 
        {
            revert RequirementInvalid(ownerCount, _required);
        }
        _;
    }


    /*
     * Public functions
     */
    /// @dev Contract initializer sets initial owners and required number of confirmations
    /// @param _EIP712Name The name of the contract
    /// @param _EIP712Version The version of the contract
    /// @param _owners List of initial owners
    /// @param _required Number of required confirmations
    /// @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis
    function __Multisig_init(
        string memory _EIP712Name, 
        string memory _EIP712Version, 
        address[] memory _owners, 
        uint _required, 
        uint _dailyLimit) 
        internal onlyInitializing
    {   
        __EIP712_init(_EIP712Name, _EIP712Version);
        __Multisig_init_unchained(_owners, _required, _dailyLimit);
    }


    /// @dev Contract initializer sets initial owners and required number of confirmations
    /// @param _owners List of initial owners
    /// @param _required Number of required confirmations
    /// @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis
    function __Multisig_init_unchained(
        address[] memory _owners, 
        uint _required, 
        uint _dailyLimit) 
        internal onlyInitializing
    {   
        for (uint i = 0; i < _owners.length; i++) 
        {
            if (isOwner[_owners[i]] || _owners[i] == address(0)) 
            {
                revert ArgumentInvalid();
            }

            isOwner[_owners[i]] = true;
        }

        owners = _owners;
        required = _required;
        dailyLimit = _dailyLimit;
    }


    /// @dev Fallback function allows to deposit ether
    receive() external payable
    {
        if (msg.value > 0)
        {
            emit Deposit(msg.sender, msg.value);
        }
    }


    /// @dev Fallback function allows to deposit ether
    fallback() external payable
    {
        if (msg.value > 0)
        {
            emit Deposit(msg.sender, msg.value);
        }
    }


    /// @dev Allows to add a new owner. Transaction has to be sent by wallet
    /// @param owner Address of new owner
    function addOwner(address owner)
        public virtual  
        onlyWallet
        notNull(owner)
        notWallet(owner)
        ownerDoesNotExist(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);

        emit OwnerAddition(owner);
    }


    /// @dev Allows to remove an owner. Transaction has to be sent by wallet
    /// @param owner Address of owner
    function removeOwner(address owner)
        public virtual 
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i = 0; i < owners.length - 1; i++)
        {
            if (owners[i] == owner) 
            {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
            
        owners.pop();

        if (required > owners.length)
        {
            changeRequirement(owners.length);
        }
            
        emit OwnerRemoval(owner);
    }


    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet
    /// @param owner Address of owner to be replaced
    /// @param newOwner Address of new owner
    function replaceOwner(address owner, address newOwner)
        public virtual 
        onlyWallet
        notNull(newOwner)
        notWallet(newOwner)
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i = 0; i < owners.length; i++) 
        {
            if (owners[i] == owner) 
            {
                owners[i] = newOwner;
                break;
            }
        }

        isOwner[owner] = false;
        isOwner[newOwner] = true;

        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }


    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet
    /// @param _required Number of required confirmations
    function changeRequirement(uint _required)
        public virtual 
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }


    /// @dev Allows to change the daily limit. Transaction has to be sent by wallet
    /// @param _dailyLimit Amount in wei
    function changeDailyLimit(uint _dailyLimit)
        public virtual 
        onlyWallet
    {
        dailyLimit = _dailyLimit;
        emit DailyLimitChange(_dailyLimit);
    }


    /// @dev Creates a new transaction to call the `destination` address with `value` wei and `data` payload
    ///      The transaction is executed if the required amount of confirmations has been reached
    /// @param destination Transaction target address
    /// @param value Transaction value in wei
    /// @param data Transaction data payload
    /// @return transactionId Returns transaction ID
    function submitTransaction(address destination, uint value, bytes memory data)
        public virtual 
        ownerExists(msg.sender)
        returns (uint transactionId)
    {
        // Create transaction
        transactionId = _addTransaction(destination, value, data);

        // Confirm transaction
        _confirmTransaction(transactionId, msg.sender);

        // Execute if confirmed transaction
        if (isConfirmed(transactionId)) 
        {
            _executeConfirmedTransaction(transactionId);
        }

        // Execute transaction that doesn't require confirmation
        else if (data.length == 0 && _isUnderLimit(value)) 
        {
            _executeUnonfirmedTransaction(transactionId);
        }   
    }


    /// @dev Allows an owner to confirm a transaction and execute it if the required number 
    ///      of confirmations has been reached
    /// @param transactionId Transaction ID
    function confirmTransaction(uint transactionId)
        public virtual
        ownerExists(msg.sender)
        transactionExists(transactionId)
        transactionNotExecuted(transactionId)
        transactionNotConfirmed(transactionId, msg.sender)
    {
        // Confirm transaction
        _confirmTransaction(transactionId, msg.sender);

        // Execute if confirmed
        if (isConfirmed(transactionId)) 
        {
            _executeConfirmedTransaction(transactionId);
        }
    }


    /// @dev Allows an owner to revoke a confirmation for a transaction
    /// @param transactionId Transaction ID
    function revokeConfirmation(uint transactionId)
        public virtual
        ownerExists(msg.sender)
        transactionNotExecuted(transactionId)
        transactionConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }


    /// @dev Reverted when trying to execute a transaction without sufficient signatures
    /// @param count Amount of signatures provided
    /// @param required Amount of signatures required
    error SignatureCountInvalid(uint count, uint required);

    /// @dev Reverted when trying to execute a transaction with a signature that has been expired
    /// @param timestamp Current timestamp
    /// @param deadline Deadline in unix timestamp
    error SignatureExpired(uint timestamp, uint deadline);


    
    /// @dev Allows anyone to execute a transaction with off-chain signatures
    /// @param signatures Array of signatures
    /// @param deadline Deadline in unix timestamp
    /// @param destination Transaction target address
    /// @param value Transaction value in wei
    /// @param data Transaction data payload
    /// @return transactionId Returns transaction ID
    /// @return success Returns if the transaction was executed
    function executeTransaction(
        bytes[] memory signatures, 
        uint deadline, 
        address destination, 
        uint value, 
        bytes memory data)
        public virtual override 
        nonReentrant
        returns (uint transactionId, bool success)
    {
        // Ensure the required amount of signatures
        if (signatures.length != required)
        {
            revert SignatureCountInvalid(signatures.length, required);
        }

        // Create digest
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            EIP712_TRANSACTION_SCHEMA_HASH,
            address(this),
            destination,
            value,
            keccak256(data),
            nonce++,
            deadline
        )));

        // Validate signatures
        for (uint i = 0; i < signatures.length; i++)
        {
            // Ensure signature is valid
            address signer = ECDSA.recover(digest, signatures[i]);
            if (!isOwner[signer])
            {
                revert OwnerDoesNotExist(signer);
            }

            // Ensure deadline has not passed
            if (block.timestamp > deadline)
            {
                revert SignatureExpired(block.timestamp, deadline);
            }

            if (0 == i)
            {
                // Create transaction
                transactionId = _addTransaction(destination, value, data);
            }
            else 
            {
                // Ensure that the transaction is not already confirmed by this owner (duplicate ownership check)
                if (confirmations[transactionId][signer])
                {
                    revert TransactionAlreadyConfirmed(transactionId, signer);
                }
            }

            // Confirm transaction
            _confirmTransaction(transactionId, signer);
        }

        // Execute transaction
        _executeConfirmedTransaction(transactionId);

        // Return success
        success = transactions[transactionId].executed;
    }


    /// @dev Verifies that the signer is an owner of the signing contract
    /// @param _hash Hash of the data to be signed
    /// @param _signature Signature byte array associated with _hash
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        public virtual override view 
        returns (bytes4 magicValue)
    {
        if (isOwner[ECDSA.recover(_hash, _signature)])
        {
            magicValue = ERC1271_MAGICVALUE;
        }
    }


    /// @dev Returns true if the signatures are valid and satisfy the requirements of the multisig wallet
    /// @param _hash Hash of the signed data
    /// @param signatures Array of signatures
    /// @return Returns true if enough valid signatures are provided
    function isValidSignatureSet(bytes32 _hash, bytes[] memory signatures)
        public virtual override view 
        returns (bool)
    {
        uint count = 0;
        address[] memory seen = new address[](signatures.length);

        for (uint i = 0; i < signatures.length; i++) 
        {
            address signer = ECDSA.recover(_hash, signatures[i]);
            if (isOwner[signer] && !_isSeen(signer, seen)) 
            {
                count += 1;
                seen[i] = signer;
            }

            if (count == required) 
            {
                return true;
            }
        }

        return false;
    }


    /**
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction
    /// @param transactionId Transaction ID
    /// @return count Number of confirmations
    function getConfirmationCount(uint transactionId)
        public virtual view
        returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++) 
        {
            if (confirmations[transactionId][owners[i]])
            {
                count += 1;
            }
        }
    }


    /// @dev Returns total number of transactions after filers are applied
    /// @param pending Include pending transactions
    /// @param executed Include executed transactions
    /// @return count Total number of transactions after filters are applied
    function getTransactionCount(bool pending, bool executed)
        public virtual view
        returns (uint count)
    {
        for (uint i = 0; i < transactionCount; i++)
        {
            if (pending && !transactions[i].executed || executed && transactions[i].executed)
            {
                count++;
            }
        }
    }


    /// @dev Returns list of transaction IDs in defined range
    /// @param from Index start position of transaction array
    /// @param to Index end position of transaction array
    /// @param pending Include pending transactions
    /// @param executed Include executed transactions
    /// @return transactionIds Returns array of transaction IDs
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public virtual view
        returns (uint[] memory transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);

        uint i;
        uint count;
        for (i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || 
                executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }

        transactionIds = new uint[](to - from);
        for (i = from; i < to; i++)
        {
            transactionIds[i - from] = transactionIdsTemp[i];
        }
    }


    /// @dev Returns list of owners
    /// @return List of owner addresses
    function getOwners()
        public virtual view
        returns (address[] memory)
    {
        return owners;
    }


    /// @dev Returns array with owner addresses, which confirmed transaction
    /// @param transactionId Transaction ID
    /// @return _confirmations Returns array of owner addresses
    function getConfirmations(uint transactionId)
        public virtual view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);

        uint i;
        uint count = 0;
        for (i = 0; i < owners.length; i++)
        {
            if (confirmations[transactionId][owners[i]]) 
            {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }

        _confirmations = new address[](count);
        for (i = 0; i < count; i++)
        {
            _confirmations[i] = confirmationsTemp[i];
        }
    }


    /// @dev Returns maximum withdraw amount
    /// @return Returns amount
    function getMaxWithdraw()
        public virtual view
        returns (uint)
    {
        if (block.timestamp > lastDay + 24 hours)
        {
            return dailyLimit;
        }
            
        if (dailyLimit < spentToday)
        {
            return 0;
        }
            
        return dailyLimit - spentToday;
    }


    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return confirmed Confirmation status.
    function isConfirmed(uint transactionId)
        public virtual view
        returns (bool confirmed)
    {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) 
        {
            if (confirmations[transactionId][owners[i]])
            {
                count++;
            }

            if (count == required)
            {
                confirmed = true;
                break;
            }  
        }
    }


    /*
     * Internal functions
     */
    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function _external_call(address destination, uint value, uint dataLength, bytes memory data) 
        internal 
        returns (bool result) 
    {
        assembly {
            let output := mload(0x40)
            result := call(
                sub(gas(), 34710),  // 34710 is the value that solidity is currently emitting
                                    // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                    // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                add(data, 32),      // First 32 bytes are the padded length of data, so exclude that
                dataLength,         // Size of the input (in bytes) - this is what fixes the padding problem
                output,
                0                   // Output is ignored, therefore the output size is zero
            )

            // Only for debug
             switch result
                case 0 {
                    let size := returndatasize()
                    returndatacopy(output, 0, size)
                    revert(output, size)
                } 
        }
    }


    /// @dev Returns if amount is within daily limit and resets spentToday after one day.
    /// @param amount Amount to withdraw.
    /// @return Returns if amount is under daily limit.
    function _isUnderLimit(uint amount)
        internal
        returns (bool)
    {
        if (block.timestamp > lastDay + 24 hours) 
        {
            lastDay = block.timestamp;
            spentToday = 0;
        }

        if (spentToday + amount > dailyLimit)
        {
            return false;
        }

        return true;
    }


    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function _addTransaction(address destination, uint value, bytes memory data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = ++transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });

        emit Submission(transactionId);
    }

    /// @dev Add a confirmation for `transactionId` from `owner`
    /// @param transactionId Transaction ID to add confirmation for
    /// @param owner The address that confirms the transaction
    function _confirmTransaction(uint transactionId, address owner)
        internal 
    {
        confirmations[transactionId][owner] = true;
        emit Confirmation(owner, transactionId);
    }


    /// @dev Execute transaction that has been confirmed
    /// @param transactionId Transaction ID of the transaction to execute
    function _executeConfirmedTransaction(uint transactionId)
        internal 
    {
        Transaction storage transaction = transactions[transactionId];

        // Mark as executed 
        transaction.executed = true;

        if (_external_call(
            transaction.destination, 
            transaction.value, 
            transaction.data.length, 
            transaction.data)) 
        {
            // Emit success event
            emit Execution(transactionId);
        }
        else 
        {
            // Revert state
            transaction.executed = false;

            // Emit failure event
            emit ExecutionFailure(transactionId);
        }
    }


    /// @dev Execute transaction that doesn't require confirmation
    /// @param transactionId Transaction ID of the transaction to execute
    function _executeUnonfirmedTransaction(uint transactionId)
        internal 
    {
        Transaction storage transaction = transactions[transactionId];

        // Mark as executed 
        transaction.executed = true;

        // Increase spent today
        spentToday += transaction.value;

        if (_external_call(
                transaction.destination, 
                transaction.value, 
                transaction.data.length, 
                transaction.data)) 
        {
            // Emit success event
            emit Execution(transactionId);
        }
        else 
        {
            // Revert state
            transaction.executed = false;
            spentToday -= transaction.value;

            // Emit failure event
            emit ExecutionFailure(transactionId);
        }
    }


    /// @dev Helper function to check if an address has been seen
    /// @param signer Address to check
    /// @param seen Array of seen addresses
    /// @return Returns true if the address has been seen
    function _isSeen(address signer, address[] memory seen) 
        internal pure 
        returns (bool) 
    {
        for (uint i = 0; i < seen.length; i++) 
        {
            if (seen[i] == signer) 
            {
                return true;
            }
        }

        return false;
    }
}
