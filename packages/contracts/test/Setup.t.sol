// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 < 0.9.0;

import "../src/RewardToken.sol";
import { Rewarder } from "../src/Rewarder.sol";

import { stdStorage, StdStorage, Test, Vm } from "./utils/Test.sol";
import { Utilities } from "./utils/Utilities.sol";
import { console } from "./utils/test/console.sol";

contract Setup is Test {

    // contracts
    RewardToken RewardContract;
    Rewarder RewarderContract;

    // helpers
    Utilities internal utils;

    // constants
    uint public immutable INITIAL_SUPPLY = 1_000_000;
    string public EMAIL_ADDRESS_ONE = 'first@gmail.com';
    string public EMAIL_ADDRESS_TWO = 'second@gmail.com';

    // addresses
    address public TOKEN_ADDRESS;
    address public REWARDER_ADDRESS;

    address internal DEPLOYER_ADDRESS = address(this);
    address public OWNER_ADDRESS = 0x3B356568511d38EEa29939b41A2B1DA9b162C97E;
    address public USER_ADDRESS = address(0xbae);



    constructor() {
        // initializes: token
        RewardContract = new RewardToken(
            INITIAL_SUPPLY
        );

        TOKEN_ADDRESS = address(RewardContract);
        // console.log('[success]: token deployed');

        // initializes: rewarder
        RewarderContract = new Rewarder(
            TOKEN_ADDRESS
        );

        REWARDER_ADDRESS = address(RewarderContract);
        // console.log('[success]: rewarder deployed');
    }

    // helpers
    function toWei(uint amount) public pure returns (uint) { return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return amount / 1e18; }


}