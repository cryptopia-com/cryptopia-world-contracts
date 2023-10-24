// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../../errors/ArgumentErrors.sol";
import "../../multisig/IMultiSigWallet.sol";

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <stefan.george@consensys.net> (modified by Frank Bonnet <frankbonnet@outlook.com>)
contract MultiSigWallet is IMultiSigWallet, Initializable {

    struct Transaction 
    {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    /** 
     * Storage
     */
    uint constant private MAX_OWNER_COUNT = 5;

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;
    uint public dailyLimit;
    uint public lastDay;
    uint public spentToday;


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
    error OwnerAlreadyExists(address owner);

    /// @dev Raised when an operation requires an existing owner, but the address isn't an owner
    error OwnerDoesNotExist(address owner);

    /// @dev Raised when referencing a transaction that doesn't exist
    error TransactionDoesNotExist(uint transactionId);

    /// @dev Raised when a transaction has already been confirmed by an owner
    error TransactionAlreadyConfirmed(uint transactionId, address owner);

    /// @dev Raised when an owner tries to confirm a transaction that they haven't confirmed yet
    error TransactionNotYetConfirmed(uint transactionId, address owner);

    /// @dev Raised when trying to execute a transaction that has already been executed
    error TransactionAlreadyExecuted(uint transactionId);

    /// @dev Raised when an owner is invalid (either a duplicate or zero address)
    error InvalidOwner(address account); 

    /// @dev Raised when owner count or required confirmations are not set correctly
    error InvalidOwnerCountOrRequirement(uint ownerCount, uint required);


    /**
     * Modifiers
     */
    /// @dev Ensures the function is only called by the multisig wallet itself.
    modifier onlyWallet() 
    {
        if (msg.sender != address(this)) 
        {
            revert OnlyWalletAllowed();
        }
        _;
    }

    /// @dev Ensures the specified address is not already an owner.
    modifier ownerDoesNotExist(address owner) 
    {
        if (isOwner[owner]) 
        {
            revert OwnerAlreadyExists(owner);
        }
        _;
    }

    /// @dev Ensures the specified address is an existing owner.
    modifier ownerExists(address owner) 
    {
        if (!isOwner[owner]) 
        {
            revert OwnerDoesNotExist(owner);
        }
        _;
    }

    /// @dev Ensures the transaction ID references an existing transaction.
    modifier transactionExists(uint transactionId) 
    {
        if (transactions[transactionId].destination == address(0)) 
        {
            revert TransactionDoesNotExist(transactionId);
        }
        _;
    }

    /// @dev Ensures the transaction has been confirmed by the specified owner.
    modifier transactionConfirmed(uint transactionId, address owner) 
    {
        if (!confirmations[transactionId][owner]) 
        {
            revert TransactionNotYetConfirmed(transactionId, owner);
        }
        _;
    }

    /// @dev Ensures the transaction has not been confirmed by the specified owner.
    modifier transactionNotConfirmed(uint transactionId, address owner) 
    {
        if (confirmations[transactionId][owner]) 
        {
            revert TransactionAlreadyConfirmed(transactionId, owner);
        }
        _;
    }

    /// @dev Ensures the specified transaction hasn't been executed yet.
    modifier notExecuted(uint transactionId) 
    {
        if (transactions[transactionId].executed) 
        {
            revert TransactionAlreadyExecuted(transactionId);
        }
        _;
    }

    /// @dev Ensures the provided address is non-zero.
    modifier notNull(address account) 
    {
        if (account == address(0)) 
        {
            revert ArgumentZeroAddress(account);
        }
        _;
    }

    /// @dev Validates the requirements for owner count and confirmations needed.
    modifier validRequirement(uint ownerCount, uint _required) 
    {
        if (ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0) 
        {
            revert InvalidOwnerCountOrRequirement(ownerCount, _required);
        }
        _;
    }


    /// @dev Fallback function allows to deposit ether.
    receive() external payable
    {
        if (msg.value > 0)
        {
            emit Deposit(msg.sender, msg.value);
        }
    }


    /// @dev Fallback function allows to deposit ether.
    fallback() external payable
    {
        if (msg.value > 0)
        {
            emit Deposit(msg.sender, msg.value);
        }
    }


    /*
     * Public functions
     */
    /// @dev Contract initializer sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis.
    function __Multisig_init(address[] memory _owners, uint _required, uint _dailyLimit) 
        internal onlyInitializing
    {
        for (uint i = 0; i < _owners.length; i++) 
        {
            if (isOwner[_owners[i]] || _owners[i] == address(0)) 
            {
                revert InvalidOwner(_owners[i]);
            }

            isOwner[_owners[i]] = true;
        }

        owners = _owners;
        required = _required;
        dailyLimit = _dailyLimit;
    }


    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public virtual override 
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);

        emit OwnerAddition(owner);
    }


    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public virtual override
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


    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public virtual override
        onlyWallet
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


    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public virtual override
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }


    /// @dev Allows to change the daily limit. Transaction has to be sent by wallet.
    /// @param _dailyLimit Amount in wei.
    function changeDailyLimit(uint _dailyLimit)
        public virtual override
        onlyWallet
    {
        dailyLimit = _dailyLimit;
        emit DailyLimitChange(_dailyLimit);
    }


    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return transactionId Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes memory data)
        public virtual override
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }


    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public virtual override
        ownerExists(msg.sender)
        transactionExists(transactionId)
        transactionNotConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }


    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public virtual override
        ownerExists(msg.sender)
        transactionConfirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }


    /// @dev Allows anyone to execute a confirmed transaction or ether withdraws until daily limit is reached.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public virtual override
        ownerExists(msg.sender)
        transactionConfirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        bool _confirmed = isConfirmed(transactionId);
        if (_confirmed || txn.data.length == 0 && isUnderLimit(txn.value)) 
        {
            txn.executed = true;
            if (!_confirmed)
            {
                spentToday += txn.value;
            }

            if (external_call(txn.destination, txn.value, txn.data.length, txn.data)) 
            {
                emit Execution(transactionId);
            }
            else 
            {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
                if (!_confirmed)
                {
                    spentToday -= txn.value;
                }
            }
        }
    }


    /**
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return count Number of confirmations.
    function getConfirmationCount(uint transactionId)
       public virtual override view
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


    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
       public virtual override view
        returns (uint count)
    {
        for (uint i = 0; i < transactionCount; i++)
        {
            if (pending && !transactions[i].executed || executed && transactions[i].executed)
            {
                count += 1;
            }
        }
    }


    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public virtual override view
        returns (address[] memory)
    {
        return owners;
    }


    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return _confirmations Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public virtual override view
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


    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return _transactionIds Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public virtual override view
        returns (uint[] memory _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }


    /// @dev Returns maximum withdraw amount.
    /// @return Returns amount.
    function calcMaxWithdraw()
        public 
        virtual 
        override 
        view
        returns (uint)
    {
        if (block.timestamp > lastDay + 24 hours)
            return dailyLimit;
        if (dailyLimit < spentToday)
            return 0;
        return dailyLimit - spentToday;
    }


    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return confirmed Confirmation status.
    function isConfirmed(uint transactionId)
        public 
        virtual 
        override 
        view
        returns (bool confirmed)
    {
        confirmed = false;
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                confirmed = true;
        }
    }


    /*
     * Internal functions
     */
    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, uint dataLength, bytes memory data) 
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
    function isUnderLimit(uint amount)
        internal
        returns (bool)
    {
        if (block.timestamp > lastDay + 24 hours) 
        {
            lastDay = block.timestamp;
            spentToday = 0;
        }

        if (spentToday + amount > dailyLimit || spentToday + amount < spentToday)
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
    function addTransaction(address destination, uint value, bytes memory data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });

        transactionCount += 1;
        emit Submission(transactionId);
    }
}
