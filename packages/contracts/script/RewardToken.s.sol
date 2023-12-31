// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../src/forge/Script.sol";
import "../src/RewardToken.sol";

contract TokenScript is Script {

    function run() external {
        uint deployerPrivateKey = vm.envUint("PK");
        vm.startBroadcast(deployerPrivateKey);
        
        uint initialSupply = vm.envUint("INITIAL_SUPPLY");

        RewardToken rewardToken = new RewardToken(
            initialSupply
        );

        // silences warning.
        rewardToken;

        vm.stopBroadcast();
    }
}
