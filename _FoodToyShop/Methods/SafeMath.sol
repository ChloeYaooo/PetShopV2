pragma solidity ^0.5.0;

/* Safe Mathematical Operations Contract*/

contract SafeMath {

  /*
  Safely subtract two numbers without overflows
  @x: First operand
  @y: Second operand
  Return result
  */
  function safeSub(uint256 x, uint256 y) internal pure returns (uint256) {
    assert (y <= x);
    return x - y;
  }
  
  /*
  Safely add two numbers without overflows
  @x: First operand
  @y: Second operand
  Return @z: result 
  */
  function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
    uint256 z = x + y;
    assert (z >= x);
    return z;
  }

  /*
  Safely multiply two numbers without overflows
  @x: First operand
  @y: Second operand
  Return @z: result 
  */
  function safeMul(uint256 x, uint256 y) internal pure returns (uint256) {
    uint256 z = x * y;
    assert (z / x == y || x == 0);
    return z;
  } 

  /*
  Safely divide two numbers without overflows
  @x: First operand
  @y: Second operand
  Return @z: result  
  */
  function safeDiv(uint256 x, uint256 y) internal pure returns (uint256) {
    uint256 z = x / y;
    return z;
  }
}
