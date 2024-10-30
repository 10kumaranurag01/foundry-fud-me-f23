// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.01 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // us -> FundMeTest -> DeployFundMe -> FundMe ("->" means "deploy/call")
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // Giving our fake user to start out
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5 * 1e18);
    }

    function testOwnerIsMessageSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); //The next line after this should revert
        fundMe.fund(); // This should revert, because the amount sent is less than the minimum
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The next TX will be sent by our fake user

        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); // The next TX will be sent by our fake user

        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw(); // This should revert, because the sender is not the owner
    }

    function testWithdrawWithASingleFunder() public funded {
        // 1. Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // Balance of the owner
        uint256 startingFundMeBalance = address(fundMe).balance; // Balance in the contract

        // 2. Act
        // uint256 gasStart = gasleft(); // Get the gas left before the transaction
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // The next TX will be sent by the owner
        fundMe.withdraw();
        // uint256 gasEnd = gasleft(); // Get the gas left after the transaction
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // Get the gas used by the withdrawal
        // console.log(gasUsed);

        // 3. Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
        assertEq(endingFundMeBalance, 0);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // If we want to create addresses from number, we use uint160
        uint160 startingFunderIndex = 1;
        // Funding by multiple funders
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //1. vm.prank -> new address

            //2. vm.deal -> fund the new address
            hoax(address(i), SEND_VALUE); // Creates a new address and fund it

            //3. fund the fundMe
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // Balance of the owner
        uint256 startingFundMeBalance = address(fundMe).balance; // Balance in the contract

        // Act
        vm.startPrank(fundMe.getOwner()); // The next TX will be sent by the owner
        fundMe.withdraw();
        vm.stopPrank(); // Stop the prank

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
        assertEq(endingFundMeBalance, 0);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // If we want to create addresses from number, we use uint160
        uint160 startingFunderIndex = 1;
        // Funding by multiple funders
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //1. vm.prank -> new address

            //2. vm.deal -> fund the new address
            hoax(address(i), SEND_VALUE); // Creates a new address and fund it

            //3. fund the fundMe
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // Balance of the owner
        uint256 startingFundMeBalance = address(fundMe).balance; // Balance in the contract

        // Act
        vm.startPrank(fundMe.getOwner()); // The next TX will be sent by the owner
        fundMe.cheaperWithdraw();
        vm.stopPrank(); // Stop the prank

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
        assertEq(endingFundMeBalance, 0);
    }
}
