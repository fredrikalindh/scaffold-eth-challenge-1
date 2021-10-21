// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    deadline = block.timestamp + 1 days;
  }

  mapping (address => uint) public balances;

  uint public constant threshold = 1 ether;

  uint public immutable deadline;

  event Stake (
    address staker,
    uint amount
  );

  modifier afterDeadline() {
    require(block.timestamp < deadline, "Deadline not reached");
    _;
  }
  
  modifier notCompleted() {
    require(!exampleExternalContract.completed(), "Already completed");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() payable external {
    require (block.timestamp < deadline, "Too late to stake");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() external notCompleted afterDeadline {
    require(address(this).balance >= threshold, "Threshold not met");

    exampleExternalContract.complete{value: address(this).balance}();
  }


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() external notCompleted afterDeadline {
    require(address(this).balance < threshold, "Threshhold met");

    uint amount = balances[msg.sender];
    balances[msg.sender] = 0;
    (bool ok, ) = payable(msg.sender).call{value: amount}("");
    require(ok);
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint left) {
    if (block.timestamp < deadline) left = deadline - block.timestamp;
  }

}
