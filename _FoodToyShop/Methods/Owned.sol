pragma solidity ^0.5.0;

/* Ownership Maintaining Contract */

contract Owned {
  address public owner;

  /* Default Constructor */
  constructor() public {
    owner = msg.sender;
  }

  /* Make sure that the caller of a function is the owner of the contract */
  modifier onlyOwner() {
    require (msg.sender == owner);
    _;
  }

  /*
  Changes the address of the shop owner
  @new_owner: Address of the new owner
  */
  function transferOwnership(address new_owner) public onlyOwner {
    if (new_owner !=address(0) && new_owner != owner) {
      owner = new_owner;
    }
  }

}
