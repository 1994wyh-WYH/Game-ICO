pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks and PREVENTS throws
 * Inspired by https://github.com/OpenZeppelin/openzeppelin-solidity
 * Modified by author
 */
library SafeMath {
    
    /**
      * @dev Subtracts two numbers, NO throws on overflow. 
      * If subtrahend is greater than intended, just return 0.
      */
      function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        if(b >= a) return 0;
        return a - b;
      }
    
      /**
      * @dev Adds two numbers, NO throws on overflow.
      * Return the greater one if overflows.
      */
      function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        if (c <= a) {
            if(a > b) {
                return a;
            }
            else{
                return b;
            }
        }
        return c;
      }
      
      
      /**
      * @dev Multiplies two numbers, NO throws on overflow.
      * Return the greater one if overflow.
      */
      function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        if (a == 0) {
          return 0;
        }
    
        c = a * b;
        if(c / a != b) {
            if(a > b) {
                return a;
            }
            else{
                return b;
            }
        }
        return c;
      }
    
      /**
      * @dev Integer division of two numbers, truncating the quotient.
      * Returns the first value if requirement doesn't hold.
      */
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        if(c > a){
            return 1;
        }
        return c;
      }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


//////////////////////////////////////////////////////////////
///////////////   starts here ! //////////////////////////////
/////////////////////////////////////////////////////////////
/**
 * @author whatever you hear 
 */
 
contract Game is Ownable {
    using SafeMath for *;
    
    //NOTE: 100 key units = 1 actual key for purchase
    // 0.18% up per new actual key => 0.0018% per key uint
    uint256 public initAKeyPrice = 100000000000000; 
    // 0.18% down per new actual key => 0.0018% per key uint
    uint256 public initBKeyPrice = 100000000000000; 
    // => NOT USED, to be used for a new calculation
    uint256 public lastAKeyPrice; 
    // => NOT USED, to be used for a new calculation
    uint256 public lastBKeyPrice; 
    
    uint256 public launchTime = 10; // ? to be decided
    
    // 01/01/2020 ? to be decided
    uint256 public expirationTime = 1576800000; 
    
    // 12 h countdown cap
    uint256 public countdown = 43200; 
    // Increase 2 minutes per purchase of a full A key
    uint256 public increaseStep = 120; 
    // 10 minutes between each round
    uint256 public roundInterval = 600; 
    
    // 100 key units = 1 actual key
    uint256 public keyDecimal = 100; 

    uint256 public BRewardPercent = 40;
    uint256 public reservedPercent = 10;
    uint256 public ARewardPercent = 40;
    // BIG FAT reward for last player 
    uint256 public lastPlayerPercent = 10; 
    
    // current max player ID => total # of player
    uint256 public lastPID;    
    // current round ID => total # of rounds
    uint256 public currRID;    
    
    // RID => round data
    mapping (uint256 => Round) public rounds;   
    // addr => PID
    mapping (address => uint256) public addrToPID; 
    // PID => player data
    mapping (uint256 => Player) public PIDToPlayers;   
    // PID, RID => PlayerRound
    mapping (uint256 => mapping (uint256 => PlayerRound)) public playerRounds; 
   
    struct Player{
        uint256 PID; // if new, assign new ID and update last PID;
        address account; //player address
        // mapping (uint256 => PlayerRound) myRounds; // RID => PlayerRound
    }
    
    struct PlayerRound{
        uint256 PID;
        uint256 RID;
        uint256 AKeys; // set to 0 upon paying dividends
        uint256 BKeys; // only cleared at final stage
        
        // A keys given upon last payment. 
        // NOTE: needs to be >= 1 to be eligible for last-player big-fat reward.
        uint256 lastAKeys; 
        
        // // dividends obtained after last claim, can be claimed at anytime
        // // cleared upon withdraw 
        // uint256 AEarning;
        
        // dividends already claimed in this round. Cumulated.
        uint256 claimedAEarning;
        
        // total dividends of the round when the player registered for this round
        uint256 initTotalDivi;
        
        // // # of A keys when the player last claimed dividends
        // // used to approx real time dividends
        // uint256 lastClaimAKeys;
        // uint256 BEarning; // calculated only at the end of round
    }
    
    struct Round{
        uint256 RID; // primary key
        
        uint256 totalAKeys;
        uint256 totalBKeys;
        
        uint256 pot; // all 4 pots should add up to (address(this)).balance ?
        uint256 dividends; // needs to claim by oneself
        uint256 foundationReserved; 
        uint256 lastPlayerReward; // dynamically grow as more wager goes in
        
        address lastPlayer; // keeps changing as new payments goes in
        
        uint256 start;
        uint256 end; // changes after start
        bool hasBeenEnded;
    }

    
    // fire when assigns dividends
    event DividendsIncr(address player, uint256 amount);
    
    // fire when one claims his/her dividends
    event DividendsPaid(address player, uint256 amount);
    
    // fire for front end to catch when dividends com in
    event NewDividends(uint256 amount);
    
    // fire when last winner is confirmed to be valid
    event GetLastWinner(address last);
    
    // fire when pot increases
    event PotIncr(uint256 amount);
    
    // fire when end time got updated 
    event EndUpdate(uint256 newEnd);
    
    // fire for the front end to deal with upon receiving any transaction
    event PaymentReceived(address sender, uint256 value);
    
    // fire when final stage transfer is made. 
    // can be A or B or both rewards
    event RewardsClear(address player, uint256 rewards);
    
    
    /**
     * @dev sets boundaries for incoming eth (per payment) in wei
     * @param amount Amount of eth
     */
    modifier checkBoundaries(uint256 amount) {
        // 1/10000 eth minimum, least pay for 0.01 actual key
        require(amount >= 100000000000000); 
        require(amount <= 100000000000000000000); // 100 eth maximum
        _;    
    }
    
    /**
     * @dev check if there has been >=1 round(s)
     */
    modifier hasLaunched() {
        require(currRID >= 1);
        _;
    }
    
    /**
     * @dev This prevents the owner of the contract from running away.
     * 
     */
    modifier hasExpired() {
        require(isCurrRoundEnded());
        require(now >= expirationTime);
        _;
    }
    
    /**
     * @dev check if has passed launch time
     */
    modifier readyToLaunch() {
        require(now >= launchTime);
        _;
    }
    
    /**
     * @dev constructor, initialize values
     */
    constructor() public {
        // init dynamically changing values
        lastAKeyPrice = initAKeyPrice;
        lastBKeyPrice = initBKeyPrice;
        lastPID = 0;
        currRID = 0;
    }
    
    /**
     * @dev only allow withdraw after a round has ended.
     */
    function withdraw() public onlyOwner hasLaunched {
        require(isCurrRoundEnded());
        owner.transfer(rounds[currRID].foundationReserved); 
    }
    
    /**
     * @dev only allow withdraw after the game has expired and no round is running.
     * The foundation cannot extract left money and run until 01/01/2020.
     */
    function withdrawLeftover() public onlyOwner hasExpired {
        require(isCurrRoundEnded());
        owner.transfer(address(this).balance); 
    }
    
    /**
     * @dev Fallback function. Receives ether and assign keys to the payer. 
     * NOTE: Payments with values outside the accepted range will be disgarded.
     * NOTE: Payments sent during cooling down or before launch will be ignored, 
     * that is to say, no keys given upen payment.
     */
    function() public payable hasLaunched checkBoundaries(msg.value) {
        // do nothing before actual launch of the game
        // deal with the received payment
        dealWithPay(msg.sender, msg.value);
        
        // UI catch and deal with payment
        emit PaymentReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev Helper for dealing with any incoming tx.
     * @param sender The payer
     * @param value The amount sent to contract
     */
    function dealWithPay(address sender, uint256 value) 
        public 
        onlyOwner 
        hasLaunched 
    {
        // for time consistency throughout the function
        uint256 _now = now;

        // 2 scenarios: last round has ended; you are still in a round
        // NOTE: numbers of keys bought are calculated differently upon diff scenarios
        ////////////////////////////////////////////////////////////////////////
        // last round ended
        if(isCurrRoundEnded()){
            // End curr round if it has not been ended
            // foundation reserve in endround()
            // NOTE: currRound changes
            uint256 lastEnd = rounds[currRID].end;
            if(!rounds[currRID].hasBeenEnded){
                endRound();
            }
            
            if (_now >= lastEnd.add(roundInterval)) {
                // has ended and passed cooling down but not yet started a new round
                // End curr round
                // Start a new round!
                startRound();
                updateAndRecalc(sender, value);
            }
            else{
                //do nothing during cool down time. Payments ignored.
            }
        }
        ////////////////////////////////////////////////////////////////////////
        //if hasn't ended yet, that is, curr round still active
        else{
            // update and pay. A Keys updated here
            updateAndRecalc(sender, value);
            // update round end time
            PlayerRound storage pr = playerRounds[addrToPID[sender]][currRID];
            uint256 aKeys2 = pr.lastAKeys;
            if(aKeys2 >= 100){
                //if purchased a full key
                Round memory currRound2 = rounds[currRID];
                if(countdown < ((currRound2.end).sub(_now)).add(aKeys2.mul(increaseStep).div(100))){
                    currRound2.end = _now.add(countdown);
                }
                else{
                    currRound2.end = (currRound2.end).add(aKeys2.mul(increaseStep).div(100));
                }
                emit EndUpdate(currRound2.end);
            }
            else{
                // if not a full actual key
                // no update of end time
            }
        }
    }
    
    
    /**
     * @dev Helper function to update round info upon payment.
     * @param _account The account made the payment
     * @param _amount Amount of the payment
     */
     function updateAndRecalc(address _account, uint256 _amount) 
        public 
        onlyOwner 
        hasLaunched 
     {
            uint256 _pid = addrToPID[_account];
            uint256 amt = _amount; // passed value
            // calc keys. Only called once per payment
            uint256 _aKeys = AKeysOf(amt);
            // give B keys with the curr value of the same amount of money paid
            uint256 _bKeys = BKeysOf(amt); 
            
            // player is new
            if(_pid == 0){
                lastPID ++;
                Player memory p = Player ({
                    PID: lastPID,
                    account: _account
                });
                
                PlayerRound memory pr = PlayerRound ({
                    PID: lastPID,
                    RID: currRID,
                    AKeys: _aKeys,
                    BKeys: _bKeys,
                    lastAKeys: _aKeys,
                    claimedAEarning: 0,
                    initTotalDivi: 0
                });
                playerRounds[p.PID][currRID] = pr;
                // update instance variables
                PIDToPlayers[p.PID] = p;
                addrToPID[_account] = p.PID;
            }
            // player exists in record
            else{
                PlayerRound memory pr2 = playerRounds[_pid][currRID];
                pr2.AKeys = pr2.AKeys.add(_aKeys);
                pr2.BKeys = pr2.BKeys.add(_bKeys);
                pr2.lastAKeys = _aKeys;
            }
            
            Round memory currRound = rounds[currRID];
            // assign dividends
            uint256 toPay = ((_amount).mul(ARewardPercent)).div(100);
            // update A's total dividends
            currRound.dividends = (currRound.dividends).add(toPay);
            emit NewDividends(toPay);
            
            //update round info     
            currRound.foundationReserved = (currRound.foundationReserved).add((_amount).mul(reservedPercent).div(100));
            currRound.pot = (currRound.pot).add((_amount).mul(BRewardPercent).div(100));
            currRound.lastPlayerReward = (currRound.lastPlayerReward).add((_amount).mul(lastPlayerPercent).div(100));
            currRound.lastPlayer = _account;
            currRound.totalAKeys = (currRound.totalAKeys).add(_aKeys);
            currRound.totalBKeys = (currRound.totalBKeys).add(_bKeys);
            
            emit PotIncr(currRound.pot);
     }
    
    
    /**
     * @dev for checking if a game has ended.
     */
    function isCurrRoundEnded() public view returns (bool) {
        if(currRID == 0){
            return false;
        }
        return now >= rounds[currRID].end;
    }
    
    /**
     * @dev calculates the number of A keys given amount of eth in wei.
     * @param _quantity The amount of eth paid
     */
     function AKeysOf(uint256 _quantity) 
        public 
        onlyOwner 
        hasLaunched 
        returns (uint256) 
    {
        uint256 ret = 0;
        // dynamic step for approx the result without exceeding gas limit
        uint256 step = _quantity.div(lastAKeyPrice).div(10);
        if(step < 1) {
            step = 1;
        }
        uint256 rise = step.mul(18);
        while(_quantity.sub(lastAKeyPrice.mul(step)) >= 1) {
            _quantity = _quantity.sub(lastAKeyPrice.mul(step));
            lastAKeyPrice = lastAKeyPrice.mul((1000000).add(rise)).div(1000000);
            ret = ret.add(step);
        }
        // if left money greater than half of the next key price,
        // count as 1
        if(_quantity > lastAKeyPrice.mul(step).div(2)) {
            ret = ret.add(step);
            lastAKeyPrice = lastAKeyPrice.mul((1000000).add(rise)).div(1000000);
        }
        // no way to be lower than 1
        if(ret < 1){
            ret = 1;
        }
        return ret;
     }
     
    /**
     * @dev calculates the number of B keys (decimal=100) given amount of eth in wei. 
     * NOTE: Limits minimum price to 1 to avoid crash.
     * @param _quantity The amount of eth paid
     */
     function BKeysOf(uint256 _quantity)    
        public 
        onlyOwner 
        hasLaunched 
        returns (uint256) 
    {
        uint256 ret = 0;
        // dynamic step for approx the result without exceeding gas limit
        uint256 step = _quantity.div(lastAKeyPrice).div(10);
        if(step < 1) {
            step = 1;
        }
        uint256 fall = step.mul(18);
        while(_quantity.sub(lastBKeyPrice.mul(step)) >= 1) {
            _quantity = _quantity.sub(lastBKeyPrice.mul(step));
            lastBKeyPrice = lastBKeyPrice.mul((1000000).sub(fall)).div(1000000); 
            ret = ret.add(step);
        }
        // if left money greater than half of the next key price,
        // count as 1        
        if(_quantity > lastBKeyPrice.mul(step).div(2)) {
            ret = ret.add(step);
            lastBKeyPrice = lastBKeyPrice.mul((1000000).sub(fall)).div(1000000);
        }
        // no way to be lower than 1
        if(ret < 1){
            ret = 1;
        }
        return ret;
     }
         
    
     /**
     * @dev Ends current round, starts cooling down. 
     * All players' data reset to default.
     * Pays last player reward and B key rewards.
     * Pays A rewards according to cumulated earnings.
     * Foundation withdraw.
     */
    function endRound() public onlyOwner hasLaunched {
        require(currRID > 0 && now >= rounds[currRID].end);
        // update round info? no, except hasBeenEnded
        
        // do not update curr RID!!
        Round memory currRound = rounds[currRID];
        currRound.hasBeenEnded = true;
        
        // ready to claim B rewards
        // claim dividends as you want
        
        // pay final winner
        checkAndPayLastPlayer();
       
        //foundation withdraw all eth left
        withdraw();
    }
    
    /**
     * @dev starts a new round.
     * NOTE: not set start to 'now' but the estimated time based on last end.
     */
    function startRound() public onlyOwner readyToLaunch {
        // do not start until actual launchTime
        // check and return without doing anything if not ready to start
        require((rounds[currRID].end).add(roundInterval) <= now || currRID == 0);
        
        // check if last round has ended. If not, need to end last round first
        if((currRID!=0) && (!rounds[currRID].hasBeenEnded)){
            endRound();
        }
        //update parameters
        currRID = currRID.add(1);
        lastAKeyPrice = initBKeyPrice;
        lastBKeyPrice = initBKeyPrice;
        //set a new round
        uint256 newStart;
        // launch the first game or use previous data to set start/end time
        if(currRID > 1){
            newStart = (rounds[currRID-1].end).add(roundInterval);
        }
        else{
            newStart = now;
        }
        Round memory r = Round({
            RID: currRID,
            totalAKeys: 0,
            totalBKeys: 0,
            pot: 0,
            dividends: 0,
            foundationReserved: 0,
            lastPlayerReward: 0,
            lastPlayer: address(0),
            start: newStart,
            end: newStart.add(countdown),
            hasBeenEnded: false
        });
        rounds[currRID] = r;
        
        emit EndUpdate(r.end);
    }
    
    
    // /**
    //  * @dev can be called by anyone to calc a player's dividends. 
    //  * Cumulate specified earnings to players. Update info.
    //  * NOTE: Earnings will all be sent to players at the END of each round.
    //  * @param _pid
    //  * @param _rid
    //  */
    // function calcDividends(uint256 _rid) 
    //     public 
    //     hasLaunched 
    // {
    //     Round storage r = rounds[currRID]; //view, no need to be memory
    //     // fetch Player
    //     PlayerRound memory pr = playerRounds[addrToPID[msg.sender]][_rid];
    //     uint256 divi = (total).mul(pr.AKeys).div(r.totalAKeys);
    //     pr.AEarning = pr.AEarning.add(divi);
    //     pr.AKeys = 0;
        
    //     emit DividendsIncr(p.account, p.AEarning);
    // }
    
    /**
     * @dev can be called by anyone to withdraw dividends balance.
     * Clears balance.
     * @param _rid Round ID from which the dividends to be withdraw.
     */
    function withdrawDividends(uint256 _rid) public hasLaunched {
        //do nothing if not a valid registered player
        if(addrToPID[msg.sender] == 0) return;
        
        // fetch Player
        PlayerRound memory pr = playerRounds[addrToPID[msg.sender]][_rid];
        //fetch round
        Round storage r = rounds[_rid]; //view, no need to be memory
        
        // calc current earning
        // check claimed earning >= current 
        
        // currrent earn 
        // = # of A Keys * (total curr divi - init divi when player entered game)
        // / total current A keys
        uint256 currEarn = (pr.AKeys).mul((r.dividends).sub(pr.initTotalDivi)).div(r.totalAKeys);
        
        uint256 toSend = currEarn.sub(pr.claimedAEarning); // for proper serialization
        if(toSend > 0){
            pr.claimedAEarning = pr.claimedAEarning.add(toSend);
            (msg.sender).transfer(toSend);
        }
            
        emit DividendsPaid(msg.sender, toSend);
    }
    
    /**
     * @dev for players to claim their final B rewards after game ends.
     * @param _rid Round ID from which the rewards to be withdraw.
     * NOTE: dividends in this round will be claimed AS WELL !!
     * Sends the ALL earnings to players.
     * Rewards paid at final stage of each round.
     * @param _rid The round that you want to claim rewards from.
     */
    function claimRewards(uint256 _rid) public hasLaunched {
        //do nothing if not a valid registered player
        if(addrToPID[msg.sender] == 0) {
            return;
        }
        
        Round storage r = rounds[currRID];
        //do nothing if the current round has not ended
        if(!r.hasBeenEnded) {
            return;
        }
        
        // fetch Player
        PlayerRound memory pr = playerRounds[addrToPID[msg.sender]][_rid];
        uint256 rewards = (r.pot).mul(pr.BKeys).div(r.totalBKeys);
        pr.BKeys = 0;
        
        // check if the player's dividends has anything left
        uint256 currEarn = (pr.AKeys).mul((r.dividends).sub(pr.initTotalDivi)).div(r.totalAKeys);
        uint256 aRewards = currEarn.sub(pr.claimedAEarning); // for proper serialization
        if(aRewards > 0){
            pr.claimedAEarning = pr.claimedAEarning.add(aRewards);
            rewards = rewards.add(aRewards);
        }
        
        // actually pays the player automatically!
        (msg.sender).transfer(rewards);
         emit RewardsClear(msg.sender, rewards);
    }
    
    // /**
    //  * @dev automatically claims earnings for 'lazy' players after curr round ends.
    //  * @param lazy The player PID. 
    //  * Apparently, the author is also too lazy to think a better var name.
    //  */
    //  function autoClaim(uint256 _lazy, uint256 _rid) public onlyOwner hasLaunched {
    //     Round storage r = rounds[currRID];
    //     //do nothing if that round has not ended
    //     if(!r.hasBeenEnded) {
    //         return;
    //     }
        
    //     uint256 rewards = 0;
    //     rewards = rewards.add(p.AEarning).add((r.pot).mul(pr.BKeys).div(r.totalBKeys));
        
    //     Player memory p = PIDToPlayers[lazy];
    //     p.AEarning = 0;
    //     p.AKeys = 0;
    //     p.lastAKeys = 0;
    //     p.BKeys = 0;
         
    //     (p.account).transfer(rewards);
    //     emit RewardsClear(p.account, rewards);
    //  }
    
    
    /**
     * @dev Checks if the last player is eligible for last-player reward.
     * If so, pay the player.
     */
     function checkAndPayLastPlayer() public onlyOwner hasLaunched {
        // check if last round has ended. If not, need to end last round first
        if(!rounds[currRID].hasBeenEnded){
            endRound();
        }
        
        Round memory r = rounds[currRID];
        PlayerRound storage last = playerRounds[addrToPID[r.lastPlayer]][currRID];
        Player storage p = PIDToPlayers[last.PID];
        if(last.lastAKeys >= 100){
            // has a full key
            (p.account).transfer(r.lastPlayerReward);
            
            emit GetLastWinner(p.account);
        }
        else{
            // not a full key
            // sadly, can't claim the big-fat reward
        }
     }
    
    
    
}



//////////////////////////////////////////////////////////////
