pragma solidity ^0.5.0;

contract Donate{
    
    address owner;
    bool public isDonating = false; // isDonating should be true when Donating starts
    uint public goal = 0; 
    uint public money =0;
    uint i =0;
    
    struct RequestDonating{
        string charityname;
        bool isRegistered;
        uint TotalMoney;
    }
    
    address[] public RequestDonatingList;
    
    mapping(address => RequestDonating) public RequestDonatingData;
    mapping(address => uint) public Money;
    
    /*Event for donating */
    event RequestDonate(address register, uint goal, string charityname);//request the donate
    event StartDonate(address donor, address charity);//starts donating
    //event donateStart(uint money);
    
    constructor() public {
        owner = msg.sender;
    }
    
    //register
     function register(string memory name, uint Total) public payable {
        
        require(isDonating == false);
        require(msg.sender == owner);
        
       
        RequestDonatingList.push(msg.sender);
        RequestDonating storage c = RequestDonatingData[msg.sender];
        require(!c.isRegistered);
        
        c.charityname = name;
        c.isRegistered = true;
        c.TotalMoney = Total;
        goal = Total;
        RequestDonatingData[msg.sender]=c;
        emit RequestDonate(msg.sender,  Total, name);

    }
    
    /* Stop register and start donating*/
    function startDonating() public {
        
        isDonating = true;
        require(msg.sender == owner);
        //emit donateStart(money);
    }
    
    
    //donate
    function donate(address charityAddr, uint donatemoney) public{
        require(isDonating ==true);
        money = money + donatemoney;
        Money[charityAddr] = money;
        emit StartDonate(msg.sender, charityAddr);
        
    }
    
    
    function getRequestDonatingList() public view returns (address[] memory) {
        
        return (RequestDonatingList);
    }

}