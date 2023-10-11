// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentracyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

pragma solidity =0.8.19;

contract Rewarder is Pausable, ReentrancyGuard, Ownable2Step {
    using SafeERC20 for IERC20;
    
    IERC20 public RewardToken;

    struct UserInfo {
        uint postCount;
        uint claimed;
        string email;
    }

    constructor(address _rewardToken) {
        RewardToken = IERC20(_rewardToken);
    }

    // maps: an address to UserInfo.
    mapping(address => UserInfo) public userInfo;
    // maps: email to an address.
    mapping (string => address) public userAddress;

    // note: must be registered to verify.
    mapping(string => bool) public verifiedEmails;
    // note: must be registered to claim rewards.
    mapping(string => bool) public registeredEmails;

    // assigns: email to msg.sender.
    function register(string memory email) external {
        require(!registeredEmails[email], 'email already registered');
        
        // gets: userInfo[msg.sender].
        UserInfo storage user = userInfo[msg.sender];
        // registers: email.
        registeredEmails[email] = true;
        // sets: email associated with address.
        user.email = email;
        // maps: email to msg.sender for emailAddress.
        emailAddress[msg.sender] = email;
    }

    // claims: pending rewards associated with msg.sender.
    function claim() external whenNotPaused nonReentrant{
        // gets: userInfo[msg.sender].
        UserInfo storage user = userInfo[msg.sender];
        require(user.postCount >= user.claimed, "no rewards to claim");
        
        // checks: email is verified.
        string memory email = user.email;
        require(verifiedEmails[email], 'email not verified');
        
        // gets: claimable as postCount - claimed.
        uint claimable = user.postCount - user.claimed;
        
        // updates: claimed.
        user.claimed = user.claimed + claimable;
        
        // sends: claimable to msg.sender.
        RewardToken.safeTransfer(msg.sender, claimable);
    }

    // GETTER FUNCTIONS //

    function getClaimable(address userAddress) public view returns (uint claimable) {
        // gets: userInfo.
        UserInfo storage user = userInfo[userAddress];
        // sets: claimable to postCount - claimed.
        claimable =
            user.postCount = user.claimed ? 0
            : user.postCount - user.claimed;
    }

    function getAddress(string email) external view returns (address) {
       return userAddress[email];
    }

    // INTERNAL FUNCTIONS //

    // checks: email uniqueness (internal view)
    // function checkDuplicate(string email) internal view {
    //     uint length = userInfo.length;

    //     for (uint i = 0; i < length; ++i) {
    //         require(userInfo[i].email != email, 'duplicate email');
    //     }
    // }

    // ADMIN FUNCTIONS //
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPostCount(uint email, uint posts) external onlyOwner {
        // gets: userInfo[userAddress].
        UserInfo storage user = userInfo[userAddress[email]];

        // checks: update required.
        require(user.postCount < posts, 'no update required');

        // sets: postCount.
        user.postCount = posts;
    }

    // note: not trustless.
    function verifyEmail(string email) external onlyOwner {
        require(registeredEmails[email], 'email not registered');
        require(!verifiedEmails[email], 'email already verified');
 
        // verifies: email.
        verifiedEmails[email] = true;
    }

    // note: not trustless.
    function registerEmail(string email) external onlyOwner {
        require(!registeredEmails[email], 'email already registered');
        registeredEmails[email] = true;
    }
   
    // note: not trustless.
    function updateEmail(string email, address userAddress) external onlyOwner {
        require(registeredEmails[email], 'email not registered');
        // gets: userInfo.
        UserInfo storage user = userInfo[userAddress];
        // sets: email associated with address.
        user.email = email;
    }
}