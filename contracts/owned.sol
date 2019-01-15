pragma solidity ^0.5.0;

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