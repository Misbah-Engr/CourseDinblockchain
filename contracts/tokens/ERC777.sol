// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC777Token {
   string public name;
   string public symbol;
   uint8 public decimals = 18;
   uint256 public totalSupply;
   mapping(address => uint256) public balances;
   mapping(address => mapping(address => bool)) internal authorized;

   event Transfer(address indexed from, address indexed to, uint256 amount);
   event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
   event RevokedOperator(address indexed operator, address indexed tokenHolder);

   constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
       name = _name;
       symbol = _symbol;
       totalSupply = _initialSupply * 10 ** uint256(decimals);
       balances[msg.sender] = totalSupply;
   }

   modifier onlyAuthorized(address _operator, address _tokenHolder) {
       require(authorized[_operator][_tokenHolder], "Operator not authorized");
       _;
   }

   function balanceOf(address _tokenHolder) external view returns (uint256) {
       return balances[_tokenHolder];
   }

   function authorizeOperator(address _operator) external {
       authorized[_operator][msg.sender] = true;
       emit AuthorizedOperator(_operator, msg.sender);
   }

   function revokeOperator(address _operator) external {
       authorized[_operator][msg.sender] = false;
       emit RevokedOperator(_operator, msg.sender);
   }

   function send(address _to, uint256 _amount, bytes calldata _data) external {
       require(_to != address(0), "Invalid address");
       require(_amount <= balances[msg.sender], "Insufficient balance");
       balances[msg.sender] -= _amount;
       balances[_to] += _amount;
       emit Transfer(msg.sender, _to, _amount);
   }

   function operatorSend(
       address _from,
       address _to,
       uint256 _amount,
       bytes calldata _data,
       bytes calldata _operatorData
   ) external onlyAuthorized(msg.sender, _from) {
       require(_to != address(0), "Invalid address");
       require(_amount <= balances[_from], "Insufficient balance");
       balances[_from] -= _amount;
       balances[_to] += _amount;
       emit Transfer(_from, _to, _amount);
   }
}


