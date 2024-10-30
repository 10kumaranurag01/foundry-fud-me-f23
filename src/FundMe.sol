// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// Custom error
error FundMe__NotOwner();

contract FundMe {
    // Attaches the library's functions to all uint256 varables
    using PriceConverter for uint256;

    // Adding constant reduces the gas used
    uint256 public constant MINIMUM_USD = 5 * 1e18;

    address[] private s_funders;
    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;
    // immutable also saves gas
    // constant and immutable variables are stored in the contract's bytecode instead of storing in storage slot of the contract
    // in constants the values are assigned during compile time, but in immutable values are assigned during deployment
    address private immutable i_owner;
    AggregatorV3Interface private s_pricefeed;

    // Constructor runs when thwe contract is first deployed and the owner variable is set
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_pricefeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // Allow users to send $
        // Have a function $ sent
        // 1. How do we send ETH to this contract
        //require(msg.value > 1e18, "didn't send enough ETH"); // 1e18 = 1 ETH = 1000000000000000000 = 1 * 10 ** 18

        // 2. How do we send $5 to this contract
        require(
            msg.value.getConversionRate(s_pricefeed) >= MINIMUM_USD,
            "didn't send enough ETH"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;

        // What is a revert?
        // Undo any actions that have been done, and send the remaining gas back.
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // Reset s_funders array
        s_funders = new address[](0);

        // Withdraw funds
        // msg.sender = address type
        // payable(msg.sender) = payable address type
        // this keyword refers to the present contract

        // transfer: automaticcaly reverts if any issue
        // payable(msg.sender).transfer(address(this).balance);
        // send: returns bool to verify the fund transfer
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    function getVersion() public view returns (uint256) {
        return s_pricefeed.version();
    }

    // modifier is used to give additional functionalities to a function
    modifier onlyOwner() {
        //_; this _ means that execute the function first the execute the below line

        //require(msg.sender == i_owner, "Sender is not owner");
        // Custom error also reduces gas usage
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }

        _; // this _ means that execute above line and then what else their in the function where it is called
    }

    // What happens if someone sends this contract ETH without calling the fund function

    //Below function runs if anybody tries to send ETH to our contract without using the fund() function or no function.
    receive() external payable {
        fund();
    }

    // Below function runs if anybody sends ETH by calling an invalid function
    fallback() external payable {
        fund();
    }

    /**
     * View/Pure Functions (Getters)
     */

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
