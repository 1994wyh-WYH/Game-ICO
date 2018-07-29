# Game-ICO

## Contract is now tested on Ethereum `Ropsten` and `Kovan` Testnet. 

### Ropsten: 0xdeed2d0acdf37672a073cb7c8cf3a5fcd55d5619
//Kovan: 0x186d8f9a230967ac1060977b89aec94cc7c4ba6c
### mainnet: 0x62f136cf732c66cccfcdce201213eed26399ae5c

## Testing Steps 

1. Send ethers to the contract address. You'll be registered for the game automatically once transaction is confirmed and another function -- `dealWithPay()` is triggered. 

2. Now you can assume the process is done once the tx is confirmed. Call and structures which store all the data/status of the Rounds, PlayerRounds and Players to check if those are consistent with your tx. 

3. To withdraw your current balance, you'll need to call the `withdrawDividends()` function with the current round ID (1, for now). I suggest Remix IDE as a web3 UI. Check it here http://remix.ethereum.org using Chrome.

First, download or copy the Game.sol file in this repo and paste it in Remix as a new file. 

Second, make sure you have MetaMask installed and connected to Ropsten.

Then, on the right side, compile it by hitting `compile` and hit `run` section. Select `injected Web3` as the environment, make sure the account below is your default account, and then select the to-de-deployed contract as 'Game'. Copy and paste the contract address above (0xdeed2d0acdf37672a073cb7c8cf3a5fcd55d5619) and hit `At Address`.

Wait until the tx is confirmed. Now you can interact with the already deployed contract.

Pass the round ID in `withdrawDividends()` and hit it. Then you'll need to sign the tx. 

Now, wait until your tx succeeded.


