// SPDX-License-Identifier: GPL-3.0
// Lucrar is a project founded by Workolic and his development team 

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract xToken is ERC20 {

    // metadata
    string public version = "3.0";
    
	bool[] public releaseDone;
	
	uint256[] private releasePeriods;
	
	uint256 private intervalBlocksYear;
	uint256 private intervalBlocksQuarter;
	
	
   
    address public xFundDeposit; // deposit address for main wallet        
	address public owner;
	
    uint256 private constant tokenHardCap =  100 * (10**6) * 10**9; 
    
	// events
    event TotalSupplyCreated(address indexed _to, uint256 _value);
	
    // constructor
    constructor() ERC20("Token X", "tXX")
    {
		owner = msg.sender;
		xFundDeposit = address(msg.sender); // can be another wallet
		
		// improve this with timestamp later
		uint256 daysUntilFirstRelease = 58;
		uint256 hoursUntilMidnight = 7;

		uint256 startBlock = block.number + ((daysUntilFirstRelease * 24 + hoursUntilMidnight) * 60 * 60 / 3); // April 1, 2023 aprox.	
		
		intervalBlocksYear = 365 * 24 * 60 * 60 / 3;  // 1 year of blocks (1 each 3 seconds)
		intervalBlocksQuarter = intervalBlocksYear / 4;  // 1 quarter of blocks 

		releasePeriods = new uint256[](81);
		releaseDone = new bool[](80);	
		
		for (uint i= 0; i < 81; i++)
		{
			releasePeriods[i] = startBlock + i * intervalBlocksQuarter;
			if (i < 80) releaseDone[i] = false;
		}
		
		uint256 totalSupply = tokenHardCap;	
		
		uint256 xFundValue = totalSupply / 5;	// 20%
		
		_mint(address(this), totalSupply);
		emit TotalSupplyCreated(address(this), totalSupply);  // logs money creation
		
		
		_approve(address(this), msg.sender, lcrFundValue);  
		transferFrom(address(this), xFundDeposit, xFundValue);  // transfer 20% to Main account
  
	  	
    }  
    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
	
	modifier onlyOwner() {
		require (msg.sender == owner, "not allowed");
		_;
	}
	
	modifier zeroBalanceAndInsufficientBalance(uint256 value) {
	    uint256 balance = balanceOf(address(msg.sender));
	    require (balance > 0, "zero balance");		
		require (balance >= value, "insufficient balance");
		_;
	}
	
	
	function getNativeTokenBalance(address account) public view returns (uint256 balance)
	{	
	    return address(account).balance; // ETH/BNB balance
	}
	
	function getBalance(address account) public view returns (uint256 balance)
	{	
	    return balanceOf(account); // x token balance
	}
	
	function getXFundBalance() public view returns (uint256 balance)
	{		
	    return this.balanceOf(address(this)); 
	}
	
	
	function releaseFunds() public onlyOwner
	{
		require  (releasePeriods[0] <= block.number, "before release period");
		require  (block.number < releasePeriods[80] , "after release period");
		require  (balanceOf(address(msg.sender)) > 0, "fund is empty");
		
							
		uint256 valueToRelease = 1 * (10**6) * 10**decimals(); // 1 M tokens max per Quarter
				
		for (uint i= 0; i < 80; i++)
		{
			if (block.number >= releasePeriods[i] && block.number < releasePeriods[i+1]) 
			{
				require (!releaseDone[i], "release already done this Quarter!");
				releaseDone[i] = true;
				this.transfer(xFundDeposit, valueToRelease);
			}
		}
	}
	
	
}

