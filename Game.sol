pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * https://github.com/OpenZeppelin/openzeppelin-solidity
 */
library SafeMath {

      /**
      * @dev Multiplies two numbers, throws on overflow.
      */
      function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        if (a == 0) {
          return 0;
        }
    
        c = a * b;
        assert(c / a == b);
        return c;
      }
    
      /**
      * @dev Integer division of two numbers, truncating the quotient.
      */
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
      }
    
      /**
      * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
      */
      function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
      }
    
      /**
      * @dev Adds two numbers, throws on overflow.
      */
      function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
      }
    
    // /**
    //  * @dev calculates square root of given number.
    //  */
    // function sqrt(uint256 x) internal pure returns (uint256 y) 
    // {
    //     uint256 z = ((add(x,1)) / 2);
    //     y = x;
    //     while (z < y) {
    //         y = z;
    //         z = ((add((x / z),z)) / 2);
    //     }
    // }
    
    // /**
    //  * @dev calculates x to the power of y 
    //  */
    // function power(uint256 x, uint256 y) internal pure returns (uint256) {
    //     if (x==0){
    //         return (0);
    //      }
    //     else if (y==0){
    //         return (1);
    //      }
    //     else 
    //     {
    //         uint256 z = x;
    //         for (uint256 i=1; i < y; i++){
    //             z = mul(z,x);
    //      }
    //         return (z);
    //     }
    // }
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
    uint256 public initAKeyPrice = 100000000000000; // 0.18% up per new actual key => 0.0018% per key uint
    uint256 public initBKeyPrice = 100000000000000; // 0.18% down per new actual key => 0.0018% per key uint
    uint256 public lastAKeyPrice; // => ALREADY USED, need to be updated before using for new calculation
    uint256 public lastBKeyPrice; // => ALREADY USED, need to be updated before using for new calculation
    
    uint256 public launchTime; // ? to be decided
    
    uint256 public countdown = 43200; // 12 h countdown cap
    uint256 public increaseStep = 120; // Increase 2 minutes per purchase of a full A key
    uint256 public roundInterval = 600; // 10 minutes between each round
    
    uint256 public keyDecimal = 100; // 100 key units = 1 actual key

    uint256 public BRewardPercent = 40;
    uint256 public reservedPercent = 10;
    uint256 public ARewardPercent = 40;
    uint256 public lastPlayerPercent = 10; // BIG FAT reward for last player 
    
    uint256 lastPID;    // current max player ID => total # of player
    uint256 public currRID;    // current round ID => total # of rounds
    
    // uint256[] players; // players eligible for B rewards. arr index => PID
    
    mapping (uint256 => Round) public rounds;   // RID => round data
    mapping (address => uint256) public addrToPID; // addr => PID
    mapping (uint256 => Player) public PIDToPlayers;   // PID => player data
   
    struct Player{
        uint256 PID; // if new, assign new ID and update last PID;
        address account; //player address
        uint256 AKeys; // set to 0 upon paying dividends
        uint256 BKeys; // only cleared at final stage
        uint256 lastAKeys; // A keys given upon last payment. NOTE: needs to be >= 1 to be eligible for last-player big-fat reward.
        uint256 AEarning; // cumulated dividends obtained
        // uint256 BEarning; // calculated finally 
    }
    
    struct Round{
        uint256 RID;
        uint256 totalAKeys;
        uint256 totalBKeys;
        uint256 pot; // all 3 pots add up to (address(this)).balance ?
        uint256 foundationReserved; 
        uint256 lastPlayerReward; // dynamically grow as more wager goes in
        address lastPlayer; // keeps changing as new payments goes in
        uint256 start;
        uint256 end; // changing
        // uint256 lastPressTime; // 'absolute' time
        // uint256 lastPressRemainingTime; // time interval
        bool hasBeenEnded;
    }

    
    // fire when assigns dividends
    event DividendsIncr(address player, uint256 amount);
    
    // fire when last winner is confirmed to be valid
    event GetLastWinner(address last);
    
    // fire when pot increases
    event PotIncr(uint256 amount);
    
    // fire when end time got updated 
    event EndUpdate(uint256 newEnd);
    
    
    /**
     * @dev sets boundaries for incoming eth (per payment) in wei
     * @param amount Amount of eth
     */
    modifier checkBoundaries(uint256 amount) {
        require(amount >= 100000000000000); // 1/10000 eth minimum, least pay for 0.01 actual key
        require(amount <= 1000000000000000000000); // 1000 eth maximum
        _;    
    }
    
    /**
     * @dev check if has passed launch time
     */
    modifier hasLaunched() {
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
        owner.transfer((address(this)).balance); 
    }
    
    /**
     * @dev Fallback function. Receives ether and assign keys to the payer. 
     * NOTE: Payments with values outside the accepted range will be disgarded.
     * NOTE: Payments sent during cooling down or before launch will be ignored, 
     * that is to say, no keys given upen payment.
     */
    function() public payable checkBoundaries(msg.value) {
        // do nothing before actual launch of the game
        if(now < launchTime) return;
        
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
                updateAndPay(msg.sender, msg.value);
            }
            else{
                //do nothing during cool down time. Payments ignored.
            }
        }
        ////////////////////////////////////////////////////////////////////////
        //if hasn't ended yet, that is, curr round still active
        else{
            uint256 aKeys2 = AKeysOf(msg.value); //store amount of A keys first
            // update and pay
            updateAndPay(msg.sender, msg.value);
            // update round end time
            if(aKeys2 >= 100){
                //if purchased a full key
                Round memory currRound2 = rounds[currRID];
                if(countdown < (currRound2.end).sub(_now) + aKeys2.mul(increaseStep).div(100)){
                    currRound2.end = _now + countdown;
                }
                else{
                    currRound2.end = currRound2.end + aKeys2.mul(increaseStep).div(100);
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
     * payPlayersA called inside.
     * @param _account The account made the payment
     * @param _amount Amount of the payment
     */
     function updateAndPay(address _account, uint256 _amount) private hasLaunched {
            Round memory currRound = rounds[currRID];
            uint256 _pid = addrToPID[_account];
            uint256 aKeys = AKeysOf(_amount);
            uint256 bKeys = BKeysOf(_amount); // give B keys with the curr value of the same amount of money paid
            
            // player is new
            if(_pid == 0){
                Player memory p = Player ({
                    //init default
                    PID: lastPID + 1, 
                    account: _account,
                    AKeys: aKeys,
                    BKeys: bKeys,
                    lastAKeys: aKeys,
                    AEarning: 0
                });
                lastPID ++;
                // update instance variables
                PIDToPlayers[p.PID] = p;
                addrToPID[_account] = p.PID;
            }
            // player exists in record
            else{
                Player memory p2 = PIDToPlayers[_pid];
                p2.AKeys = p2.AKeys + aKeys;
                p2.BKeys = p2.BKeys + bKeys;
                p2.lastAKeys = aKeys;
            }
            
            // assign dividends
            uint256 toPay = ((_amount).mul(ARewardPercent)).div(100);
            payPlayersA(toPay);
            
            //update round info     
            currRound.foundationReserved = currRound.foundationReserved + (_amount).mul(reservedPercent).div(100);
            currRound.pot = currRound.pot + (_amount).mul(BRewardPercent).div(100);
            currRound.lastPlayerReward = currRound.lastPlayerReward + (_amount).mul(lastPlayerPercent).div(100);
            currRound.lastPlayer = _account;
            currRound.totalAKeys = currRound.totalAKeys + aKeys;
            currRound.totalBKeys = currRound.totalBKeys + bKeys;
            
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
     function AKeysOf(uint256 _quantity) private hasLaunched returns (uint256) {
        uint256 ret = 0;
        // last key price => ALREADY USED, need to be updated before using for new calculation
        lastAKeyPrice = lastAKeyPrice.mul(18).div(1000000);
        while(_quantity - lastAKeyPrice >= 0) {
            _quantity = _quantity - lastAKeyPrice;
            lastAKeyPrice = lastAKeyPrice.mul((18).add(1000000)).div(1000000);
            ret = ret + 1;
        }
        // if left money greater than half of the next key price,
        // count as 1
        if(_quantity > lastAKeyPrice / 2) {
            ret = ret + 1;
            lastAKeyPrice = lastAKeyPrice.mul((18).add(1000000)).div(1000000);
        }
        
        return ret;
     }
     
    /**
     * @dev calculates the number of B keys (decimal=100) given amount of eth in wei. 
     * NOTE: Limits minimum price to 1 to avoid crash.
     * @param _quantity The amount of eth paid
     */
     function BKeysOf(uint256 _quantity) private hasLaunched returns (uint256) {
        uint256 ret = 0;
        lastBKeyPrice = lastBKeyPrice.mul(18).div(1000000);
        while(_quantity - lastBKeyPrice >= 0) {
            _quantity = _quantity - lastBKeyPrice;
            lastBKeyPrice = lastBKeyPrice.mul((1000000).sub(18)).div(1000000); 
            ret = ret + 1;
        }
        // if left money greater than half of the next key price,
        // count as 1        
        if(_quantity > lastBKeyPrice / 2) {
            ret = ret + 1;
            lastBKeyPrice = lastBKeyPrice.mul((1000000).sub(18)).div(1000000);
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
    function endRound() public onlyOwner {
        require(now >= rounds[currRID].end);
        // update round info? no, except hasBeenEnded
        
        // do not update curr RID!!
        Round memory currRound = rounds[currRID];
        currRound.hasBeenEnded = true;
        // actually pay dividends => make tx
        for(uint256 i = 1; i <= lastPID; i++) {
            Player memory p = PIDToPlayers[i];
            (p.account).transfer(p.AEarning);
        }
        
        // pay rewards
        payPlayersB();
        // pay final winner
        checkAndPayLastPlayer();
        // set all players info to defaults!!
        for(uint256 j = 1; j <= lastPID; j++) {
            Player memory p2 = PIDToPlayers[j];
            p2.AEarning = 0;
            p2.AKeys = 0;
            p2.BKeys = 0;
            p2.lastAKeys = 0;
        }
       
        //foundation withdraw all eth left
        withdraw();
    }
    
    /**
     * @dev starts a new round.
     * NOTE: not set start to 'now' but the estimated time based on last end.
     */
    function startRound() public onlyOwner hasLaunched {
        // do not start until actual launchTime
        // check and return without doing anything if not ready to start
        require(rounds[currRID].end + roundInterval <= now);
        
        // check if last round has ended. If not, need to end last round first
        if(!rounds[currRID].hasBeenEnded){
            endRound();
        }
        //update parameters
        currRID ++;
        lastAKeyPrice = initBKeyPrice;
        lastBKeyPrice = initBKeyPrice;
        //set a new round
        Round memory r = Round({
            RID: currRID,
            totalAKeys: 0,
            totalBKeys: 0,
            pot: 0,
            foundationReserved: 0,
            lastPlayerReward: 0,
            lastPlayer: address(0x0),
            start: rounds[currRID-1].end+roundInterval,
            end: rounds[currRID-1].end+roundInterval + countdown,
            hasBeenEnded: false
        });
        rounds[currRID] = r;
        
        emit EndUpdate(r.end);
    }
    
    
    /**
     * @dev Helper function to pay all players dividends. 
     * Cumulate specified earnings to players. Update info.
     * NOTE: Earnings will all be sent to players at the END of each round.
     * @param _amount Amount to to divided.
     */
    function payPlayersA(uint256 _amount) public onlyOwner hasLaunched {
        Round storage r = rounds[currRID]; //view, no need to be memory
        for(uint256 i = 1; i <= lastPID; i++){
            // fetch Player
            Player memory p = PIDToPlayers[i];
            uint256 dividends = (_amount).mul(p.AKeys).div(r.totalAKeys);
            p.AEarning = p.AEarning + dividends;
            
            emit DividendsIncr(p.account, p.AEarning);
        }
    }
    
    /**
     * @dev Helper function to pay all players with the pot.
     * Sends the earnings to players.
     * Rewards paid at final stage of each round.
     */
    function payPlayersB() public onlyOwner hasLaunched {
        Round storage r = rounds[currRID];
        for(uint256 i = 1; i <= lastPID; i++){
            // fetch Player
            Player memory p = PIDToPlayers[i];
            uint256 rewards = (r.pot).mul(p.BKeys).div(r.totalBKeys);
            // actually pays the player automatically!
            (p.account).transfer(rewards);
        }
    }
    
    
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
        Player storage last = PIDToPlayers[addrToPID[r.lastPlayer]];
        if(last.lastAKeys >= 100){
            // has a full key
            (last.account).transfer(r.lastPlayerReward);
            
            emit GetLastWinner(last.account);
        }
        else{
            // not a full key
            // sadly, can't claim the big-fat reward
        }
     }
    
    
    
}



//////////////////////////////////////////////////////////////
