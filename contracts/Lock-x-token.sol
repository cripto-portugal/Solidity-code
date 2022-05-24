// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



contract xTokenlock {

    // metadata
    string public version = "1.0";
    
		
	uint256 public totalLockedTokens;	// so por curiosidade
	uint256 public totalBalance;	// so por curiosidade
	
	uint256 private startTimestamp;
	uint256 private firstReleaseTimestamp;
	uint256 private releaseInterval;

    address private xTokenId;
    IERC20 private xTokenContract;
	
		
	struct TokenLockInfo {
        address tokenId;
		uint256 totalLockedAmount;
        uint256 balance;
		uint256 withdrawn;
        uint256 lockTimestamp;	// initialLock	
		uint256 withdrawPerPeriod;
		string comment;
    }

    // map wallet address to tokenLock details
    mapping(address => TokenLockInfo) public tokenLock;
	
	
  
	address public owner;
	
   
    // events
	event ERC20Received(address from, uint256 amount, address contractAddress);
	
    event LockXtoken(address indexed _wallet, uint256 _value);
    event UnLockXtoken(address indexed _wallet, uint256 _value);
	
    // constructor
    constructor()
    {
		owner = msg.sender;	
		
        xTokenId = 0x999999999999999999999999999999999; // replace by your token address
		xTokenContract = IERC20(xTokenId); 
	
	
		startTimestamp = block.timestamp; // now

		// vesting setup
        releaseInterval = 30 * (24 * 60 * 60); // 30 days
		firstReleaseTimestamp = startTimestamp + (6 * releaseInterval); // 6 months		
		
	
		totalLockedTokens = 0;	
		totalBalance = 0;		
	  	
    }  
	
	function lock(address _tokenId, uint256 _amount, string calldata _comment ) public {
	 
		if (tokenLock[msg.sender].totalLockedAmount == 0) {
			
			uint256 withdrawPerPeriod = _amount/20; // for 5% release 
			
			require (xTokenId == _tokenId, "not valid token");
			tokenLock[msg.sender] = TokenLockInfo(_tokenId, _amount, _amount, 0, block.timestamp, withdrawPerPeriod, _comment); 			
		}
		else
		{
			// add lock tokens for the same wallet
			
			require (tokenLock[msg.sender].tokenId == _tokenId, "not valid token");
			tokenLock[msg.sender].totalLockedAmount += _amount;
			tokenLock[msg.sender].balance += _amount;		
			
		}
			
		totalLockedTokens += _amount;
		totalBalance += _amount;
		
		// approve needed
		// check for approved balance ??? // later
        
        xTokenContract.transferFrom(msg.sender, address(this), _amount);  		
		
		emit LockXtoken(msg.sender, _amount);
    } 
    	

		
	function unLock(address _tokenId) public
	{		
	
		require (tokenLock[msg.sender].tokenId == _tokenId, "not valid token");		
		require (tokenLock[msg.sender].totalLockedAmount > 0, "never locked");		
		require (tokenLock[msg.sender].balance > 0, "no locked balance");	
		
		require (block.timestamp > firstReleaseTimestamp, "can not unlock yet");	
		
		uint256 delta =  block.timestamp - firstReleaseTimestamp;
		
		uint256 allowIndex = (delta / releaseInterval) + 1;
						
			
		if (allowIndex >= 20) {
			// can Withdraw all
             xTokenContract.approve(address(this), tokenLock[msg.sender].balance);

			 xTokenContract.transferFrom(address(this), msg.sender, tokenLock[msg.sender].balance);  
			 
			 tokenLock[msg.sender].withdrawn += tokenLock[msg.sender].balance;			 
			 tokenLock[msg.sender].balance = 0;
			 
			 totalBalance -= tokenLock[msg.sender].balance;
			 emit UnLockXtoken(msg.sender, tokenLock[msg.sender].balance);
		}
		else
		{
			uint256 canWithdraw = allowIndex * tokenLock[msg.sender].withdrawPerPeriod;
			canWithdraw -= tokenLock[msg.sender].withdrawn;
			
            xTokenContract.approve(address(this), canWithdraw);

			xTokenContract.transferFrom(address(this), msg.sender, canWithdraw);  
			
			tokenLock[msg.sender].withdrawn += canWithdraw;			 
			tokenLock[msg.sender].balance -= canWithdraw;
			
			totalBalance -= canWithdraw;
			emit UnLockXtoken(msg.sender, canWithdraw);	
		}
		
		
	}   
	
	modifier onlyOwner() {
		require (msg.sender == owner, "not allowed");
		_;
	}
	
	
	// failsafe functions here
	
	function releaseFunds(address _tokenId) public onlyOwner
	{
		// avoid stuck tokens in the contract

        if (block.timestamp - firstReleaseTimestamp - (releaseInterval * 20) > 0) {
            // to avoid stuck x Tokens sended by mistake

            IERC20 anyTokenContract = IERC20(_tokenId); 			
            uint256 balance = anyTokenContract.balanceOf(address(this)); 
            
            require (balance > 0, "balance is zero");
                
            anyTokenContract.transfer(msg.sender, balance);

        }
        else {
            
            require (xTokenId != _tokenId, "only other Tokens!");	
            
            IERC20 anyTokenContract = IERC20(_tokenId); 			
            uint256 balance = anyTokenContract.balanceOf(address(this)); 
            
            require (balance > 0, "balance is zero");
                
            anyTokenContract.transfer(msg.sender, balance);
        }
	}
	
	function releaseNativeToken() public onlyOwner
	{
		// avoid stuck ETH/BNB/etc in the contract
							
		uint256 balance = address(this).balance;		
		require (balance > 0, "balance is zero");		
		payable(msg.sender).transfer(address(this).balance);		
	}
	

	
	// get info about Lock befere UnLock 
	// can be inproved
	
    function getLockInfo(address account) public view returns (uint256 lockedBalance, uint256 lockedTime)
	{		
	    if (tokenLock[account].totalLockedAmount == 0) return (0, 0); // more informative 
	
		lockedTime = block.timestamp - tokenLock[account].lockTimestamp;		
		lockedBalance = tokenLock[account].balance;
		
				
		return (lockedBalance, lockedTime);
	}

}

