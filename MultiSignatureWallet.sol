pragma solidity ^0.5.0;

contract MultiSignatureWallet {

    struct Transaction {
        bool executed;
        address destination;
        uint value;
        bytes data;
    }

    uint public transactionCount;
    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping (address => bool)) public confirmations;

    address[] public owners;
    uint public required;
    mapping (address => bool) public isOwner;

    event Deposit(address indexed sender, uint value);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);


    /// @dev Fallback function allows to deposit ether to the wallet.
    function() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }
    /** Public Functions */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners Initial owners of the wallet.
    /// @param _required Number of confirmations required to execute a transaction.
    

    modifier validRequirement(uint ownerCount, uint required) {
        if (_required > ownerCount || _required == 0 || ownerCount == 0) {
            revert();
            _;
        }
    }
    constructor(address[] memory _owners, uint _required) public validRequirement(_owners.length, _required) {
        for (uint i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns Transaction ID.
    function submitTransaction(address destination, uint value, bytes memory data) public returns (uint TransactionId) {
        require(isOwner[msg.sender]);
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId) public {
        require(isOwner[msg.sender]);
        require(transactions[transactionId].destination) != address(0);
        require(confirmations[transactionId][msg.sender] == false);
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId) public {}

    /// @dev Allows an owner to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public {
        require(transactions[transactionId].executed == false);
        if (isConfirmed(transactionId)) {
            Transaction storage t = transactions[transactionId];
            t.executed = true;
            (bool success, bytes memory returnedData) = t.destination.call.value(t.value)(t.data);
            if (success) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                t.executed = false;
            }
        }
    }

    /** (Possible) Helper Functions */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status of the transaction.
    function isConfirmed(uint transactionId) internal view returns (bool) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            if (count == required) {
                return true;
                }
            }
        }
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns Transaction ID.
    function addTransactions(address destination, uint value, bytes memory data) internal returns (uint TransactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            executed: false,
            destination: destination,
            value: value,
            data: data
        });
        transactionCount += 1;
        emit Submission(transactionId);
        })
    }
}