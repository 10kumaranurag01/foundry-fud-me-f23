// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    // Gets the USD value of 1 ETH from chainlink oracle
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        // To interact with an external contract we need the contracts:
        // 1. Address = 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // 2. ABI

        ( ,int answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 1e18); // Here we got the value of 1 ETH in USD 
        // Multiplied by 1e18 bcz answer is in 8 decimal places and we need it in 18 decimal places same as wei
    }

    // Converts given ethAmount to its corresponding USD value
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) public view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        // Solidity rule: Always multiply before dividing
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
        return ethAmountInUsd;
    }
}