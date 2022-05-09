// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

contract Escrow {
    
    address public depositor;
    address payable public beneficiary;
    address public arbiter;

    constructor(address _arbiter, address payable _beneficiary) payable public {
        depositor = msg.sender;
        arbiter = _arbiter;
        beneficiary = _beneficiary;
    }

    function approve() external {
        require(msg.sender == arbiter, "You are not the arbiter.");
        beneficiary.transfer(address(this).balance);
    }
}
