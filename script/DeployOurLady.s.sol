// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {OurLady} from "../src/OurLady.sol";
import {AddConsumer, FundSubscription} from "./Interactions.s.sol";

contract DeployOurLady is Script {
    function run() external returns (OurLady, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        AddConsumer addConsumer = new AddConsumer();
        (
            uint64 subscriptionId,
            bytes32 gasLane,
            uint256 automationUpdateInterval,
            //uint256 raffleEntranceFee,
            uint32 callbackGasLimit,
            address vrfCoordinatorV2,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 6725) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinatorV2,
                deployerKey
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinatorV2,
                subscriptionId,
                link,
                deployerKey
            );
        }

        vm.startBroadcast(deployerKey);
        OurLady ourLady = new OurLady(
            subscriptionId,
            gasLane,
            automationUpdateInterval,
            callbackGasLimit,
            vrfCoordinatorV2
        );
        vm.stopBroadcast();

        // We already have a broadcast in here
        addConsumer.addConsumer(
            address(ourLady),
            vrfCoordinatorV2,
            subscriptionId,
            deployerKey
        );
        return (ourLady, helperConfig);
    }
}
