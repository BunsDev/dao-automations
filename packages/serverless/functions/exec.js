const axios = require('axios')
const ethers = require('ethers')
const { abis, addresses } = require('../constants')

exports.handler = async function() {
  console.log('Starting...');

  // Gets: API Data from Discourse Forum
  const BASE_API_URL = "https://forum.soulswap.finance"
  // posts: posts.json
  // user list: /directory_items.json?period=weekly&order=post_count
  // users (active): /admin/users/list/active.json?order=posts&asc=true&show_emails=true
  // users (new): /admin/users/list/new.json?order=posts&asc=true
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

  // Gets: Users from API Data
  let users = []
  for (let i = 0; i < json.length; i++) {
    // ignores: inactive users (below threshold)
    // note: email is used since it isn't a public field, which allows us to use it as a value from the contract.
    // note: make this trustless with a threshold variable from the smart contract.
    if(json[i].post_count == 0) continue
    users.push(` ${json[i].email}: ${json[i].post_count}`)
  }

  // console.log(json)
  // console.log(users)
  // console.log(response)

  // Initializes: Wallet
  // const chainId = '250'
  // const provider =
  //   new ethers.providers.JsonRpcProvider('https://rpc.ftm.tools', parseInt(chainId))
  // let wallet = ethers.Wallet.fromMnemonic(process.env.MNEMONIC)
  // wallet = wallet.connect(provider)
  // console.log('Wallet connected');

  // Loads: Contract
  // const Rewarder = new ethers.Contract(
  //   RewarderAddress,
  //   RewarderABI,
  //   wallet,
  // )
  // console.log('Contract loaded');

  // console.log('Sending transaction...');
  try {
    // Specify custom tx overrides, such as gas price https://docs.ethers.io/ethers.js/v5-beta/api-contract.html#overrides
    // const overrides = { gasPrice: process.env.DEFAULT_GAS_PRICE };
    // const overrides = { gasPrice: 100_000_000_000 }; // 100 Gwei

    // Sends: Transaction (if pending)
    // const getPending = await Rewarder.available()
    // console.log('Pending amount', Number(getPending))
    // const tx = await Rewarder.allocate(overrides)
    // const explorer = 'https://ftmscan.com'
    // const successMessage = `:white_check_mark: Transaction sent ${explorer}/tx/${tx.hash}`;
    const successMessage = `${users}`;
    console.log(successMessage)
    await postToSlack(successMessage);
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