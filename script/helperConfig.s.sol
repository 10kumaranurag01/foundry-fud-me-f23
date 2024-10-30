// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

// We are doing this to keep track of the contract addresses on different chains
// and deploy mocks when we are on a local anvil chain
contract HelperConfig is Script {
    // If we are on a local anvil chain we can deploy the mocks
    // Otherwise we can keep track of the contract addresses on different chains
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;
    uint256 public constant MAINNET_CHAIN_ID = 1;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ZKSYNC_MAINNET_CHAIN_ID = 324;
    uint256 public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == MAINNET_CHAIN_ID) {
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == ZKSYNC_MAINNET_CHAIN_ID) {
            activeNetworkConfig = getZkSyncMainnetEthConfig();
        } else if (block.chainid == ZKSYNC_SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getZkSyncSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getZkSyncSepoliaEthConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        // price feed address
        NetworkConfig memory zkSyncSepoliaConfig = NetworkConfig({
            priceFeed: 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF
        });
        return zkSyncSepoliaConfig;
    }

    function getZkSyncMainnetEthConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        // price feed address
        NetworkConfig memory zkSyncMainnetConfig = NetworkConfig({
            priceFeed: 0x6D41d1dc818112880b40e26BD6FD347E41008eDA
        });
        return zkSyncMainnetConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check if priceFeed is a valid address; if so, return activeNetworkConfig.
        // Address defailts to address(0) if its never deployed, so if we have ran it once it won't be a zero-address
        // We do this to avoid deploying the mocks multiple times.
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // 1. Deploy the mocks
        // 2. Return the mock address
        // We deploy our mock because we are on a local anvil chain and aggregatorV3Interface doesn't exist on the local chain

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        // price feed address
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}

// Deploy mocks when we are on a local anvil chain
// Keep track of contract addresses accross different chains
// Sepolia ETH/USD
// Mainnet ETH/USD
