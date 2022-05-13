// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Govern.sol";
import "./ILendingPool.sol";

contract FlashVoter {
    ILendingPool constant pool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    uint constant borrowAmount = 100000e18; //100k

    Govern public governanceToken;
    uint public proposalId;

    constructor(Govern _governanceToken, uint _proposalId) {
        governanceToken = _governanceToken;
        proposalId = _proposalId;
    }


    function flashVote() external {
        address[] memory assets = new address[](1); // only going to use 1 asset 
        assets[0] = address(DAI);

        uint[] memory amounts = new uint[](1); //only 1 amount for the 1 asset 
        amounts[0] = borrowAmount; // borrowing 100k dai 

        uint[] memory modes = new uint[](1);
        modes[0] = 0; // paying back the flash loan in full

        // calling the flashloan function from the aave lending pool interface 
        pool.flashLoan(address(this), assets, amounts, modes, address(this), "", 0);
    }

    // the pool will call this function when the flash loan is executed 
    function executeOperation(
        address[] calldata,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address, bytes calldata
    ) external returns(bool) {
        // approving the governance contract to spend the dai
        DAI.approve(address(governanceToken), borrowAmount);
        // buying governance tokens 
        governanceToken.buy(borrowAmount);
        // voting with these tokens - used true to say I'm for this proposal 
        governanceToken.vote(proposalId, true);
        // selling the governance tokens after my vote ;)
        governanceToken.sell(borrowAmount);
        
        // calculating the amount owed after the flash loan 
        uint totalOwed = amounts[0] + premiums[0];
        // approving the pool to spend the dai 
        DAI.approve(address(pool), totalOwed);
        return true;
    }
}
