pragma solidity ^0.8.0;

contract RealEstateInvestment {
    address payable public owner;
    uint256 public totalReadyToSellShare;
    mapping(address => uint256) public ownershipMap;
    address[] private shareholders;
    mapping(address => uint256) public readyToSellShareMap;
    address[] private currentSellers;
    uint256 public currAssetPrice;

    constructor() {
        owner = payable(msg.sender);
        ownershipMap[owner] = 100;
        shareholders.push(owner);
    }

    function setCurrAssetPrice(uint256 price) public {
        require(msg.sender == owner, "only owner can change the price");
        currAssetPrice = price;
    }

    function getCurrentSellers() public view returns (address[] memory) {
        return currentSellers;
    }

    function getShareholders() public view returns (address[] memory) {
        return shareholders;
    }

    function SellShares(uint256 percentage) public {
        address sender = msg.sender;
        uint256 sellerCurrOwnership = ownershipMap[sender];
        require(
            sellerCurrOwnership >= percentage,
            "You don't have enough of shares to sell"
        );

        //mapping api reference https://solidity-by-example.org/mapping/#:~:text=Maps%20are%20created%20with%20the,Mappings%20are%20not%20iterable.

        if (readyToSellShareMap[sender] > 0) {
            uint256 curr = readyToSellShareMap[sender];
            uint256 update = curr + percentage;
            readyToSellShareMap[sender] = update;
        } else {
            currentSellers.push(sender);
            readyToSellShareMap[sender] = percentage;
        }
        totalReadyToSellShare = totalReadyToSellShare + percentage;
    }

    function checkSellerExist(address seller) public view returns (bool) {
        for (uint256 i = 0; i < currentSellers.length; i++) {
            if (currentSellers[i] == seller) {
                return true;
            }
        }

        return false;
    }

    function foundArrPosition(address[] memory array, address add) private view returns (int256) {
        int256 position = -1;
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == add) {
                position = int256(i);
            }
        }
        return position;
    }

    function removeCurrSeller(address seller) private {
        int256 sellerPosition = foundArrPosition(currentSellers, seller);
        require(sellerPosition != -1);
        currentSellers[uint256(sellerPosition)] = currentSellers[
            uint256(currentSellers.length) - 1
        ];
        currentSellers.pop();
    }

    event print(uint256 number);

    function buyShares(address payable seller, uint256 percentage) public payable {
        address buyer = msg.sender;
        address _seller = seller;
        uint256 money = msg.value;

        require(
            money >= checkShareToPrice(percentage) * (1 ether),
            "please sending enough of ether"
        );

        require(checkSellerExist(seller));

        //get the number of percentage the seller want to sell
        uint256 sellerAvailShare = readyToSellShareMap[seller];

        //not enough to sell then return
        require(sellerAvailShare >= percentage, "not enough to sell");
        //ownership transfer
        //seller receive money
        seller.transfer(msg.value);
        uint256 updateShareNum = sellerAvailShare - percentage;

        //update currentSellers array if he sell all of his percentage
        if (updateShareNum == 0) {
            removeCurrSeller(seller);
        }
        //update readyToSellShareMap
        readyToSellShareMap[_seller] = updateShareNum;

        //update seller's ownership
        ownershipMap[_seller] = ownershipMap[_seller] - percentage;
        emit print(ownershipMap[_seller]);

        //update total ready to sell
        totalReadyToSellShare = totalReadyToSellShare - percentage;

        //update buyer's ownership
        uint256 currOwnershipNum = ownershipMap[buyer];
        uint256 newOwnershipNum = currOwnershipNum + percentage;
        ownershipMap[buyer] = newOwnershipNum;

        //check buyer is existing investor or not existing investor
        bool isExisting = currOwnershipNum != 0;

        //update shareholder array
        if (!isExisting) {
            shareholders.push(buyer);
        }
    }

    function checkShareToPrice(uint256 percentage) public view returns (uint256) {
        return (currAssetPrice * percentage) / 100;
    }

    function transferOwnership(address payable newOwner) public {
        require(msg.sender == owner, "only owner can change the ownership");
        require(
            totalReadyToSellShare == 0,
            "new owner need to buy out all ready to sell shares"
        );

        owner = newOwner;
    }

    Tenant[] private tenantList;
    uint256 private lateRentFeePercent = 10;

    struct Tenant {
        address tenantAdd;
        uint256 monthlyPayment;
        uint256 latePaymentTimes;
        uint256 totalLateFee;
    }

    function getTenantList() public view returns (Tenant[] memory) {
        require(msg.sender == owner);
        return tenantList;
    }

    function assignTenant(address _tenant, uint256 monthlyPayment) public {
        require(msg.sender == owner, "Only owner can assign the renter");
        Tenant memory tenant = Tenant(_tenant, monthlyPayment, 0, 0);
        tenantList.push(tenant);
    }

    // API for crun job to update late fee to each tenant daily
    function updateLateFeeDaily() public {
        for (uint256 i = 0; i < tenantList.length; i++) {
            Tenant storage tenant = tenantList[i];

            if (tenant.latePaymentTimes > 0) {
                uint256 newFee = (tenant.latePaymentTimes *
                    tenant.monthlyPayment *
                    lateRentFeePercent) / 100;
                tenant.totalLateFee = tenant.totalLateFee + newFee;
            }
        }
    }

    // API for crun job to trigger the first day of the month, meaning each tenant's latepayment count will increase 1
    function updateMonthlyRentCount() public {
        for (uint256 i = 0; i < tenantList.length; i++) {
            Tenant storage tenant = tenantList[i];
            tenant.latePaymentTimes = tenant.latePaymentTimes + 1;
        }
    }

    //tenant pay late fee
    function payLateFee() public payable {
        address tenantAddr = msg.sender;
        uint256 tenantPosition = findTenantPosit(tenantAddr);
        Tenant storage tenant = tenantList[tenantPosition];
        uint256 currLateFee = tenant.totalLateFee;
        tenant.totalLateFee = currLateFee - msg.value;
    }

    function findTenantPosit(address addr)
        private
        view
        returns (uint256 position)
    {
        for (uint256 i = 0; i < tenantList.length; i++) {
            if (tenantList[i].tenantAdd == addr) {
                return i;
            }
        }
    }

    // pay money to the smart contract and the money will store in the contract  https://medium.com/coinmonks/blockchain-development-how-to-send-and-withdraw-money-from-a-solidity-smart-contract-bcbbd27ec1aa
    function payRent() public payable {
        uint256 totalRentReceived = getRentBalance();
        address tenantAddr = msg.sender;
        uint256 tenantPosition = findTenantPosit(tenantAddr);
        Tenant storage tenant = tenantList[tenantPosition];

        require(
            tenant.monthlyPayment * (1 ether) == msg.value,
            "The payment is not enough or it is over"
        );
        tenant.latePaymentTimes = tenant.latePaymentTimes - 1;

        //start to spread the money to each owner
        for (uint256 i = 0; i < shareholders.length; i++) {
            address payable shareHolder = payable(shareholders[i]);
            uint256 ownerShipPercent = ownershipMap[shareHolder];
            uint256 amountToPay = (totalRentReceived * ownerShipPercent) / 100;
            shareHolder.transfer(amountToPay);
        }
    }

    function getRentBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
