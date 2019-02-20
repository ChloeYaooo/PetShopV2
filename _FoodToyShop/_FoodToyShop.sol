pragma solidity ^0.5.0;

import "./Methods/Owned.sol";
import "./Methods/SafeMath.sol";

/*
Title: Pet Supplies- Food and Toy Shop Contract
Author: Kyra Tsen
This contract implements a simple shop that can interact with registered users.
Every User has its own shopping cart.
*/

contract FoodToyShop is Owned, SafeMath {
    /* The seller's address */
    address payable public owner;
    uint256 public fee = 1000000000000000000;
  
    /* Shop Internals */
    bytes32 public shop_name; // shop name
    uint256 private shop_balance;  // shop balance
  
    mapping (address => User) users;
    mapping (uint256 => Product) products;

    /* Every User has an address, name, balance and a shopping cart */
    struct User {
        address payable addr;
        bytes32 name;
        uint256 balance;
        Cart cart;
    }
        
    /*
    A shopping cart contains
    @products: an array of product ids
    @priceSum: a sum of product prices (automatically updated when User adds or removes products)
    */
    struct Cart {
        uint256[] products;
        uint256 priceSum;  
    }  

    /*
    @id: Product id
    @name: Product name
    @description: Decription: 
    @default_amount: Amount of items in a single product
    */
    struct Product {
        uint256 id;
        bytes32 name;
        address seller;
        bytes32 description;
        uint256 price;
        uint256 default_amount;
    }

    /* Shop Events */
    event UserRegistered(address user);
    event UserRegistrationFailed(address user);
    event UserDeregistered(address user);
    event UserDeregistrationFailed(address user);  

    event ProductRegistered(uint256 productId);
    event ProductDeregistered(uint256 productId);
    event ProductRegistrationFailed(uint256 productId);
    event ProductDeregistrationFailed(uint256 productId);

    event CartProductInserted(address user, uint256 prodId, uint256 prodPrice, uint256 priceSum);
    event CartProductInsertionFailed(address user, uint256 prodId);
    event CartProductRemoved(address user, uint256 prodId);
    event CartCheckoutCompleted(address user, uint256 paymentSum);
    event CartCheckoutFailed(address user, uint256 userBalance, uint256 paymentSum);
    event CartEmptied(address user);

    function Shop() public {
        owner = msg.sender; //Default constructor
        shop_name = "pet-food-toy-shop";
        shop_balance = 0;
        assert (address(this).balance < 0);
    }

    /* Payable Fallback */
    function() external payable {

    }
    
    /*
    Register a single product
    @id: Product ID
    @name: Product Name
    @description: Product Description
    @price: Product Price
    @default_amount: Default amount of items in a single product        
    Return success
    */
    function registerProduct(uint256 id, bytes32 name, bytes32 description, uint256 price, uint256 default_amount) public payable {
        if (price > 0) {
            products[id] = Product(id, name, msg.sender, description, price, default_amount);
            owner.transfer(fee);
            emit ProductRegistered(id);
        }
        emit ProductRegistrationFailed(id);
    }
  /*
  Removes a product from the list
  @id: Product ID
  Return success
  */
    function deregisterProduct(uint256 id) public returns (bool success) {
        require(products[id].seller == owner || products[id].seller == msg.sender, "Only owner and seller can de-register product");
        Product memory product = products[id];
        if (product.id == id) {
            delete products[id];
            emit ProductDeregistered(id);
            return true;
        }
        emit ProductDeregistrationFailed(id);
        return false;
    }

    /*
    Registers a new User (only shop owners)
    @_address: User's address
    @_name: User's name
    @_balance: User's balance
    Return success
    */
    function registerUser(address payable _address, bytes32 _name, uint256 _balance) public onlyOwner returns (bool success) {        
        if (_address != address(0)) {
            User memory user = User({ addr: _address, name: _name, balance: _balance, cart: Cart(new uint256[](0), 0)});
            users[_address] = user;
            emit UserRegistered(_address);
            return true;
        }
        emit UserRegistrationFailed(_address);
        return false;
    }

    /*
    Removes a User from the list (only shop owners)
    @_address: User's address
    Return success
    */
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

    /*
    Inserts a product into the shopping cart
    This function returns a boolean and the positiom of the inserted product.
    The positional information can later be used to directly reference the product within the mapping
    @id: Product ID
    Return (success, position)
    */
    function insertProductIntoCart(uint256 id) public returns (bool success, uint256 pos_insert) {
        User storage cust = users[msg.sender];
        Product memory prod = products[id];
        uint256 prods_len = cust.cart.products.length;
        cust.cart.products.push(prod.id);
        uint256 cur_pSum = cust.cart.priceSum;
        cust.cart.priceSum = safeAdd(cur_pSum, prod.price);
        if (cust.cart.products.length > prods_len) {
            emit CartProductInserted(msg.sender, id, prod.price, cust.cart.priceSum);
            return (true, cust.cart.products.length - 1);
        }
        emit CartProductInsertionFailed(msg.sender, id);
        return (false, 0);
    }

    /*
    Removes a product entry from the shopping list
    @pos_prods: Product's position in the internal mapping
    */
    function removeProductFromCart(uint256 pos_prods) public {
        uint256[] memory new_product_list = new uint256[](users[msg.sender].cart.products.length - 1);
        uint256[] memory userProds = users[msg.sender].cart.products;
        for (uint256 i = 0; i < userProds.length; i++) {
            if (i != pos_prods) {
                new_product_list[i] = userProds[i];
            }
            else {
                users[msg.sender].cart.priceSum -= products[userProds[i]].price;
                emit CartProductRemoved(msg.sender, userProds[i]);
            }
        }
        users[msg.sender].cart.products = new_product_list;
    }

    /*
    Invokes a checkout process that'll use the current shopping cart to transfer balances between the current User and the shop
    Return success
    */
    function checkoutCart() public payable returns (bool success) {
        User memory user = users[msg.sender];
        uint256 paymentSum = user.cart.priceSum;
        if (user.cart.products.length > 0) {
            user.balance -= paymentSum;
            user.cart = Cart(new uint256[](0), 0);
            owner.transfer(paymentSum);
            shop_balance += paymentSum;
            emit CartCheckoutCompleted(msg.sender, paymentSum);
            return true;
        }
        emit CartCheckoutFailed(msg.sender, user.balance, paymentSum);
        return false;
    }

    /*
    Empties the shopping cart
    Returns success
    */
    function emptyCart() public returns (bool success) {
        User memory user = users[msg.sender];
        user.cart = Cart(new uint256[](0), 0);
        emit CartEmptied(user.addr);
        return true;
    }

    /*
    Changes the name of the shop
    @new_shop_name: New shop name
    Return success
    */
    function renameShopTo(bytes32 new_shop_name) public onlyOwner returns (bool success) {
        if (new_shop_name.length != 0 && new_shop_name.length <= 32) {
            shop_name = new_shop_name;
            return true;
        }
        return false;
    }

    /*
    Returns elements describing a product
    @id: Product ID
    Return (name, description, price, default amount)
    */
    function getProduct(uint256 id) public view returns (bytes32 name, bytes32 description, uint256 price, uint256 default_amount) {
        return (products[id].name, products[id].description, products[id].price, products[id].default_amount);
    }

    /*
    Returns a list of product ids and a complete price sum
    The caller address must be a registered User
    Return (product_ids, price_sum
    */
    function getCart() public view returns (uint256[] memory product_ids, uint256 price_sum) {
        User memory user = users[msg.sender];
        uint256 len = user.cart.products.length;
        uint256[] memory ids = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            ids[i] = products[i].id;
        }
        return (ids, user.cart.priceSum);
    }

    /*
    Returns User's balance
    Return @_balance: User's balance
    */
    function getBalance() public view returns (uint256 _balance) {
        return users[msg.sender].balance;
    }

    /*
    Returns shop's own balance
    Return shop_balance
    */
    function getShopBalance() public onlyOwner view returns (uint256) {
        return shop_balance;
    }

}