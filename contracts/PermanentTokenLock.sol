// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



contract permanentTokenLock {

    // metadata
    string public version = "1.0";

   
    event Lock(address indexed _wallet, uint256 _value);

	
    // constructor
    constructor()  { }
    
	
	function permanentTokenLock(address _tokenId, uint256 _amount) public {	 
	
        IERC20 anyTokenContract = IERC20(_tokenId); 
                
        anyTokenContract.transferFrom(msg.sender, address(this), _amount);  
		
		emit Lock(msg.sender, _amount);
    }    
	

}

