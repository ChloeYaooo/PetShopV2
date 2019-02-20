pragma solidity ^0.5.1;

contract Hello {
    // add new
    uint countPet;
    
    struct User {
        uint password;
        uint tipe;
    }
    mapping(address => User) users;
    
    struct Pet {
        string name;
        string description;
        string kind;
        address userId;
    }
    mapping(uint => Pet) pets;
    
    function registerPet(address _addr, string memory _name, string memory _description, string memory _kind) public {
        if(users[_addr].tipe == 0) {
            pets[countPet].name = _name;
            pets[countPet].description = _description;
            pets[countPet].kind = _kind;   
            countPet++;
        }
    }
    
    function registerUser(address _addr, uint _password, uint _tipe) public {
        users[_addr].password = _password;
        users[_addr].tipe = _tipe;
    }
    
    function adopt(address _addr, uint _petId) public returns (bool) {
        if(users[_addr].tipe == 1) {
            pets[_petId].userId = _addr;
            return true;
        }
        return false;
    }
    
    function getPets(uint _petId) public returns (string memory name, string memory desc, string memory kind, address owner) {
        return (pets[_petId].name, pets[_petId].description, pets[_petId].kind, pets[_petId].userId);
    }
    
    function getTotalPet() public returns (uint) {
        return countPet;
    }

    function getUser(address _addr) public returns (uint pwd, uint tp) {
        return (users[_addr].password, users[_addr].tipe);
    }
}