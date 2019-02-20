pragma solidity ^0.5.0;

import "./Methods/Owned.sol";
import "./Methods/SafeMath.sol";

/*
Title: Pet Supplies- Food and Toy Shop Contract
Author: Kyra Tsen
This contract implements a simple shop that can interact with registered customers.
Every customer has its own shopping cart.
*/

contract FoodToyShop is Owned, SafeMath {

  /* The seller's address */
  address public owner;
  
  /* Shop Internals */
  bytes32 public shop_name; // shop name
  uint256 private shop_balance;  // shop balance
  
  mapping (address => Customer) customers;
  mapping (uint256 => Product) products;

  /* Every customer has an address, name, balance and a shopping cart */
  struct Customer {
    address adr;
    bytes32 name;
    uint256 balance;
    Cart cart;
    }

  /*
  A shopping cart contains
  @products: an array of product ids
  @priceSum: a sum of product prices (automatically updated when customer adds or removes products)
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
    bytes32 description;
    uint256 price;
    uint256 default_amount;
  }

  /* Shop Events */
  event CustomerRegistered(address customer);
  event CustomerRegistrationFailed(address customer);
  event CustomerDeregistered(address customer);
  event CustomerDeregistrationFailed(address customer);  

  event ProductRegistered(uint256 productId);
  event ProductDeregistered(uint256 productId);
  event ProductRegistrationFailed(uint256 productId);
  event ProductDeregistrationFailed(uint256 productId);

  event CartProductInserted(address customer, uint256 prodId, uint256 prodPrice, uint256 priceSum);
  event CartProductInsertionFailed(address customer, uint256 prodId);
  event CartProductRemoved(address customer, uint256 prodId);
  event CartCheckoutCompleted(address customer, uint256 paymentSum);
  event CartCheckoutFailed(address customer, uint256 customerBalance, uint256 paymentSum);
  event CartEmptied(address customer);

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
  function registerProduct(uint256 id, bytes32 name, bytes32 description, uint256 price, uint256 default_amount) public onlyOwner returns (bool success) {
    if (price > 0) {
      products[id] = Product(id, name, description, price, default_amount);
      emit ProductRegistered(id);
      return true;
    }
    emit ProductRegistrationFailed(id);
    return false;
  }

  /*
  Removes a product from the list
  @id: Product ID
  Return success
  */
  function deregisterProduct(uint256 id) public onlyOwner returns (bool success) {
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
  Registers a new customer (only shop owners)
  @_address: Customer's address
  @_name: Customer's name
  @_balance: Customer's balance
  Return success
  */
  function registerCustomer(address _address, bytes32 _name, uint256 _balance) public onlyOwner returns (bool success) {
    if (_address != address(0)) {
      Customer memory customer = Customer({ adr: _address, name: _name, balance: _balance, cart: Cart(new uint256[](0), 0) });
        customers[_address] = customer;
        emit CustomerRegistered(_address);
        return true;
    }
    emit CustomerRegistrationFailed(_address);
    return false;
  }

  /*
  Removes a customer from the list (only shop owners)
  @_address: Customer's address
  Return success
  */
  function deregisterCustomer(address _address) public onlyOwner returns (bool success) {
    Customer memory customer = customers[_address];
    if (customer.adr != address(0)) {
      delete customers[_address];
      emit CustomerDeregistered(_address);
      return true;
    }
    emit CustomerDeregistrationFailed(_address);
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
    Customer storage cust = customers[msg.sender];
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
    uint256[] memory new_product_list = new uint256[](customers[msg.sender].cart.products.length - 1);
    uint256[] memory customerProds = customers[msg.sender].cart.products;
    for (uint256 i = 0; i < customerProds.length; i++) {
      if (i != pos_prods) {
        new_product_list[i] = customerProds[i];
      }
      else {
        customers[msg.sender].cart.priceSum -= products[customerProds[i]].price;
        emit CartProductRemoved(msg.sender, customerProds[i]);
      }
    }
    customers[msg.sender].cart.products = new_product_list;
  }

  /*
  Invokes a checkout process that'll use the current shopping cart to transfer balances between the current customer and the shop
  Return success
  */
  function checkoutCart() public returns (bool success) {
    Customer memory customer = customers[msg.sender];
    uint256 paymentSum = customer.cart.priceSum;
    if ((customer.balance >= paymentSum) && customer.cart.products.length > 0) {
      customer.balance -= paymentSum;
      customer.cart = Cart(new uint256[](0), 0);
      shop_balance += paymentSum;
      emit CartCheckoutCompleted(msg.sender, paymentSum);
      return true;
    }
    emit CartCheckoutFailed(msg.sender, customer.balance, paymentSum);
    return false;
  }

  /*
  Empties the shopping cart
  Returns success
  */
  function emptyCart() public returns (bool success) {
    Customer memory customer = customers[msg.sender];
    customer.cart = Cart(new uint256[](0), 0);
    emit CartEmptied(customer.adr);
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
  The caller address must be a registered customer
  Return (product_ids, price_sum
  */
  function getCart() public view returns (uint256[] memory product_ids, uint256 price_sum) {
    Customer memory customer = customers[msg.sender];
    uint256 len = customer.cart.products.length;
    uint256[] memory ids = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      ids[i] = products[i].id;
    }
    return (ids, customer.cart.priceSum);
  }

  /*
  Returns customer's balance
  Return @_balance: Customer's balance
  */
  function getBalance() public view returns (uint256 _balance) {
    return customers[msg.sender].balance;
  }

  /*
  Returns shop's own balance
  Return shop_balance
  */
  function getShopBalance() public onlyOwner view returns (uint256) {
    return shop_balance;
  }
}