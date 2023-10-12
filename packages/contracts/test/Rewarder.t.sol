// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./Setup.t.sol";

contract RewarderTest is Test, Setup {

    function getAddress() public view returns (address rewarderAddress) {
        return REWARDER_ADDRESS;
    }

    // test: register email
    function test_registerEmail() public {
        // imitates: user
        vm.startPrank(USER_ADDRESS);

        // registers: email
        RewarderContract.registerEmail(EMAIL_ADDRESS_ONE);

        // checks: registered and unverified.
        assertTrue(RewarderContract.registeredEmails(EMAIL_ADDRESS_ONE));
        console.log("[success]: email registered");

        assertTrue(RewarderContract.unverifiedEmails(EMAIL_ADDRESS_ONE));
        console.log("[success]: email unverified");

        assertTrue(RewarderContract.verifiedEmails(EMAIL_ADDRESS_ONE) == false);
        console.log("[success]: email NOT verified");
    }

    function test_verifyEmail() public {
        // imitates: owner
        vm.startPrank(RewarderContract.owner());

        // verifies: email
        RewarderContract.verifyEmail(EMAIL_ADDRESS_ONE);

        vm.stopPrank();

        // checks: registered and verified.
        assertTrue(RewarderContract.registeredEmails(EMAIL_ADDRESS_ONE));
        console.log("[success]: email registered");

        assertTrue(RewarderContract.unverifiedEmails(EMAIL_ADDRESS_ONE) == false);
        console.log("[success]: email NOT unverified");

        assertTrue(RewarderContract.verifiedEmails(EMAIL_ADDRESS_ONE));
        console.log("[success]: email verified");
        }
}