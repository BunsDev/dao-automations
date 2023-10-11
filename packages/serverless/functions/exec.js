const axios = require('axios')
const ethers = require('ethers')
const { abis, addresses } = require('../constants')

exports.handler = async function() {
  console.log('Starting...');
  // Loads: ABIs
  const RewarderABI = abis.Rewarder;
  const RewarderAddress = addresses.Rewarder;
  console.log('Contract ABIs loaded');

  // Initializes: Wallet
  const chainId = '250'
  const provider =
    new ethers.providers.JsonRpcProvider('https://rpc.ftm.tools', parseInt(chainId))
  let wallet = ethers.Wallet.fromMnemonic(process.env.MNEMONIC)
  wallet = wallet.connect(provider)
  console.log('Wallet connected');

  // Loads: Contract
  const Rewarder = new ethers.Contract(
    RewarderAddress,
    RewarderABI,
    wallet,
  )
  console.log('Contract loaded');

  console.log('Sending transaction...');
  try {
    // Specify custom tx overrides, such as gas price https://docs.ethers.io/ethers.js/v5-beta/api-contract.html#overrides
    // const overrides = { gasPrice: process.env.DEFAULT_GAS_PRICE };
    const overrides = { gasPrice: 100_000_000_000 }; // 100 Gwei

    // Sends: Transaction (if pending)
    const getPending = await Rewarder.available()
    console.log('Pending amount', Number(getPending))
    const tx = await Rewarder.allocate(overrides)
    const explorer = 'https://ftmscan.com'
    const successMessage = `:white_check_mark: Transaction sent ${explorer}/tx/${tx.hash}`;
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