pragma solidity ^0.8.0;

contract RealEstateInvestment {

address public owner;
uint public totalReadyToSellShare;
mapping(address => uint) public ownershipMap;
address [] public shareholders;
mapping(address => uint) public readyToSellShareMap;
address [] public currentSellers;

constructor() {
    owner = msg.sender;
    ownershipMap[owner] = 100;
    shareholders.push(owner);
}

function getCurrentSellers() public view returns (address[] memory){
   
      return currentSellers;
}






function SellShares(uint  percentage) public  {

        address sender = msg.sender;

        require(ownershipMap[sender] >= percentage,"You don't have enough of money");

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
        
}












}