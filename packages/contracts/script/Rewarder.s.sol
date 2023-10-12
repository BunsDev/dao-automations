// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../src/forge/Script.sol";
import "../src/Rewarder.sol";

contract RewarderScript is Script {

    function run() external {
        uint deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);
        address rewardTokenAddress = vm.envAddress("TOKEN_ADDRESS");

        Rewarder rewarder = new Rewarder(
            rewardTokenAddress
        );

        // silences warning.
        rewarder;

        vm.stopBroadcast();
    }
}
