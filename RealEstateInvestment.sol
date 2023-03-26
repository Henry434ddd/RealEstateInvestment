pragma solidity ^0.8.0;

contract RealEstateInvestment {

address payable public  owner;
uint public totalReadyToSellShare;
mapping(address => uint) public ownershipMap;
address [] private shareholders;
mapping(address => uint) public readyToSellShareMap;
address []  private currentSellers;

constructor() {
    owner = payable(msg.sender);
    ownershipMap[owner] = 100;
    shareholders.push(owner);
}

function getCurrentSellers() public view returns (address[] memory){
   
      return currentSellers;
}
function getShareholders() public view returns (address[] memory){
   
      return shareholders;
}






function SellShares(uint  percentage) public  {

        address sender = msg.sender;
        uint sellerCurrOwnership = ownershipMap[sender];
        require(sellerCurrOwnership >= percentage,"You don't have enough of money");

        //mapping api reference https://solidity-by-example.org/mapping/#:~:text=Maps%20are%20created%20with%20the,Mappings%20are%20not%20iterable.
        
        
        if (readyToSellShareMap[sender] > 0) {
            uint curr = readyToSellShareMap[sender];
            uint update = curr + percentage;
            readyToSellShareMap[sender] = update;

        } else {
            currentSellers.push(sender);
            readyToSellShareMap[sender] = percentage;
        }
        totalReadyToSellShare = totalReadyToSellShare + percentage;
        ownershipMap[sender] = sellerCurrOwnership - percentage;
        
}

function checkSellerExist(address seller) public view returns(bool) {

    
  for(uint i = 0; i < currentSellers.length; i++)
  {
    if(currentSellers[i] == seller)
    {
      return true;
    }
  }
    
    return false;
}

function foundArrPosition( address[] memory array,  address  add) private view returns(int) {

    int position = -1;
    for (uint i = 0; i < array.length; i++) {
        if (array[i] == add) {
            position = int(i);
        }
    }
    return position;


}

function removeCurrSeller(address seller) private {

        int sellerPosition = foundArrPosition(currentSellers,seller);
        require(sellerPosition != -1);
        currentSellers[uint(sellerPosition)] = currentSellers[uint(currentSellers.length) - 1];
        currentSellers.pop();
    
}

        


function buyShares(address payable seller, uint  percentage) public payable{
    address buyer = msg.sender;
    uint money = msg.value;
    require(checkSellerExist(seller));
    
    //get the number of percentage the seller want to sell
    uint sellerAvailShare = readyToSellShareMap[seller];
  
    //not enough to sell then return
    require(sellerAvailShare >= percentage, "not enough to sell"); 
    //ownership transfer
        //seller receive money
        require(money == percentage * (1 ether) ,"please sending enough of ether");
        seller.transfer(msg.value);

        uint updateShareNum = sellerAvailShare - percentage;
        
        //update currentSellers array if he sell all of his percentage
        if (updateShareNum == 0) {
            removeCurrSeller(seller);
        }
        //update readyToSellShareMap
        readyToSellShareMap[seller] = updateShareNum;
        //update total ready to sell
        totalReadyToSellShare = totalReadyToSellShare - percentage;

      

        //update buyer's ownership
        uint currOwnershipNum = ownershipMap[buyer];
        uint newOwnershipNum = currOwnershipNum + percentage;
        ownershipMap[buyer] = newOwnershipNum;

         //check buyer is existing investor or not existing investor
        bool isExisting = currOwnershipNum != 0;


        //update shareholder array
        if (!isExisting) {
            shareholders.push(buyer);
        }


}











}