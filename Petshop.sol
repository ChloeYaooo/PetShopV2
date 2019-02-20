pragma solidity ^0.5.1;

import "./Owned.sol";
import "./SafeMath.sol";

contract Petshop is Owned, SafeMath {
    //The owner's address
    address public owner;
    //register Pet fee = 1 dxn
    uint256 public fee = 1000000000000000000;
  
    /* Shop Internals */
    string public shop_name; 
    uint256 private shop_balance;  
  
    mapping (address => User) users;
    mapping (uint256 => Pet) pets;

    struct User {
        address payable addr;
        string name;
        uint256 balance;
        Cart cart;
    }
    struct Cart {
        uint256[] pets;
        uint256 priceSum;  
    }  
    struct Pet {
        uint256 id;
        string name;
        string description;
        uint256 price;
        uint256 default_amount;
    }

    /* Shop Events */
    event UserRegistered(address user);
    event UserRegistrationFailed(address user);
    event UserDeregistered(address user);
    event UserDeregistrationFailed(address user);  

    event PetRegistered(uint256 petId);
    event PetDeregistered(uint256 petId);
    event PetRegistrationFailed(uint256 petId);
    event PetDeregistrationFailed(uint256 petId);

    event CartPetInserted(address user, uint256 prodId, uint256 prodPrice, uint256 priceSum);
    event CartPetInsertionFailed(address user, uint256 prodId);
    event CartPetRemoved(address user, uint256 prodId);
    event CartCheckoutCompleted(address user, uint256 paymentSum);
    event CartCheckoutFailed(address user, uint256 userBalance, uint256 paymentSum);
    event CartEmptied(address user);

    function Shop() public {
        owner = msg.sender; //Default constructor
        shop_name = "pet-adoption";
        shop_balance = 0;
        assert (address(this).balance < 0);
    }
   
    function registerPet(uint256 id, string memory name, string memory description, uint256 price, uint256 default_amount) public onlyOwner{
        if (price >= 0) {
            pets[id] = Pet(id, name, description, price, default_amount);
            emit PetRegistered(id);
        }
        emit PetRegistrationFailed(id);
    }
    function deregisterPet(uint256 id) public onlyOwner returns (bool success) {
        Pet memory pet = pets[id];
        if (pet.id == id) {
            delete pets[id];
            emit PetDeregistered(id);
            return true;
        }
        emit PetDeregistrationFailed(id);
        return false;
    }

    function registerUser(address payable _address, string memory _name, uint256 _balance) public onlyOwner returns (bool success) {        
        if (_address != address(0)) {
            User memory user = User({ addr: _address, name: _name, balance: _balance, cart: Cart(new uint256[](0), 0)});
            users[_address] = user;
            emit UserRegistered(_address);
            return true;
        }
        emit UserRegistrationFailed(_address);
        return false;
    }

    function deregisterUser(address _address) public onlyOwner returns (bool success) {
        User memory user = users[_address];
        if (user.addr != address(0)) {
            delete users[_address];
            emit UserDeregistered(_address);
            return true;
        }
        emit UserDeregistrationFailed(_address);
        return false;
    }

    function insertPetIntoCart(uint256 id) public returns (bool success, uint256 pos_insert) {
        User storage cust = users[msg.sender];
        Pet memory prod = pets[id];
        uint256 prods_len = cust.cart.pets.length;
        cust.cart.pets.push(prod.id);
        uint256 cur_pSum = cust.cart.priceSum;
        cust.cart.priceSum = safeAdd(cur_pSum, prod.price);
        if (cust.cart.pets.length > prods_len) {
            emit CartPetInserted(msg.sender, id, prod.price, cust.cart.priceSum);
            return (true, cust.cart.pets.length - 1);
        }
        emit CartPetInsertionFailed(msg.sender, id);
        return (false, 0);
    }

    function removePetFromCart(uint256 pos_prods) public {
        uint256[] memory new_pet_list = new uint256[](users[msg.sender].cart.pets.length - 1);
        uint256[] memory userProds = users[msg.sender].cart.pets;
        for (uint256 i = 0; i < userProds.length; i++) {
            if (i != pos_prods) {
                new_pet_list[i] = userProds[i];
            }
            else {
                users[msg.sender].cart.priceSum -= pets[userProds[i]].price;
                emit CartPetRemoved(msg.sender, userProds[i]);
            }
        }
        users[msg.sender].cart.pets = new_pet_list;
    }

    function checkoutCart() public returns (bool success) {
        User memory user = users[msg.sender];
        uint256 paymentSum = user.cart.priceSum;
        if ((user.balance >= paymentSum) && user.cart.pets.length > 0) {
            user.balance -= paymentSum;
            user.cart = Cart(new uint256[](0), 0);
            shop_balance += paymentSum;
            emit CartCheckoutCompleted(msg.sender, paymentSum);
            return true;
        }
        emit CartCheckoutFailed(msg.sender, user.balance, paymentSum);
        return false;
    }


    function emptyCart() public returns (bool success) {
        User memory user = users[msg.sender];
        user.cart = Cart(new uint256[](0), 0);
        emit CartEmptied(user.addr);
        return true;
    }

    function renameShopTo(string memory new_shop_name) public onlyOwner returns (bool success) {
        shop_name = new_shop_name;
        return true;
    }

    function getPet(uint256 id) public view returns (string memory name, string memory description, uint256 price, uint256 default_amount) {
        return (pets[id].name, pets[id].description, pets[id].price, pets[id].default_amount);
    }

    function getCart() public view returns (uint256[] memory pet_ids, uint256 price_sum) {
        User memory user = users[msg.sender];
        uint256 len = user.cart.pets.length;
        uint256[] memory ids = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            ids[i] = pets[i].id;
        }
        return (ids, user.cart.priceSum);
    }

    function getBalance() public view returns (uint256 _balance) {
        return users[msg.sender].balance;
    }

    function getShopBalance() public onlyOwner view returns (uint256) {
        return shop_balance;
    }

}