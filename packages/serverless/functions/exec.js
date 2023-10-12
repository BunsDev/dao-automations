const axios = require('axios')
const ethers = require('ethers')
const { abis, addresses } = require('../constants')

exports.handler = async function() {
  console.log('starting...');

  // Gets: API Data from Discourse Forum
  const BASE_API_URL = "https://forum.soulswap.finance"
  // posts: posts.json
  // user list: /directory_items.json?period=weekly&order=post_count
  // users (new): /admin/users/list/new.json?order=posts&asc=false&show_emails=true
  // groups: /groups/trust_level_0/members.json?limit=50&offset=50
  const res = await fetch(`${BASE_API_URL}/admin/users/list/new.json?order=posts&asc=false&show_emails=true`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'Referrer-Policy': 'no-referrer',
      'Api-Key': process.env.FORUM_KEY,
      'Api-Username': 'system'
    },
  })
  const json = await res.json()
  // console.log(json)

  // gets: Users from API Data
  let activeUsers = []
  let activeEmails = []
  let activePosts = []
  let totalActiveUsers = 0

  for (let i = 0; i < json.length; i++) {
    // ignores: inactive users (below threshold)
    if(json[i].post_count == 0) continue
      activeUsers.push(` ${json[i].email}: ${json[i].post_count}`)
      activeEmails.push(json[i].email)
      activePosts.push(json[i].post_count)
      totalActiveUsers ++
  }

  // console.log(activeUsers)

  // initializes: wallet
  const chainId = '250'
  const provider =
    new ethers.providers.JsonRpcProvider('https://rpc.ftm.tools', parseInt(chainId))
  let wallet = ethers.Wallet.fromMnemonic(process.env.MNEMONIC)
  wallet = wallet.connect(provider)
  console.log('[.√.] wallet connected')

  const RewarderAddress = addresses.Rewarder
  const RewarderABI = abis.Rewarder
  
  const RewardAddress = addresses.RewardToken
  const RewardABI = abis.RewardToken

  // loads: contracts
  const Rewarder = new ethers.Contract(
    RewarderAddress,
    RewarderABI,
    wallet,
  )
  console.log('[.√.] rewarder loaded');
  
  const RewardToken = new ethers.Contract(
    RewardAddress,
    RewardABI,
    wallet,
  )
  console.log('[.√.] reward loaded');

  try {
    // Specify custom tx overrides, such as gas price https://docs.ethers.io/ethers.js/v5-beta/api-contract.html#overrides
    const overrides = { gasPrice: process.env.DEFAULT_GAS_PRICE }; // 100 Gwei
    const explorer = 'https://ftmscan.com'

    // Sends: Transaction (if pending)
    
    console.log('[...] searching for registered emails.');
    const totalRegisteredEmails = await Rewarder.totalEmails(overrides)
    let registeredEmails = []
    for (i=0; i < totalRegisteredEmails; i++) {
      let registeredEmail = await Rewarder.emails(i, overrides)
      registeredEmails.push(registeredEmail)
    }

    const post_users = `${activeUsers}`
    // generates: registeredEmails post.
    const post_registeredEmails = `Registered [${totalRegisteredEmails.toString()}]: ${registeredEmails}`
    console.log(post_registeredEmails)
    
    // posts: registeredEmails to Slack.
    await postToSlack(post_registeredEmails)
    console.log('[.√.] posted registeredEmails to Slack')

    // generates: activeUsers post.
    const post_activeUsers = `Active [${totalActiveUsers.toString()}]:${post_users}`
    // console.log(post_activeUsers)
    
    // posts: activeUsers to Slack.
    await postToSlack(post_activeUsers)
    console.log('[.√.] posted userList to Slack')

    // finds: activeUsers that are registered.
    let qualifiedEmails = []
    let qualifiedPosts = []
    let qualifiedWallets = []
    let totalQualifiedUsers = 0

    // searches: activeUsers and returns if registeredEmail is a match.
    for (i=0; i < totalActiveUsers; i++) {
      // iterates: through each registeredEmail.
      let email = registeredEmails[i]
      // checks: each registeredEmail for all activeUser.
      for (j=0; j < totalActiveUsers; j++) {
        // checks: if registeredEmail matches with activeEmail.
        if (email == activeEmails[j]) {
              // gets: postCount for each eligibleEmail.
              let postCount = activePosts[j]
              // gets: walletAddress for each eligibleEmail.
              let walletAddress  = await Rewarder.getAddress(email, overrides)
              
              // updates: qualified lists.
              qualifiedEmails.push(email)
              qualifiedPosts.push(postCount)
              qualifiedWallets.push(walletAddress)
              
              totalQualifiedUsers ++
            }
        }
    }

    // posts: qualified to Slack.
    const post_qualifiedEmails = `Qualified [${totalQualifiedUsers.toString()}]: ${qualifiedEmails}`
    await postToSlack(post_qualifiedEmails);
    console.log('[.√.] posted qualifiedEmails to Slack')

    // updates: post count for each qualified (if needed).
    for (i=0; i<totalQualifiedUsers; i++) {
      // gets: stored postCount for each qualifiedUser.
      let _postCount_contract = await Rewarder.getPostCount(qualifiedEmails[i], overrides) 
      let postCount_contract = _postCount_contract / 1e18
      let postCount_api = qualifiedPosts[i]
      console.log(`postCount(api) [${i}]: ${postCount_api}`)
      console.log(`postCount(contract) [${i}]: ${postCount_contract}`)

      let toAllocate = Number(postCount_api) - Number(postCount_contract)
      
      if (toAllocate > 0) {
        // updates: postCount for each qualifiedUser.
        const updateCountTx = await Rewarder.setPostCount(qualifiedEmails[i], toAllocate, overrides)
        await updateCountTx.wait()

        // console.log('toAllocate:', toAllocate)
        const post_updateConfirmation = `[.√.] updated post count for ${qualifiedEmails[i]} to ${toAllocate}: ${explorer}/tx/${updateCountTx.hash}`
        postToSlack(post_updateConfirmation)
        console.log(post_updateConfirmation)
      }
    }

      // checks: if rewarder has enough funds to claim rewards.
      const rewardBalance = await RewardToken.balanceOf(RewarderAddress, overrides)
      const totalUnclaimed = await Rewarder.totalUnclaimed(overrides)    
      const refillNeeded = Number(totalUnclaimed) <= Number(rewardBalance) ? 0 : Number(totalUnclaimed) - Number(rewardBalance)
      console.log('refillNeeded: %s', (refillNeeded / 1e18).toString())

      // refills: if there is a need.
      if (refillNeeded > 0) {
        // sends: refill to rewarder address to ensure rewards are claimable.
        const allocationTx = await RewardToken.transfer(RewarderAddress, (refillNeeded).toString(), overrides)
        await allocationTx.wait()
  
        const post_allocationConfirmation = `[.√.] transferred ${refillNeeded / 1e18} tokens to rewarder: ${explorer}/tx/${allocationTx.hash}`
        postToSlack(post_allocationConfirmation)
        console.log(post_allocationConfirmation)
      }
    
    
  } catch (err) {
    const errorMessage = `:warning: transaction failed: ${err.message}`;
    console.error(errorMessage)
    await postToSlack(errorMessage);
    return err;
  }

  console.log('Completed');
  return true;
}

// Sends: Success Message to Slack
function postToSlack(text) {
  const payload = JSON.stringify({ 
    text,
  });
  return axios.post(process.env.SLACK_HOOK_URL, payload)
}