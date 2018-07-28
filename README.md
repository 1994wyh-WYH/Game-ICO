# Game-ICO

## Contract is now tested on Ethereum `Ropsten` and `Kovan` Testnet. 

### Ropsten: 0xdeed2d0acdf37672a073cb7c8cf3a5fcd55d5619
### //Kovan: 0x186d8f9a230967ac1060977b89aec94cc7c4ba6c
### mainnet: 0x62f136cf732c66cccfcdce201213eed26399ae5c

## Testing Steps 

1. Send ethers to the contract address. You'll be registered for the game once transaction is confirmed and the front end calls another function -- `dealWithPay()`. For now, we need to assume the UI deals with the emitted data correctly and successfully calls `dealWithPay()`.

2. Since we don't have a UI yet, we need to do the assumed work ourselves. Call `dealWithPay()` with two parameter: your account address and the amount of ethers you sent to the contract (the amount you typed in or intended, not including tx fee). The amount needs to be recalculated in `wei`, which is the smallest unit of 'money' on Ethereum blockchains. 1 ether = 10^18 `wei`, for example if you sent 0.01 ether, it is 10^16 = 10000000000000000 in `wei`. Make sure you type all the zeros instead of '10^16' !!

3. Call and structures which store all the data/status of the rounds and players to check if those are consistent with your caculation.
