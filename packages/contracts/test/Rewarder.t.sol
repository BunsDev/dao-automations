// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./Setup.t.sol";

contract RewarderTest is Test, Setup {

    function getAddress() public view returns (address rewarderAddress) {
        return REWARDER_ADDRESS;
    }

    function registerEmail() public returns (bool) {
        // imitates: owner
        vm.prank(address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496));

        // registers: email
        RewarderContract.registerUser(USER_ADDRESS, EMAIL_ADDRESS_ONE);

        return RewarderContract.isRegistered(EMAIL_ADDRESS_ONE);
    }

    // tests: email registration.
    function test_register() public {
        // triggers: email registration
        require(registerEmail(), 'failed to register email');
    
        // checks: registered and unverified.
        assertTrue(RewarderContract.isRegistered(EMAIL_ADDRESS_ONE));
        console.log("[success]: email registered");
    }
    
    function test_totalEmails() public {
        // triggers: email registration
        require(registerEmail(), 'failed to register email');

        // checks: total emails.
        assertTrue(RewarderContract.totalEmails() == 1);
        console.log("[success]: totalEmails");
    }
}