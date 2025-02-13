pragma solidity >=0.4.22 <0.6.0;

contract VotingSecurity {
  
    bool private locked;
    
    modifier noReentrant() {
        require(!locked, "Reentrant call detected");
        locked = true;
        _;
        locked = false;
    }
    
    
    modifier safeOperations(uint a, uint b) {
        require(a + b >= a, "Overflow detected");
        _;
    }
    

    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }
} 