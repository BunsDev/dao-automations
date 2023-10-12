const axios = require('axios')
const ethers = require('ethers')
const { abis, addresses } = require('../constants')

exports.handler = async function() {
  console.log('Starting...');

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

  // Gets: Users from API Data
  let activeUsers = []
  let activeEmails = []
  let totalActiveUsers = 0

  for (let i = 0; i < json.length; i++) {
    // ignores: inactive users (below threshold)
    // note: email is used since it isn't a public field, which allows us to use it as a value from the contract.
    // note: make this trustless with a threshold variable from the smart contract.
    if(json[i].post_count == 0) continue
    activeUsers.push(` ${json[i].email}: ${json[i].post_count}`)
    activeEmails.push(json[i].email)
    totalActiveUsers ++
  }

  // console.log(users)

  // initializes: wallet
  const chainId = '250'
  const provider =
    new ethers.providers.JsonRpcProvider('https://rpc.ftm.tools', parseInt(chainId))
  let wallet = ethers.Wallet.fromMnemonic(process.env.MNEMONIC)
  wallet = wallet.connect(provider)
  console.log('[.√.] wallet connected');

  const RewarderAddress = addresses.Rewarder;
  const RewarderABI = abis.Rewarder;

  // Loads: Contract
  const Rewarder = new ethers.Contract(
    RewarderAddress,
    RewarderABI,
    wallet,
  )
  console.log('[.√.] contract loaded');

  try {
    // Specify custom tx overrides, such as gas price https://docs.ethers.io/ethers.js/v5-beta/api-contract.html#overrides
    const overrides = { gasPrice: process.env.DEFAULT_GAS_PRICE }; // 100 Gwei

    // Sends: Transaction (if pending)
    console.log('[..] searching for unverified emails.');

    const totalEmails = await Rewarder.totalEmails(overrides)
    const totalVerified = await Rewarder.totalVerified(overrides)
    const totalUnverified = Number(totalEmails) - Number(totalVerified)
    console.log(`[.√.] ${totalUnverified} unverified ${totalUnverified == 1 ? 'email' : 'emails'} found.`)

    // creates: list of unverified emails (from contract).
    let unverifiedEmails = []
    for (i=0; i < totalUnverified; i++) {
      const email = await Rewarder.unverifiedEmails(i, overrides)
      unverifiedEmails.push(email)
    }

    const post_users = `${activeUsers}`
    
    // generates: unverifiedUsers post.
    const post_unverifiedEmails = totalUnverified > 0 
      ? `Unverified [${totalUnverified.toString()}]: ${unverifiedEmails}`
      : `:white_check_mark: All emails are verified.`
    // console.log(post_unverifiedEmails)

    // generates: activeUsers post.
    const post_activeUsers = `Active [${totalActiveUsers.toString()}]:${post_users}`
    // console.log(post_activeUsers)

    // posts: unverifiedUsers to Slack.
    await postToSlack(post_unverifiedEmails)
    console.log('[.√.] posted unverifiedEmails to Slack')
    
    // posts: activeUsers to Slack.
    await postToSlack(post_activeUsers);
    console.log('[.√.] posted userList to Slack')

    // finds: activeUsers that are unverified.
    let qualifiedUsers = []
    // seaches all activeUsers and returns if unverifiedUser is a match.
    for (i=0; i < totalActiveUsers; i++) {
      // iterates: through each unverifiedEmail.
      let email = unverifiedEmails[i]
        // checks: each unverifiedEmail for all activeUser.
        for (j=0; j < totalActiveUsers; j++) {
          let eligibleEmail = activeEmails[j]
            // checks: if unverifiedEmail matches with activeEmail.
            if (email == eligibleEmail) {
              qualifiedUsers.push(email)
            }
        }
    }

    // generates: qualifiedUsers post.
    const post_qualifiedUsers = `Qualified [${qualifiedUsers.length}]: ${qualifiedUsers}`
    // console.log(post_qualifiedUsers)

    // posts: qualified to Slack.
    await postToSlack(post_qualifiedUsers);
    console.log('[√] posted qualifiedUsers to Slack')

    // todo: find emails that need allocation.
    // let unallocatedUsers = []

    // const tx = await Rewarder.allocate(overrides)
    // const explorer = 'https://ftmscan.com'
    // const successMessage = `:white_check_mark: Transaction sent ${explorer}/tx/${tx.hash}`;
    // console.log(successMessage)
  
  } catch (err) {
    const errorMessage = `:warning: Transaction failed: ${err.message}`;
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