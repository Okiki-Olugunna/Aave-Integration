//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.5;

import "./IERC20.sol";
import "./IWETHGateway.sol";

contract Escrow {
    address arbiter;
    address depositor;
    address beneficiary;

    uint initialDeposit;
    
    IWETHGateway gateway = IWETHGateway(0xDcD33426BA191383f1c9B431A342498fdac73488);
    IERC20 aWETH = IERC20(0x030bA81f1c18d280636F32af80b9AAd02Cf0854e);

    constructor(address _arbiter, address _beneficiary) payable {
        arbiter = _arbiter;
        beneficiary = _beneficiary;
        depositor = msg.sender;

        initialDeposit = msg.value;

        // Depositing ETH through the WETH gateway
        gateway.depositETH{value: address(this).balance}(address(this), 0);        
    }

    receive () external payable {}

    function approve() external {
        require(msg.sender == arbiter);

        uint balance = aWETH.balanceOf(address(this));
        //approving the gateway to spend the aWETH for ETH when withdrawing later 
        aWETH.approve(address(gateway), balance);

        // withdrawing the interest & ETH to this escrow contract
        gateway.withdrawETH(type(uint256).max, address(this));

        // paying the beneficiary the initial deposit
        payable(beneficiary).transfer(initialDeposit);

        // paying the interest to the depositer 
        payable(depositor).transfer(address(this).balance);
        // other option could be to use selfdestruct(payable(depositer))  
    }
}
