pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./FixedSupplyToken.sol";
//import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Exchange {
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
        uint lowestBuyPrice;
        uint amountBuyPrices;

        mapping(uint => OrderBook) sellBook;

        uint curSellPrice;
        uint highestSellPrice;
        uint amountSellPrices;
    }

    struct Temp {
        uint price;
        uint amount;
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
     event LimitSellOrderCreated(uint indexed _symbolIndex, address indexed _who, uint _amountTokens, uint _priceInWei, uint _orderKey);

    event SellOrderFulfilled(uint indexed _symbolIndex, uint _amount, uint _priceInWei, uint _orderKey);

    event SellOrderCanceled(uint indexed _symbolIndex, uint _priceInWei, uint _orderKey);

    event LimitBuyOrderCreated(uint indexed _symbolIndex, address indexed _who, uint _amountTokens, uint _priceInWei, uint _orderKey);

    event BuyOrderFulfilled(uint indexed _symbolIndex, uint _amount, uint _priceInWei, uint _orderKey);

    event BuyOrderCanceled(uint indexed _symbolIndex, uint _priceInWei, uint _orderKey);

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
    function addToken(string memory symbolName, address erc20TokenAddress) public {
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

    function getSymbolIndex(string memory symbolName) internal view returns (uint8) {

        for(uint8 i = 1; i <= symbolNameIndex; i++)
        {
            if(stringsEqual(tokens[i].symbolName, symbolName))
            {
                return i;
            }
        }
        return 0;

    }

    function getSymbolIndexOrThrow(string memory symbolName) public view returns (uint8) {
        uint8 index = getSymbolIndex(symbolName);
        require(index > 0);
        return index;
    }

    function stringsEqual(string storage _a, string memory _b) internal view returns (bool) {
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



    /////////////////////////////
    // ORDER BOOK - BID ORDERS //
    /////////////////////////////
     function getBuyOrderBook(string memory symbolName) public view returns (/*uint[] memory, uint[] memory*/Temp[] memory) {
              uint8 tokenNameIndex = getSymbolIndexOrThrow(symbolName);
            //  uint[] memory arrPricesBuy = new uint[](tokens[tokenNameIndex].amountBuyPrices);
           //   uint[] memory arrVolumesBuy = new uint[](tokens[tokenNameIndex].amountBuyPrices);
              Temp[] memory tempArray = new Temp[](tokens[tokenNameIndex].amountBuyPrices);

              uint whilePrice = tokens[tokenNameIndex].lowestBuyPrice;
              uint counter = 0;
              if (tokens[tokenNameIndex].curBuyPrice > 0) {
                  while (whilePrice <= tokens[tokenNameIndex].curBuyPrice) {
                      tempArray[counter].price = whilePrice;
                     // arrPricesBuy[counter] = whilePrice;
                      uint volumeAtPrice = 0;
                      uint offers_key = 0;

                      offers_key = tokens[tokenNameIndex].buyBook[whilePrice].offers_key;
                      while (offers_key <= tokens[tokenNameIndex].buyBook[whilePrice].offers_length) {
                          volumeAtPrice += tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount;
                          offers_key++;
                      }

                      tempArray[counter].amount = volumeAtPrice;
                      //arrVolumesBuy[counter] = volumeAtPrice;

                      //next whilePrice
                      if (whilePrice == tokens[tokenNameIndex].buyBook[whilePrice].higherPrice) {
                          break;
                      }
                      else {
                          whilePrice = tokens[tokenNameIndex].buyBook[whilePrice].higherPrice;
                      }
                      counter++;

                  }
              }

              return tempArray;//(arrPricesBuy, arrVolumesBuy);

          }



     ////////////////////////////
    // ODER BOOK - ASK ORDERS //
    ////////////////////////////
    function getSellOrderBook(string memory symbolName) public view returns (uint[] memory, uint[] memory) {
           uint8 tokenNameIndex = getSymbolIndexOrThrow(symbolName);
           uint[] memory arrPricesSell = new uint[](tokens[tokenNameIndex].amountSellPrices);
           uint[] memory arrVolumesSell = new uint[](tokens[tokenNameIndex].amountSellPrices);
           uint sellWhilePrice = tokens[tokenNameIndex].curSellPrice;
           uint sellCounter = 0;
           if (tokens[tokenNameIndex].curSellPrice > 0) {
               while (sellWhilePrice <= tokens[tokenNameIndex].highestSellPrice) {
                   arrPricesSell[sellCounter] = sellWhilePrice;
                   uint sellVolumeAtPrice = 0;
                   uint sell_offers_key = 0;

                   sell_offers_key = tokens[tokenNameIndex].sellBook[sellWhilePrice].offers_key;
                   while (sell_offers_key <= tokens[tokenNameIndex].sellBook[sellWhilePrice].offers_length) {
                       sellVolumeAtPrice += tokens[tokenNameIndex].sellBook[sellWhilePrice].offers[sell_offers_key].amount;
                       sell_offers_key++;
                   }

                   arrVolumesSell[sellCounter] = sellVolumeAtPrice;

                   //next whilePrice
                   if (tokens[tokenNameIndex].sellBook[sellWhilePrice].higherPrice == 0) {
                       break;
                   }
                   else {
                       sellWhilePrice = tokens[tokenNameIndex].sellBook[sellWhilePrice].higherPrice;
                   }
                   sellCounter++;

               }
           }

           //sell part
           return (arrPricesSell, arrVolumesSell);
    }
    ////////////////////////////
    // NEW ODER - BID ORDER //
    ////////////////////////////
     function buyToken(string memory symbolName, uint priceInWei, uint amount) public {
           uint8 tokenNameIndex = getSymbolIndexOrThrow(symbolName);
           uint total_amount_ether_necessary = 0;

           if (tokens[tokenNameIndex].amountSellPrices == 0 || tokens[tokenNameIndex].curSellPrice > priceInWei) {
               //if we have enough ether, we can buy that:
               total_amount_ether_necessary = amount * priceInWei;

               //overflow check
               require(total_amount_ether_necessary >= amount);
               require(total_amount_ether_necessary >= priceInWei);
               require(balanceEthForAddress[msg.sender] >= total_amount_ether_necessary);
               require(balanceEthForAddress[msg.sender] - total_amount_ether_necessary >= 0);
               require(balanceEthForAddress[msg.sender] - total_amount_ether_necessary <= balanceEthForAddress[msg.sender]);

               //first deduct the amount of ether from our balance
               balanceEthForAddress[msg.sender] -= total_amount_ether_necessary;

               //limit order: we don't have enough offers to fulfill the amount

               //add the order to the orderBook
               addBuyOffer(tokenNameIndex, priceInWei, amount, msg.sender);
               //and emit the event.
               emit LimitBuyOrderCreated(tokenNameIndex, msg.sender, amount, priceInWei, tokens[tokenNameIndex].buyBook[priceInWei].offers_length);
           }
           else {
               //market order: current sell price is smaller or equal to buy price!

               //1st: find the "cheapest sell price" that is lower than the buy amount  [buy: 60@5000] [sell: 50@4500] [sell: 5@5000]
               //2: buy up the volume for 4500
               //3: buy up the volume for 5000
               //if still something remaining -> buyToken

               //2: buy up the volume
               //2.1 add ether to seller, add symbolName to buyer until offers_key <= offers_length

               uint total_amount_ether_available = 0;
               uint whilePrice = tokens[tokenNameIndex].curSellPrice;
               uint amountNecessary = amount;
               uint offers_key;
               while (whilePrice <= priceInWei && amountNecessary > 0) {//we start with the smallest sell price.
                   offers_key = tokens[tokenNameIndex].sellBook[whilePrice].offers_key;
                   while (offers_key <= tokens[tokenNameIndex].sellBook[whilePrice].offers_length && amountNecessary > 0) {//and the first order (FIFO)
                       uint volumeAtPriceFromAddress = tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount;

                       //Two choices from here:
                       //1) one person offers not enough volume to fulfill the market order - we use it up completely and move on to the next person who offers the symbolName
                       //2) else: we make use of parts of what a person is offering - lower his amount, fulfill out order.
                       if (volumeAtPriceFromAddress <= amountNecessary) {
                           total_amount_ether_available = volumeAtPriceFromAddress * whilePrice;

                           require(balanceEthForAddress[msg.sender] >= total_amount_ether_available);
                           require(balanceEthForAddress[msg.sender] - total_amount_ether_available <= balanceEthForAddress[msg.sender]);
                           //first deduct the amount of ether from our balance
                           balanceEthForAddress[msg.sender] -= total_amount_ether_available;

                           require(tokenBalanceForAddress[msg.sender][tokenNameIndex] + volumeAtPriceFromAddress >= tokenBalanceForAddress[msg.sender][tokenNameIndex]);
                           require(balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] + total_amount_ether_available >= balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who]);
                           //overflow check
                           //this guy offers less or equal the volume that we ask for, so we use it up completely.
                           tokenBalanceForAddress[msg.sender][tokenNameIndex] += volumeAtPriceFromAddress;
                           tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount = 0;
                           balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] += total_amount_ether_available;
                           tokens[tokenNameIndex].sellBook[whilePrice].offers_key++;

                           emit SellOrderFulfilled(tokenNameIndex, volumeAtPriceFromAddress, whilePrice, offers_key);

                           amountNecessary -= volumeAtPriceFromAddress;
                       }
                       else {
                           require(tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount > amountNecessary);//sanity

                           total_amount_ether_necessary = amountNecessary * whilePrice;
                           require(balanceEthForAddress[msg.sender] - total_amount_ether_necessary <= balanceEthForAddress[msg.sender]);

                           //first deduct the amount of ether from our balance
                           balanceEthForAddress[msg.sender] -= total_amount_ether_necessary;

                           require(balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] + total_amount_ether_necessary >= balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who]);
                           //overflow check
                           //this guy offers more than we ask for. We reduce his stack, add the tokens to us and the ether to him.
                           tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount -= amountNecessary;
                           balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] += total_amount_ether_necessary;
                           tokenBalanceForAddress[msg.sender][tokenNameIndex] += amountNecessary;

                           amountNecessary = 0;
                           //we have fulfilled our order
                           emit SellOrderFulfilled(tokenNameIndex, amountNecessary, whilePrice, offers_key);
                       }

                       //if it was the last offer for that price, we have to set the curBuyPrice now lower. Additionally we have one offer less...
                       if (
                       offers_key == tokens[tokenNameIndex].sellBook[whilePrice].offers_length &&
                       tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount == 0
                       ) {

                           tokens[tokenNameIndex].amountSellPrices--;
                           //we have one price offer less here...
                           //next whilePrice
                           if (whilePrice == tokens[tokenNameIndex].sellBook[whilePrice].higherPrice || tokens[tokenNameIndex].buyBook[whilePrice].higherPrice == 0) {
                               tokens[tokenNameIndex].curSellPrice = 0;
                               //we have reached the last price
                           }
                           else {
                               tokens[tokenNameIndex].curSellPrice = tokens[tokenNameIndex].sellBook[whilePrice].higherPrice;
                               tokens[tokenNameIndex].sellBook[tokens[tokenNameIndex].buyBook[whilePrice].higherPrice].lowerPrice = 0;
                           }
                       }
                       offers_key++;
                   }

                   //we set the curSellPrice again, since when the volume is used up for a lowest price the curSellPrice is set there...
                   whilePrice = tokens[tokenNameIndex].curSellPrice;
               }

               if (amountNecessary > 0) {
                   buyToken(symbolName, priceInWei, amountNecessary);
                   //add a limit order!
               }
           }
       }

       ///////////////////////////
       // BID LIMIT ORDER LOGIC //
       ///////////////////////////
       function addBuyOffer(uint8 tokenIndex, uint priceInWei, uint amount, address who) internal {
           // Increase offers length
           tokens[tokenIndex].buyBook[priceInWei].offers_length ++;
           // Add new offer for this price for this token
           tokens[tokenIndex].buyBook[priceInWei].offers[tokens[tokenIndex].buyBook[priceInWei].offers_length] = Offer(amount, who);

           // Take care of order linked list only if this is the first offer for this price
           if(tokens[tokenIndex].buyBook[priceInWei].offers_length == 1)
           {
               tokens[tokenIndex].buyBook[priceInWei].offers_key = 1;
               // We have a new buy order - increase the counter, so we can set the getOrderBook array later
               tokens[tokenIndex].amountBuyPrices ++;

               // LowerPrice and HigherPrice have to be set
               uint curBuyPrice = tokens[tokenIndex].curBuyPrice;
               uint lowestBuyPrice = tokens[tokenIndex].lowestBuyPrice;
               if(lowestBuyPrice == 0 || lowestBuyPrice > priceInWei)
               {
                   if(curBuyPrice == 0)
                   {
                       // There is no buy Order yet, we insert the first one ...
                       tokens[tokenIndex].curBuyPrice = priceInWei;
                       tokens[tokenIndex].buyBook[priceInWei].higherPrice = priceInWei;
                       tokens[tokenIndex].buyBook[priceInWei].lowerPrice = 0;
                   }
                   else
                   {
                       // find the current lowestBuyPrice and change it's 'lower' price
                       tokens[tokenIndex].buyBook[lowestBuyPrice].lowerPrice = priceInWei;
                       tokens[tokenIndex].buyBook[priceInWei].higherPrice = lowestBuyPrice;
                       tokens[tokenIndex].buyBook[priceInWei].lowerPrice = 0;
                   }
                   tokens[tokenIndex].lowestBuyPrice = priceInWei;
               }
               else if(curBuyPrice < priceInWei) // this buy order is the new highest price
               {
                   tokens[tokenIndex].buyBook[curBuyPrice].higherPrice = priceInWei;
                   tokens[tokenIndex].buyBook[priceInWei].lowerPrice = curBuyPrice;
                   tokens[tokenIndex].buyBook[priceInWei].higherPrice = priceInWei;
                   tokens[tokenIndex].curBuyPrice = priceInWei;
               }
               else {
                   // We are somewhere in the middle. We need to find the right spot first
                   uint price = tokens[tokenIndex].curBuyPrice;
                   bool placeFound = false;
                   while(price > 0 && !placeFound)
                   {
                       if(price < priceInWei
                       && tokens[tokenIndex].buyBook[price].higherPrice > priceInWei)
                       {
                           // place for this order is found
                           placeFound = true;
                           // Set lowerPrice and higherPrice for this buy order
                           tokens[tokenIndex].buyBook[priceInWei].lowerPrice =  price;
                           tokens[tokenIndex].buyBook[priceInWei].higherPrice =  tokens[tokenIndex].buyBook[price].higherPrice;
                           // Set the higherPrice'd order-book entries lower pric to the current price
                           tokens[tokenIndex].buyBook[tokens[tokenIndex].buyBook[price].higherPrice].lowerPrice = priceInWei;
                           // Set the lowerPrices'd order-book entries higherPrice to the current Price
                           tokens[tokenIndex].buyBook[price].higherPrice = priceInWei;
                       }

                       price = tokens[tokenIndex].buyBook[price].lowerPrice;

                   }
               }

           }


       }
     ////////////////////////////
    // NEW ODER - ASK ORDER //
    ////////////////////////////
     function sellToken(string memory symbolName, uint priceInWei, uint amount) public returns (string memory) {
             uint8 tokenNameIndex = getSymbolIndexOrThrow(symbolName);
             uint total_amount_ether_necessary = 0;
             uint total_amount_ether_available = 0;


             if (tokens[tokenNameIndex].amountBuyPrices == 0 || tokens[tokenNameIndex].curBuyPrice < priceInWei) {

                 //if we have enough ether, we can buy that:
                 total_amount_ether_necessary = amount * priceInWei;

                 //overflow check
                 require(total_amount_ether_necessary >= amount);
                 require(total_amount_ether_necessary >= priceInWei);
                 require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amount);
                 require(tokenBalanceForAddress[msg.sender][tokenNameIndex] - amount >= 0);
                 require(balanceEthForAddress[msg.sender] + total_amount_ether_necessary >= balanceEthForAddress[msg.sender]);

                 //actually subtract the amount of tokens to change it then
                 tokenBalanceForAddress[msg.sender][tokenNameIndex] -= amount;

                 //limit order: we don't have enough offers to fulfill the amount

                 //add the order to the orderBook
                 addSellOffer(tokenNameIndex, priceInWei, amount, msg.sender);
                 //and emit the event.
                 emit LimitSellOrderCreated(tokenNameIndex, msg.sender, amount, priceInWei, tokens[tokenNameIndex].sellBook[priceInWei].offers_length);

             }
             else {
                 //market order: current buy price is bigger or equal to sell price!

                 //1st: find the "highest buy price" that is higher than the sell amount  [buy: 60@5000] [buy: 50@4500] [sell: 500@4000]
                 //2: sell up the volume for 5000
                 //3: sell up the volume for 4500
                 //if still something remaining -> sellToken limit order

                 //2: sell up the volume
                 //2.1 add ether to seller, add symbolName to buyer until offers_key <= offers_length


                 uint whilePrice = tokens[tokenNameIndex].curBuyPrice;
                 uint amountNecessary = amount;
                 uint offers_key;
                 while (whilePrice >= priceInWei && amountNecessary > 0) {//we start with the highest buy price.
                     offers_key = tokens[tokenNameIndex].buyBook[whilePrice].offers_key;
                     while (offers_key <= tokens[tokenNameIndex].buyBook[whilePrice].offers_length && amountNecessary > 0) {//and the first order (FIFO)
                         uint volumeAtPriceFromAddress = tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount;


                         //Two choices from here:
                         //1) one person offers not enough volume to fulfill the market order - we use it up completely and move on to the next person who offers the symbolName
                         //2) else: we make use of parts of what a person is offering - lower his amount, fulfill out order.
                         if (volumeAtPriceFromAddress <= amountNecessary) {
                             total_amount_ether_available = volumeAtPriceFromAddress * whilePrice;


                             //overflow check
                             require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= volumeAtPriceFromAddress);
                             //actually subtract the amount of tokens to change it then
                             tokenBalanceForAddress[msg.sender][tokenNameIndex] -= volumeAtPriceFromAddress;

                             //overflow check
                             require(tokenBalanceForAddress[msg.sender][tokenNameIndex] - volumeAtPriceFromAddress >= 0);
                             require(tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] + volumeAtPriceFromAddress >= tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex]);
                             require(balanceEthForAddress[msg.sender] + total_amount_ether_available >= balanceEthForAddress[msg.sender]);

                             //this guy offers less or equal the volume that we ask for, so we use it up completely.
                             tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] += volumeAtPriceFromAddress;
                             tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount = 0;
                             balanceEthForAddress[msg.sender] += total_amount_ether_available;
                             tokens[tokenNameIndex].buyBook[whilePrice].offers_key++;
                             emit SellOrderFulfilled(tokenNameIndex, volumeAtPriceFromAddress, whilePrice, offers_key);


                             amountNecessary -= volumeAtPriceFromAddress;
                         }
                         else {
                             require(volumeAtPriceFromAddress - amountNecessary > 0);
                             //just for sanity
                             total_amount_ether_necessary = amountNecessary * whilePrice;
                             //we take the rest of the outstanding amount

                             //overflow check
                             require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amountNecessary);
                             //actually subtract the amount of tokens to change it then
                             tokenBalanceForAddress[msg.sender][tokenNameIndex] -= amountNecessary;

                             //overflow check
                             require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amountNecessary);
                             require(balanceEthForAddress[msg.sender] + total_amount_ether_necessary >= balanceEthForAddress[msg.sender]);
                             require(tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] + amountNecessary >= tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex]);

                             //this guy offers more than we ask for. We reduce his stack, add the eth to us and the symbolName to him.
                             tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount -= amountNecessary;
                             balanceEthForAddress[msg.sender] += total_amount_ether_necessary;
                             tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] += amountNecessary;

                             emit SellOrderFulfilled(tokenNameIndex, amountNecessary, whilePrice, offers_key);

                             amountNecessary = 0;
                             //we have fulfilled our order
                         }

                         //if it was the last offer for that price, we have to set the curBuyPrice now lower. Additionally we have one offer less...
                         if (
                         offers_key == tokens[tokenNameIndex].buyBook[whilePrice].offers_length &&
                         tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount == 0
                         ) {

                             tokens[tokenNameIndex].amountBuyPrices--;
                             //we have one price offer less here...
                             //next whilePrice
                             if (whilePrice == tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice || tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice == 0) {
                                 tokens[tokenNameIndex].curBuyPrice = 0;
                                 //we have reached the last price
                             }
                             else {
                                 tokens[tokenNameIndex].curBuyPrice = tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice;
                                 tokens[tokenNameIndex].buyBook[tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice].higherPrice = tokens[tokenNameIndex].curBuyPrice;
                             }
                         }
                         offers_key++;
                     }

                     //we set the curSellPrice again, since when the volume is used up for a lowest price the curSellPrice is set there...
                     whilePrice = tokens[tokenNameIndex].curBuyPrice;
                 }

                 if (amountNecessary > 0) {
                     sellToken(symbolName, priceInWei, amountNecessary);
                     //add a limit order, we couldn't fulfill all the orders!
                 }

             }
       }

       ///////////////////////////
       // BID LIMIT ORDER LOGIC //
       ///////////////////////////
      function addSellOffer(uint8 _tokenIndex, uint priceInWei, uint amount, address who) internal {
           tokens[_tokenIndex].sellBook[priceInWei].offers_length++;
           tokens[_tokenIndex].sellBook[priceInWei].offers[tokens[_tokenIndex].sellBook[priceInWei].offers_length] = Offer(amount, who);


           if (tokens[_tokenIndex].sellBook[priceInWei].offers_length == 1) {
               tokens[_tokenIndex].sellBook[priceInWei].offers_key = 1;
               //we have a new sell order - increase the counter, so we can set the getOrderBook array later
               tokens[_tokenIndex].amountSellPrices++;

               //lowerPrice and higherPrice have to be set
               uint curSellPrice = tokens[_tokenIndex].curSellPrice;

               uint highestSellPrice = tokens[_tokenIndex].highestSellPrice;
               if (highestSellPrice == 0 || highestSellPrice < priceInWei) {
                   if (curSellPrice == 0) {
                       //there is no sell order yet, we insert the first one...
                       tokens[_tokenIndex].curSellPrice = priceInWei;
                       tokens[_tokenIndex].sellBook[priceInWei].higherPrice = 0;
                       tokens[_tokenIndex].sellBook[priceInWei].lowerPrice = 0;
                   }
                   else {

                       //this is the highest sell order
                       tokens[_tokenIndex].sellBook[highestSellPrice].higherPrice = priceInWei;
                       tokens[_tokenIndex].sellBook[priceInWei].lowerPrice = highestSellPrice;
                       tokens[_tokenIndex].sellBook[priceInWei].higherPrice = 0;
                   }

                   tokens[_tokenIndex].highestSellPrice = priceInWei;

               }
               else if (curSellPrice > priceInWei) {
                   //the offer to sell is the lowest one, we don't need to find the right spot
                   tokens[_tokenIndex].sellBook[curSellPrice].lowerPrice = priceInWei;
                   tokens[_tokenIndex].sellBook[priceInWei].higherPrice = curSellPrice;
                   tokens[_tokenIndex].sellBook[priceInWei].lowerPrice = 0;
                   tokens[_tokenIndex].curSellPrice = priceInWei;

               }
               else {
                   //we are somewhere in the middle, we need to find the right spot first...

                   uint sellPrice = tokens[_tokenIndex].curSellPrice;
                   bool weFoundIt = false;
                   while (sellPrice > 0 && !weFoundIt) {
                       if (
                       sellPrice < priceInWei &&
                       tokens[_tokenIndex].sellBook[sellPrice].higherPrice > priceInWei
                       ) {
                           //set the new order-book entry higher/lowerPrice first right
                           tokens[_tokenIndex].sellBook[priceInWei].lowerPrice = sellPrice;
                           tokens[_tokenIndex].sellBook[priceInWei].higherPrice = tokens[_tokenIndex].sellBook[sellPrice].higherPrice;

                           //set the higherPrice'd order-book entries lowerPrice to the current Price
                           tokens[_tokenIndex].sellBook[tokens[_tokenIndex].sellBook[sellPrice].higherPrice].lowerPrice = priceInWei;
                           //set the lowerPrice'd order-book entries higherPrice to the current Price
                           tokens[_tokenIndex].sellBook[sellPrice].higherPrice = priceInWei;

                           //set we found it.
                           weFoundIt = true;
                       }
                       sellPrice = tokens[_tokenIndex].sellBook[sellPrice].higherPrice;
                   }
               }
           }
       }

    //////////////////////////////
    // CANCEL LIMIT ORDER LOGIC //
    /////////////////////////////
   function cancelOrder(string memory symbolName, bool isSellOrder, uint priceInWei, uint offerKey) public {
          uint8 symbolNameIndex = getSymbolIndexOrThrow(symbolName);
          if (isSellOrder) {
              require(tokens[symbolNameIndex].sellBook[priceInWei].offers[offerKey].who == msg.sender);

              uint tokensAmount = tokens[symbolNameIndex].sellBook[priceInWei].offers[offerKey].amount;
              require(tokenBalanceForAddress[msg.sender][symbolNameIndex] + tokensAmount >= tokenBalanceForAddress[msg.sender][symbolNameIndex]);


              tokenBalanceForAddress[msg.sender][symbolNameIndex] += tokensAmount;
              tokens[symbolNameIndex].sellBook[priceInWei].offers[offerKey].amount = 0;
              emit SellOrderCanceled(symbolNameIndex, priceInWei, offerKey);

          }
          else {
              require(tokens[symbolNameIndex].buyBook[priceInWei].offers[offerKey].who == msg.sender);
              uint etherToRefund = tokens[symbolNameIndex].buyBook[priceInWei].offers[offerKey].amount * priceInWei;
              require(balanceEthForAddress[msg.sender] + etherToRefund >= balanceEthForAddress[msg.sender]);

              balanceEthForAddress[msg.sender] += etherToRefund;
              tokens[symbolNameIndex].buyBook[priceInWei].offers[offerKey].amount = 0;
              emit BuyOrderCanceled(symbolNameIndex, priceInWei, offerKey);
          }
      }
    
}