// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
 
 
contract Staking {
   IERC20 public tokenToStake;
   IERC20 public rewardToken;
   mapping(address => uint256) public stakedAmount;
   mapping(address => uint256) public lastStakeTime;
 
   event Staked(address indexed user, uint256 amount);
   event Withdrawn(address indexed user, uint256 amount);
   event RewardPaid(address indexed user, uint256 reward);
 
   constructor(address _tokenToStake, address _rewardToken) {
       tokenToStake = IERC20(_tokenToStake);
       rewardToken = IERC20(_rewardToken);
   }
 
   function stake(uint256 amount) external {
       require(amount > 0, "Staking amount must be greater than 0");
       require(tokenToStake.balanceOf(msg.sender) >= amount, "Insufficient balance");
       require(tokenToStake.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
 
       if (stakedAmount[msg.sender] == 0) {
           lastStakeTime[msg.sender] = block.timestamp;
       }
 
       tokenToStake.transferFrom(msg.sender, address(this), amount);
       stakedAmount[msg.sender] += amount;
 
       emit Staked(msg.sender, amount);
   }
 
   function withdraw(uint256 amount) external {
       require(amount > 0, "Withdrawal amount must be greater than 0");
       require(stakedAmount[msg.sender] >= amount, "Insufficient staked amount");
 
       uint256 reward = getReward(msg.sender);
       if (reward > 0) {
           rewardToken.mint(msg.sender, reward);
           emit RewardPaid(msg.sender, reward);
       }
 
       stakedAmount[msg.sender] -= amount;
       tokenToStake.transfer(msg.sender, amount);
 
       emit Withdrawn(msg.sender, amount);
   }
 
   function getReward(address user) public view returns (uint256) {
       uint256 timeElapsed = block.timestamp - lastStakeTime[user];
       uint256 stakedAmountUser = stakedAmount[user];
       if (timeElapsed == 0 || stakedAmountUser == 0) {
           return 0;
       }
 
       uint256 reward = stakedAmountUser * timeElapsed;
 
       return reward;
   }
 
 
   function getStakedBalance(address user) public view returns (uint256) {
       return stakedAmount[user];
   }
}
 
interface IERC20 {
   function totalSupply() external view returns (uint);
 
   function balanceOf(address account) external view returns (uint);
 
   function transfer(address recipient, uint amount) external returns (bool);
 
   function allowance(address owner, address spender) external view returns (uint);
 
   function approve(address spender, uint amount) external returns (bool);
 
   function transferFrom(
       address sender,
       address recipient,
       uint amount
   ) external returns (bool);
 
   function mint(address to, uint256 amount) external;
   event Transfer(address indexed from, address indexed to, uint value);
   event Approval(address indexed owner, address indexed spender, uint value);
}
