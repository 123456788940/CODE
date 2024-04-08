// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

contract vote {
    address public owner;
    address[] public members;
    mapping(address=>bool) public isPaid;
        mapping(address=>bool) public hasVoted;


    constructor() {
        owner = msg.sender;
    }

    function register(address[] memory _address, uint amount) public payable{
        require(_address.length > 0);
        require(amount>0);
        require(!isPaid[msg.sender]);
        for (uint i = 0; i < _address.length; i++) {
            members.push(_address[i]);

        }
         isPaid[msg.sender] = true;
        payable(msg.sender).transfer(amount);
    }

    function _vote(address _address) public {
         require(_address != address(0));
           require(isPaid[msg.sender]);
            require(!hasVoted[_address]);
            hasVoted[_address] = true;

    }


    function trackVote(address _address) public view returns(bool) {
        return hasVoted[_address];
    }
}
