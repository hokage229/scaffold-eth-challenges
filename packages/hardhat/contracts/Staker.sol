// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    event Stake(address indexed sender, uint256 amount);

    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 30 seconds;
    bool public openForWithdraw;

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    function execute() public {
        require(timeLeft() == 0, "Deadline not expired");
        require(!exampleExternalContract.completed(), "Already completed");

        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        }

        openForWithdraw = true;
    }

    // Add a `withdraw()` function to let users withdraw their balance
    function withdraw() public {
        require(openForWithdraw, "Not allowed to withdraw");
        require(timeLeft() == 0, "Deadline not expired");
        require(balances[msg.sender] > 0, "No balance to withdraw");

        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        return deadline > block.timestamp ? deadline - block.timestamp : 0;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}
