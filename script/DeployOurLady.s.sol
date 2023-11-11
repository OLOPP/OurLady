// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {OurLady} from "../src/OurLady.sol";
import {HelperConfig} from "./HelperConfig.sol";

contract DeployOurLady is Script {
    function run() external returns(OurLady) {

    HelperConfig helperConfig = new HelperConfig();

    function run() public {
        vm.broadcast();
    }
}
