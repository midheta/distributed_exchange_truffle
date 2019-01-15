pragma solidity ^0.5.0;

import "./owned.sol";
import "./FixedSupplyToken.sol";

contract Exchange is owned{
    ///////////////////////
    // GENERAL STRUCTURE //
    ///////////////////////

    struct Offer {

        uint amount;
        address who;

    }

    struct OrderBook {

        uint higherPrice; // pointing to the higher book entry
        uint lowerPrice; // pointing to the lower book entry

        mapping(uint => Offer) offers;
        // offers are in stack

        uint offers_key;
        uint offers_length;
    }

    struct Token {

        address tokenContract;

        string symbolName;

        mapping(uint => OrderBook) buyBook;

        uint curBuyPrice; // last entry in the buyBook
        uint lowesButPrice;
        uint amountBuyPrices;

        mapping(uint => OrderBook) sellBook;

        uint curSellPrice;
        uint highestSellPrice;
        uint amountSellPrices;
    }

    // We support a max of 255 tokens
    mapping (uint8 => Token) tokens;
    uint8 symbolNameIndex;

    ///////////////
    // BALANCES //
    //////////////

    mapping (address => mapping(uint8 => uint)) tokenBalanceForAddress;

    mapping (address => uint) balanceEthForAddress;

    /////////////
    // EVENTS //
    ////////////

    // EVENTS for Deposit/Witdrawal
    event DepositForTokenReceived(address indexed _from, uint indexed _symbolIndex, uint _amount, uint _timestamp);

    event WithdrawalToken(address indexed _to, uint indexed _symbolIndex, uint _amount, uint _timestamp);

    event DepositForEthReceived(address indexed _from, uint amount, uint _timestamp);

    event WithdrawalEth(address indexed _to, uint _amount, uint _timestamp);

    // Events for ORDERS

    // Events for management
    event TokenAddedToSystem(uint _symbolIndex, string _token, uint _timestamp);

    //////////////////////////////////
    // DEPOSIT AND WITHDRAWAL ETHER //
    //////////////////////////////////
    function depositEther() public payable {
        require(balanceEthForAddress[msg.sender] + msg.value >= balanceEthForAddress[msg.sender]);
        balanceEthForAddress[msg.sender] += msg.value;
        emit DepositForEthReceived(msg.sender, msg.value, now);
    }

    function withdrawEther(uint amountInWei) public {
        require(balanceEthForAddress[msg.sender] - amountInWei >= 0);
        require(balanceEthForAddress[msg.sender] - amountInWei <= balanceEthForAddress[msg.sender]);
        balanceEthForAddress[msg.sender] -= amountInWei;
        msg.sender.transfer(amountInWei);
        emit WithdrawalEth(msg.sender, amountInWei, now);
    }

    function getEthBalanceInWei() public returns (uint) {
        return balanceEthForAddress[msg.sender];
    }

    /////////////////////
    // TOKEN MANAGMENT //
    ////////////////////
    // ********* Only for admin *********
    function addToken(string memory symbolName, address erc20TokenAddress) public onlyowner{
        require(!hasToken(symbolName));
        symbolNameIndex ++;
        tokens[symbolNameIndex].symbolName = symbolName;
        tokens[symbolNameIndex].tokenContract = erc20TokenAddress;
        emit TokenAddedToSystem(symbolNameIndex, symbolName, now);
    }

    function hasToken(string memory symbolName) public returns (bool) {
        uint8 index = getSymbolIndex(symbolName);
        if(index == 0) {
            return false;
        }

        return true;
    }

    function getSymbolIndex(string memory symbolName) internal returns (uint8) {

        for(uint8 i = 1; i <= symbolNameIndex; i++)
        {
            if(stringsEqual(tokens[i].symbolName, symbolName))
            {
                return i;
            }
        }
        return 0;

    }

    function getSymbolIndexOrThrow(string memory symbolName) public returns (uint8) {
        uint8 index = getSymbolIndex(symbolName);
        require(index > 0);
        return index;
    }

    function stringsEqual(string storage _a, string memory _b) internal returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if(a.length != b.length)
            return false;
        for(uint i = 0; i < a.length; i ++)
         if(a[i] != b[i])
            return false;
        return true;
    }
    // **********************************

    ///////////////////////////////////
    // DEPOSIT AND WITHDRAWAL TOKEN //
    //////////////////////////////////
    function depositToken(string memory symbolName, uint amount) public {
        uint8 symbolNameIndex = getSymbolIndex(symbolName);
        require(tokens[symbolNameIndex].tokenContract != address(0));


        ERC20Interface token = ERC20Interface(tokens[symbolNameIndex].tokenContract);
        // Transfer the token from the Token Contract into Exchange contract
        require(token.transferFrom(msg.sender, address(this), amount) == true);
        require(tokenBalanceForAddress[msg.sender][symbolNameIndex] + amount >= tokenBalanceForAddress[msg.sender][symbolNameIndex]);

        tokenBalanceForAddress[msg.sender][symbolNameIndex] += amount;
        emit DepositForTokenReceived(msg.sender, symbolNameIndex, amount, now);
    }

    function withdrawToken(string memory symbolName, uint amount) public {
        uint8 symbolNameIndex = getSymbolIndexOrThrow(symbolName);
        require(tokens[symbolNameIndex].tokenContract != address(0));

         ERC20Interface token = ERC20Interface(tokens[symbolNameIndex].tokenContract);

        // Check if there is enough of the tokens for the address that is calling the contract for the symbol name that ther are trying to withdraw tokens
        require(tokenBalanceForAddress[msg.sender][symbolNameIndex] - amount >= 0);
        require(tokenBalanceForAddress[msg.sender][symbolNameIndex] - amount <= tokenBalanceForAddress[msg.sender][symbolNameIndex]);
        // Transfer with the transfer function form the FixedSuuplyToken the tokens fromt he exchange addres to the address who is calling the exchange

        tokenBalanceForAddress[msg.sender][symbolNameIndex] -= amount;
        require(token.transfer(msg.sender, amount) == true);
        emit WithdrawalToken(msg.sender, symbolNameIndex,amount, now);
    }

    function getBalance(string memory symbolName) payable public returns (uint) {
        uint8 index = getSymbolIndexOrThrow(symbolName);
        return tokenBalanceForAddress[msg.sender][index];
    }
    
    ////////////////////////////
    // ODER BOOK - BID ORDERS //
    ////////////////////////////
  //  function getBuyOrderBook(string memory symbolName) public pure returns(uint[], uint[]){ 
    // returns first array: amount for the price and the second one for the volume
    // example: someone buys 1000 weis (first returned value) for 5000 tokens (second returned value)
  
 //   }
    
     ////////////////////////////
    // ODER BOOK - ASK ORDERS //
    ////////////////////////////
   //   function getSellOrderBook(string symbolName) pure returns(uint[], uint[]){ 
        
   // }
    
     ////////////////////////////
    // NEW ODER - BID ORDER //
    ////////////////////////////
 //   function buyToken(string symbolName, uint priceInWei, uint amount){
        
//    }
    
       ////////////////////////////
    // NEW ODER - ASK ORDER //
    ////////////////////////////
  //  function sellToken(string symbolName, uint priceInWei, uint amount) {
        
 //   }
    
    //////////////////////////////
    // CANCEL LIMIT ORDER LOGIC //
    /////////////////////////////
  //  function cancelOrder(string symbolName, bool isSellOrder, uint priceInWei, uint offerKey) {
        
  //  }
    
}