# Game-ICO

## Contract is now tested on Ethereum Ropsten Testnet. Address: 0xa92b5457a4baf5c110bae649d3480cb5d2538b2c

## Testing Steps 

1. Send ethers to the contract address. You'll be registered for the game once transaction is confirmed and the front end calls another function -- dealWithPay(). For now, we need to assume the UI deals with the emitted data correctly and successfully calls dealWithPay().

2. Since we don't have a UI yet, we need to do the assumed work ourselves. Call dealWithPay() with two parameter: your account address and the amount of ethers you sent to the contract (the amount you typed in or intended, not including tx fee). The amount needs to be recalculated in wei, which is the smallest unit of 'money' on Ethereum blockchains. 1 ether = 10^18 wei, for example if you sent 0.01 ether, it is 10^16 = 10000000000000000 in wei. Make sure you type all the zeros instead of '10^16' !!

3. Call and structures which store all the data/status of the rounds and players to check if those are consistent with your caculation.
