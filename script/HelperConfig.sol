//SPDX-License-Identifier: MIT  
// 1. Deploy mocks when we are on a local anvil chain
// 2. Deploy the real contracts when we are on a testnet or mainnet
//3. Keep track of the deployed addresses so we can use them in our tests


   //If we are on a local anvil, we deploy  mocks
    //Otherwise, grab the existing address from the live networks
pragma solidity ^0.8.21;    

import {Script, console2} from "forge-std/Script.sol";
import {MockV3Aggregator} from "./MockV3Aggregator.sol";    

contract HelperConfig is Script{
    NetworkConfig public activeNetworkConfig;
    
         uint8 public constant DECIMALS = 8;
         int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
    }

    event HelperConfig_CreatedMockPriceFeed(address priceFeed);

    constructor() {
        if (block.chainid == 31337) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if {
            activeNetworkConfig = getorCreateAnvilEthConfig();
        } else {
            revert("Unsupported network");
        }
    }
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            priceFeed: 0x9326BFA02ADD2366b30bacB125260Af641031331
        });
    }

    function getorCreateAnvilEthConfig() public pure returns (NetworkConfig memory anvilNetworkConfig) {
         if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
              
            }
            vm.startBroadcast();
            MockV3Aggregator mockPriceFeed  = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
            vm.endBroadcast();
            emit HelperConfig_CreatedMockPriceFeed(address(mockPriceFeed)); 

            anvilNetworkConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});    
    }
}