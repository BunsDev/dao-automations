// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./Setup.t.sol";

contract RewarderTest is Test, Setup {

    function getAddress() public view returns (address rewarderAddress) {
        return REWARDER_ADDRESS;
    }

    function registerEmail() public returns (bool) {
        // imitates: user
        vm.prank(USER_ADDRESS);

        // registers: email
        RewarderContract.register(EMAIL_ADDRESS_ONE);

        return RewarderContract.registeredEmails(EMAIL_ADDRESS_ONE);
    }

    function verifyEmail() public returns (bool) {
        // imitates: owner
        vm.prank(address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496));

        // verifies: email
        RewarderContract.verifyEmail(EMAIL_ADDRESS_ONE);

        return RewarderContract.registeredEmails(EMAIL_ADDRESS_ONE);
    }

    // tests: email registration.
    function test_registerEmail() public {
        // triggers: email registration
        require(registerEmail(), 'failed to register email');
    
        // checks: registered and unverified.
        assertTrue(RewarderContract.registeredEmails(EMAIL_ADDRESS_ONE));
        console.log("[success]: email registered");

        assertTrue(RewarderContract.unverifiedEmails(EMAIL_ADDRESS_ONE));
        console.log("[success]: email unverified");

        assertTrue(RewarderContract.verifiedEmails(EMAIL_ADDRESS_ONE) == false);
        console.log("[success]: email NOT verified");

    }

    // tests: email verification.
    function test_verifyEmail() public {
        // triggers: email registration
        require(registerEmail(), 'failed to register email');

        // triggers: email verification
        require(verifyEmail(), 'failed to verify email');

        // checks: registered and verified.
        assertTrue(RewarderContract.registeredEmails(EMAIL_ADDRESS_ONE));
        console.log("[success]: email registered");

        assertTrue(RewarderContract.unverifiedEmails(EMAIL_ADDRESS_ONE) == false);
        console.log("[success]: email NOT unverified");

        assertTrue(RewarderContract.verifiedEmails(EMAIL_ADDRESS_ONE));
        console.log("[success]: email verified");
    }

    // tests: unverified emails.
    function test_unverifiedEmails() public {
        // verify: unverified //
        // triggers: email registration
        require(registerEmail(), 'failed to register email');
        assertTrue(RewarderContract.unverifiedEmails(EMAIL_ADDRESS_ONE));
        console.log("[success]: email unverified");

        // falsify: unverified //
        // triggers: email registration
        require(verifyEmail(), 'failed to verify email');
        assertTrue(RewarderContract.unverifiedEmails(EMAIL_ADDRESS_ONE) == false);
        console.log("[success]: email NOT unverified");

    }
}