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

        rewarder.registerUser(
            0x1F61947cDF6801E55B864690BFBcdeacf152C071,
            'luca.perfetto87@gmail.com'
        );

        rewarder.registerUser(
            0x221cAc060A2257C8F77B6eb1b03e36ea85A1675A,
            'anoncoiner@gmail.com'
        );

        // silences warning.
        rewarder;

        vm.stopBroadcast();
    }
}
