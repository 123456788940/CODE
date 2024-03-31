
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract multisigWallet {
    address[] public owners;
    uint public requiredConfirmations;
    mapping(address=>bool) public isOwner;
    mapping(uint => mapping(address=>bool)) public confirmations;
    uint public transactionCount;

    struct _transaction {
        address payable to;
        uint value;
        bytes data;
        bool isExecuted;
        uint confirmationCount;
    }

       mapping(uint=>_transaction) public transactions;

       modifier onlyOwner() {
        require(isOwner[msg.sender], "only owner can access");
        _;
       }

       constructor(address[] memory _owners, uint _requiredConfirmations) {
        require(_owners.length > 0, "owners required");
        require(_requiredConfirmations>0&&_requiredConfirmations<= _owners.length);
        for(uint i = 0;
            i<_owners.length; 
            i++) {
                address owner = _owners[i];
                require(owner != address(0), "address has to be valid");
                require(!isOwner[owner], "Owner not unique");
                isOwner[owner] = true;
                owners.push(owner);


            }

            requiredConfirmations = _requiredConfirmations;
       }

        event Deposit(address indexed sender, uint value);
       receive() external payable {
          
        emit Deposit(msg.sender, msg.value);
       }


       function submit_transaction(address payable _to, uint _value, bytes memory _data) external onlyOwner {
        uint transactionId = transactionCount++;
    transactions[transactionId] = _transaction({
            to : _to,
            value: _value,
            data: _data,
            isExecuted: false,
            confirmationCount: 0
        });

       
         confirmTransactions(transactionId);



       }


       function confirmTransactions(uint transactionId) public onlyOwner {
        confirmations[transactionId][msg.sender] = true;
        transactions[transactionId].confirmationCount++;
          if (transactions[transactionId].confirmationCount >= requiredConfirmations) {
        executeTransaction(transactionId);
          }
       }

        function executeTransaction(uint transactionId) public onlyOwner {
        require(transactions[transactionId].confirmationCount >= requiredConfirmations, "Not enough confirmations");

        _transaction storage txn = transactions[transactionId];
        txn.isExecuted = true;

        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "Transaction execution failed");

      
    }
}
