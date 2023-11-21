// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// import {Script} from "forge-std/Script.sol";
// import {HelperConfig} from "../script/HelperConfig.s.sol";
import {OurLady} from "src/OurLady.sol";

// import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";

/*is Script*/ contract DeployOurLady {
    function run() external returns (OurLady, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        AddConsumer addConsumer = new AddConsumer();
        (
            uint64 subscriptionId,
            bytes32 gasLane,
            uint256 automationUpdateInterval,
            uint32 callbackGasLimit,
            address vrfCoordinatorV2,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
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
            initialOwner,
            subscriptionId,
            gasLane,
            interval,
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
