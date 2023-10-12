// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity >=0.8.0 < 0.9.0;

// WARNING: TESTING IN PRODUCTION -- DO NOT DUPLICATE //
contract Rewarder is Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    
    IERC20 public RewardToken;

    struct UserInfo {
        uint postCount;
        uint claimed;
        string email;
    }

    constructor(address _rewardToken) Ownable(msg.sender) {
        RewardToken = IERC20(_rewardToken);
    }

    // maps: an address to UserInfo.
    mapping(address => UserInfo) public userInfo;
    // maps: email to an address.
    mapping (string => address) public userAddress;
    
    // counters
    uint public totalEmails;
    uint public totalVerified;
    uint public totalUnclaimed;

    // lists: emails
    string[] public emails;

    // note: must be registered to claim rewards.
    mapping(string => bool) public isRegistered;

    // broadcasts: registration.
    event Registered(address user, string email, uint timeStamp);

    // broadcasts: claim.
    event Claimed(address user, uint amount, uint timeStamp);

    //////////////////////////////
        /*/ USER FUNCTIONS /*/    
    //////////////////////////////

    // claims: pending rewards associated with msg.sender.
    function claim() external whenNotPaused nonReentrant {
        // gets: userInfo[msg.sender].
        UserInfo storage user = userInfo[msg.sender];
        require(user.postCount >= user.claimed, "no rewards to claim");
        
        // checks: email is verified.
        string memory email = user.email;
        require(isRegistered[email], 'email not verified');

        // gets: claimable as postCount - claimed.
        uint claimable = user.postCount - user.claimed;
        
        // updates: claimed.
        user.claimed = user.claimed + claimable;

        // updates: totalUnclaimed by removing claimable amount.
        totalUnclaimed -= claimable;
        
        // sends: claimable to msg.sender.
        RewardToken.safeTransfer(msg.sender, claimable);

        // emits: claim event.
        emit Claimed(msg.sender, claimable, block.timestamp);
    }

    //////////////////////////////
        /*/ VIEW FUNCTIONS /*/    
    //////////////////////////////

    // gets: claimable amount from post - claimed.
    function getClaimable(address account) public view returns (uint claimable) {
        // gets: userInfo.
        UserInfo storage user = userInfo[account];
        // sets: claimable to postCount - claimed.
        claimable =
            user.postCount == user.claimed ? 0
            : user.postCount - user.claimed;
    }
    
    // gets: postCount for a given email.
    function getPostCount(string memory email) public view returns (uint postCount) {
        // checks: email address is registered.
        require(isRegistered[email], 'email not registered');
        // gets: account for a given email.
        address account = userAddress[email];

        // gets: userInfo.
        UserInfo storage user = userInfo[account];
        
        // returns: postCount for given user.
        postCount = user.postCount;
    }

    // gets: address associated with a given email.
    function getAddress(string memory email) external view returns (address) {
       return userAddress[email];
    }

    //////////////////////////////
      /*/ INTERNAL FUNCTIONS /*/  
    //////////////////////////////
    
    function _register(string memory _email) internal returns (bool) {
        uint length = emails.length;
    
        // checks: email is unique.
        for (uint i = 0; i < length; ++i) {
           require(
                // gets emails[i] and compares to _email.
                keccak256(abi.encodePacked(emails[i])) 
                != keccak256(abi.encodePacked(_email)),
                'email already registered'
            );
        }

        // registers: email.
        isRegistered[_email] = true;

        // updates: emails list.
        emails.push(_email);

        // increments: total number of emails.
        totalEmails++;

        return true;
    }

    ///////////////////////////////
        /*/ ADMIN FUNCTIONS /*/    
    ///////////////////////////////

    // toggles: contract pause state.
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    // sets: post count associated with a given user.
    function setPostCount(string memory email, uint posts) external onlyOwner {
        // note: assumes 18 decimals.
        uint postCount = posts * 1E18;

        // gets: userInfo[userAddress].
        UserInfo storage user = userInfo[userAddress[email]];

        // checks: update required.
        require(user.postCount < postCount, 'no update required');

        // gets: delta as posts - postCount.
        uint delta = postCount - user.postCount;

        // sets: postCount.
        user.postCount = postCount;

        // adds: delta to totalUnclaimed
        totalUnclaimed += delta;
    }

    // assigns: email to msg.sender.
    function registerUser(address account, string memory email) external onlyOwner {
        require(!isRegistered[email], 'email already registered');
        
        // gets: userInfo[msg.sender].
        UserInfo storage user = userInfo[account];

        require(_register(email), 'failed to register email');
        
        // sets: email associated with address.
        user.email = email;
    
        // maps: email to account.
        userAddress[email] = account;

        // emits: registration event.
        emit Registered(account, email, block.timestamp);
    }

    function allocateRewards() external onlyOwner {
        uint rewardBalance = RewardToken.balanceOf(address(this));

        // checks: there is a need for allocation
        require(totalUnclaimed <= rewardBalance, 'no allocation needed');

        // gets: amount toAllocate
        uint toAllocate = totalUnclaimed - rewardBalance;

        // transfers: rewards to contract.
        RewardToken.safeTransferFrom(msg.sender, address(this), toAllocate);
    }

}