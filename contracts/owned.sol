pragma solidity >=0.4.21 <0.6.0;


contract owned {
    address owner;
    
    constructor() public {
         owner = msg.sender;
    }
    modifier onlyowner(){
        if(msg.sender == owner)
        {
            _;
        }
    }
}