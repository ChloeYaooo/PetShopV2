pragma solidity ^0.5.0;

contract Assert {

    event TestEvent(bool indexed result, string message);
    
    function isTrue(bool b, string memory message) public returns (bool result) {
        result = b;
        _report(result, message);
    }

    function _report(bool result, string memory message) internal {
        if(result)
            emit TestEvent(true, "");
        else
            emit TestEvent(false, message);
    }
}