//SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IERC20.sol";
import "./ILendingPool.sol";

contract Lottery {
	// the timestamp of the drawing event
	uint public drawing;
	// the price of the ticket in DAI (100 DAI)
	uint ticketPrice = 100e18;

	//mapping to check if someone has already entered the lottery 
	mapping(address => bool) public hasEntered;
	//array of those who entered
	address[] public tikcetHolders;

	event TicketPurchased(address indexed _purchaser);

	ILendingPool pool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
	IERC20 aDai = IERC20(0x028171bCA77440897B824Ca71D1c56caC55b68A3); 
	IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

	constructor() {
		// setting the drawing event to be 1 week after the contract is deployed 
		drawing = block.timestamp + 1 weeks;
        
	}

	function purchase() external {
		require(!hasEntered[msg.sender], "You have already purchased a ticket.");
		dai.transferFrom(msg.sender, address(this), ticketPrice);
		hasEntered[msg.sender] = true;
		tikcetHolders.push(msg.sender);

		emit TicketPurchased(msg.sender);

		// depositing the user's dai into the aave pool
		dai.approve(address(pool), ticketPrice);
		pool.deposit(address(dai), ticketPrice, address(this), 0);
	}

	event Winner(address);

	function pickWinner() external {
		// ensuring that a winner is only picked a time occuring after the drawing timestamp 
        require(drawing <= block.timestamp, "Must wait for the draw to occur before picking a winner.");

		// picking a random winner - not the most secure, will use Chainlink VRF to improve this later 
		uint randomNumer = block.timestamp % tikcetHolders.length;
		address _winner = tikcetHolders[randomNumer];
		emit Winner(_winner);

		// approving the pool to spend our aDai & convert to dai  
		aDai.approve(address(pool), type(uint256).max);
		// paying out the participants their money 
		for (uint i; i < tikcetHolders.length; i++) {
			pool.withdraw(address(dai), ticketPrice, address(this));
			dai.transfer(tikcetHolders[i], ticketPrice);
		}

		// giving the remaining interest to the winner 
		pool.withdraw(address(dai), type(uint256).max, _winner);
	}
}
