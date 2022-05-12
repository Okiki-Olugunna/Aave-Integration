// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IERC20.sol";
import "./ILendingPool.sol";

contract CollateralGroup {
	ILendingPool pool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
	IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
	IERC20 aDai = IERC20(0x028171bCA77440897B824Ca71D1c56caC55b68A3); 

	uint depositAmount = 10000e18;
  uint totalDeposit;

	address[] members;
	mapping(address => bool) isMember;

	modifier onlyMembers(address) {
		require(isMember[msg.sender], "You are not a member!");
		_;
	}

	constructor(address[] memory _members) {
        members = _members;

		// transferring the required deposit for each member of this collateral pool 
		for (uint i; i < members.length; i++) {
			dai.transferFrom(members[i], address(this), depositAmount);
			isMember[members[i]] = true;
		}
		totalDeposit = depositAmount * members.length;

		// approving the pool to spend our dai 
		dai.approve(address(pool), totalDeposit);
		// depositing the dai into aave lending pool 
		pool.deposit(address(dai), totalDeposit, address(this), 0);
	}


	function withdraw() external onlyMembers(msg.sender) {
		// calculating the balance to give out 
		uint totalBalance = aDai.balanceOf(address(this));
		uint distribute = totalBalance / members.length;

    // approving the pool to spend/convert our interest token aDai
		aDai.approve(address(pool), totalBalance);

		// distributing the funds back to the memebers
		for(uint i; i < members.length; i++){
			pool.withdraw(address(dai), distribute, members[i]);
		}
	}


	function borrow(address _asset, uint amount) external onlyMembers(msg.sender) {
		// borrowing the asset at a fixed (1) interest rate 
		pool.borrow(_asset, amount, 1, 0, address(this));
		
		// calculating the health factor of the loan 
		(,,,,,uint healthfactor) = pool.getUserAccountData(address(this));
		// requiring a health factor above 2 for safety measures 
		require(healthfactor > 2e18, "Health factor is too low! We don't want you to get liquidated.");

		// transferring the asset to the caller 
		IERC20(_asset).transfer(msg.sender, amount);
	}

	function repay(address _asset, uint amount) external {
		IERC20 asset = IERC20(_asset);
		
		// approving this collateral pool to spend their asset 
		asset.approve(address(this), amount);
		// transferring the borrowed asset to this contract 
		asset.transferFrom(msg.sender, address(this), amount);

		//approving the aave pool to spend the asset 
		asset.approve(address(pool), amount);

		// repaying the aave pool
		pool.repay(_asset, amount, 1, address(this));
	}
}
