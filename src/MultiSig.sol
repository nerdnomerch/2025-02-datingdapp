// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSigWallet {
    error NotAnOwner();
    error AlreadyApproved();
    error NotEnoughApprovals();
    error InvalidRecipient();
    error InvalidAmount();

    address public owner1;
    address public owner2;

    struct Transaction {
        address to;
        uint256 value;
        bool approvedByOwner1;
        bool approvedByOwner2;
        bool executed;
    }

    Transaction[] public transactions;

    event TransactionCreated(uint256 indexed txId, address indexed to, uint256 value);
    event TransactionApproved(uint256 indexed txId, address indexed owner);
    event TransactionExecuted(uint256 indexed txId, address indexed to, uint256 value);

    modifier onlyOwners() {
        if (msg.sender != owner1 && msg.sender != owner2) revert NotAnOwner();
        _;
    }

    constructor(address _owner1, address _owner2) {
        require(_owner1 != address(0) && _owner2 != address(0), "Invalid owner address");
        require(_owner1 != _owner2, "Owners must be different");
        owner1 = _owner1;
        owner2 = _owner2;
    }

    /// @notice Submit a transaction for approval
    function submitTransaction(address _to, uint256 _value) external onlyOwners {
        if (_to == address(0)) revert InvalidRecipient();
        if (_value == 0) revert InvalidAmount();

        transactions.push(Transaction(_to, _value, false, false, false));
        uint256 txId = transactions.length - 1;
        emit TransactionCreated(txId, _to, _value);
    }

    /// @notice Approve a pending transaction
    function approveTransaction(uint256 _txId) external onlyOwners {
        require(_txId < transactions.length, "Invalid transaction ID");
        Transaction storage txn = transactions[_txId];
        require(!txn.executed, "Transaction already executed");

        if (msg.sender == owner1) {
            if (txn.approvedByOwner1) revert AlreadyApproved();
            txn.approvedByOwner1 = true;
        } else {
            if (txn.approvedByOwner2) revert AlreadyApproved();
            txn.approvedByOwner2 = true;
        }

        emit TransactionApproved(_txId, msg.sender);
    }

    /// @notice Execute a fully-approved transaction
    function executeTransaction(uint256 _txId) external onlyOwners {
        require(_txId < transactions.length, "Invalid transaction ID");
        Transaction storage txn = transactions[_txId];
        require(!txn.executed, "Transaction already executed");
        require(txn.approvedByOwner1 && txn.approvedByOwner2, "Not enough approvals");

        txn.executed = true;
        (bool success,) = payable(txn.to).call{value: txn.value}("");
        require(success, "Transaction failed");

        emit TransactionExecuted(_txId, txn.to, txn.value);
    }

    /// @notice Allows the contract to receive ETH
    receive() external payable {}
}
