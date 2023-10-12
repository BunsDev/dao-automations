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
    string[] public unverifiedEmails;
    string[] public verifiedEmails;

    // note: must be registered to verify.
    mapping(string => bool) public isVerified;
    // note: must be registered to claim rewards.
    mapping(string => bool) public isRegistered;

    // broadcasts: registration.
    event Registered(address user, string email, uint timeStamp);

    // broadcasts: claim.
    event Claimed(address user, uint amount, uint timeStamp);

    // broadcasts: verification.
    event Verified(address user, string email, uint timeStamp);

    //////////////////////////////
        /*/ USER FUNCTIONS /*/    
    //////////////////////////////

    // assigns: email to msg.sender.
    function register(string memory email) external whenNotPaused {
        require(!isRegistered[email], 'email already registered');
        
        // gets: userInfo[msg.sender].
        UserInfo storage user = userInfo[msg.sender];

        require(_register(email), 'failed to register email');
        
        // sets: email associated with address.
        user.email = email;
    
        // maps: email to msg.sender.
        userAddress[email] = msg.sender;

        // emits: registration event.
        emit Registered(msg.sender, email, block.timestamp);

    }

    // claims: pending rewards associated with msg.sender.
    function claim() external whenNotPaused nonReentrant {
        // gets: userInfo[msg.sender].
        UserInfo storage user = userInfo[msg.sender];
        require(user.postCount >= user.claimed, "no rewards to claim");
        
        // checks: email is verified.
        string memory email = user.email;
        require(isVerified[email], 'email not verified');

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

        // updates: pending (unverifiedEmails) emails list.
        require(updatePending(), 'unable to update pending');

        return true;
    }

    // sets: unverifiedEmails
    function updatePending() internal returns (bool) {
        // resets: unverifiedEmails.
        unverifiedEmails = new string[](0);

        // iterates: emails and checks for unverifiedEmails addresses.
        for (uint i = 0; i < totalEmails; ++i) {
           if (!isVerified[emails[i]]) {
               unverifiedEmails.push(emails[i]);
           }
        }

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
        // gets: userInfo[userAddress].
        UserInfo storage user = userInfo[userAddress[email]];

        // checks: update required.
        require(user.postCount < posts, 'no update required');

        // gets: delta as posts - postCount.
        uint delta = posts - user.postCount;

        // sets: postCount.
        user.postCount = posts;

        // adds: delta to totalUnclaimed
        totalUnclaimed += delta;
    }

    // note: not trustless.
    function verifyEmail(string memory email) external onlyOwner {
        require(isRegistered[email], 'email not registered');
        require(!isVerified[email], 'email already verified');
 
        // verifies: email.
        isVerified[email] = true;
        verifiedEmails.push(email);

        // gets: account associated with email.
        address account = userAddress[email];

        // emits: verification event.
        emit Verified(account, email, block.timestamp);
    }

    // registers: email.
    function registerEmail(string memory email) external onlyOwner {
        require(!isRegistered[email], 'email already registered');
        isRegistered[email] = true;
    }
   
    // updates: email for a given user.
    function updateEmail(string memory email, address account) external onlyOwner {

        // registers: unregistered email.
        if(!isRegistered[email]) {
            _register(email);
        }

        // gets: userInfo.
        UserInfo storage user = userInfo[account];

        // sets: email associated with address.
        user.email = email;
    }

    // gets: list of unverified emails.
    function updateUnverified() external onlyOwner returns (string[] memory _unverifiedEmails) {
        // resets: unverifiedEmails.
        unverifiedEmails = new string[](0);
        
        // iterates: emails and checks for unverifiedEmails addresses.
        for (uint i = 0; i < totalEmails; ++i) {
           if (!isVerified[emails[i]]) {
               unverifiedEmails.push(emails[i]);
           }
        }

        // returns: unverified emails.
        _unverifiedEmails = unverifiedEmails;
    }

}