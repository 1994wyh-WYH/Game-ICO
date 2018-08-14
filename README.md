# Game-ICO

## Contract is now tested on Ethereum `Ropsten` Testnet. 

### Ropsten: 0x67ce505fd4ee8a5810d1971a280b5ba3dc4aa6a6

## Testing Steps 

1. Send ethers to the contract address. You'll be registered for the game automatically once transaction is confirmed and another functions to deal with payment will be triggered. 

2. Now you can assume the process is done once the tx is confirmed. Call and structures which store all the data/status of the Rounds, PlayerRounds and Players to check if those are consistent with your tx. 

3. To withdraw your current balance plus this round dividends, you can either call the `withdrawDividends()` function or send ethers with "1" as the tx data. 
For the first approach, I suggest Remix IDE as a web3 UI. Check it here http://remix.ethereum.org using Chrome.
First, download or copy the Game.sol file in this repo and paste it in Remix as a new file. 
Second, make sure you have MetaMask installed and connected to Ropsten.

Then, on the right side, compile it by hitting `compile` and hit `run` section. Select `injected Web3` as the environment, make sure the account below is your default account, and then select the to-de-deployed contract as 'Game'. Copy and paste the contract address above and hit `At Address`.

Wait until the tx is confirmed. Now you can interact with the already deployed contract.

Pass the round ID in `withdrawDividends()` and hit it. Then you'll need to sign the tx. 

Now, wait until your tx succeeded.

4. To claim your current balance including this round B rewards after the round ends, you can either call the `claimRewards()` function or send ethers with "2" as the tx data. 

5. To credit your referrer, pass his/her address in the tx data field when sending eth to the contract.
