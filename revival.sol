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
        if (c < a) {
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
    
    //   /**
    //   * @dev Integer division of two numbers, truncating the quotient.
    //   * Returns the first value if requirement doesn't hold.
    //   */
    //   function div(uint256 a, uint256 b) internal pure returns (uint256) {
    //     // assert(b > 0); // Solidity automatically throws when dividing by 0
    //     uint256 c = a / b;
    //     // if(c > a){
    //     //     return 1;
    //     // }
    //     return c;
    //   }

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

library Util {
    function bytesToUint(bytes b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(b[i])*(2**(8*(b.length-(i+1))));
        }
        return number;
    }
    
    function toBytes(address a) internal pure returns (bytes b){
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
       }
    }
    
    function bytesToAddress (bytes b) internal pure returns (address) {
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 16 + (c - 48);
            }
            if(c >= 65 && c<= 90) {
                result = result * 16 + (c - 55);
            }
            if(c >= 97 && c<= 122) {
                result = result * 16 + (c - 87);
            }
        }
        return address(result);
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
    using Util for address;
    using Util for bytes;
    
    //NOTE: 10 key units = 1 actual key for purchase
    // 0.18% up per new actual key => 0.018% per key uint
    // 0.01 ETH per A key => 0.001 ETH per A key unit
    uint256 public INITAKEYPRICE = 1000000000000000; 
    // 0.18% down per new actual key => 0.018% per key uint
    // 0.1 ETH per B key => 0.01 ETH per B key unit
    uint256 public INITBKEYPRICE = 10000000000000000; 
    // => NOT USED, to be used for a new calculation
    uint256 public lastAKeyPrice; 
    // => NOT USED, to be used for a new calculation
    uint256 public lastBKeyPrice; 
    
    uint256 public LAUNCHTIME = 10; // ? to be decided
    
    // 01/01/2020 ? to be decided
    uint256 public EXPIRATIONTIME = 1576800000; 
    
    // 12 h countdown cap, reset when get full A key
    uint256 public COUNTDOWN = 43200; 
    // // Increase 2 minutes per purchase of a full A key
    // uint256 public increaseStep = 120; 
    // 10 minutes between each round
    uint256 public ROUNDINTERVAL = 600; 
    
    // 10 key units = 1 actual key
    uint256 public KEYDECIMAL = 10; 

    uint256 public BREWARDPERCENT = 40;
    uint256 public RESERVEDPERCENT = 10;
    uint256 public AREWARDPERCENT = 40;
    // BIG FAT reward for last player 
    uint256 public LASTPLAYERPERCENT = 10; 
    uint256 public REFERPERCENT = 5;
    
    // current max player ID => total # of player
    uint256 public lastPID;    
    // current round ID => total # of rounds
    uint256 public currRID; 
    // tx data (referrer addr) => bonus
    mapping (bytes => uint256) referBonus;
    // // PID, RID => current tx number
    // mapping (uint256 => mapping (uint256 => uint256)) public maxTxID;
    // // PID, RID, txID => TXRecord
    // mapping (uint256 => mapping (uint256 => mapping (uint256 => TXRecord))) txRecords;
    
    // RID => round data
    mapping (uint256 => Round) public rounds; 
    // addr => PID
    mapping (address => uint256) public addrToPID; 
    // PID => player data
    mapping (uint256 => Player) public players;   
    // PID, RID => PlayerRound
    mapping (uint256 => mapping (uint256 => PlayerRound)) public playerRounds;
    
    // struct TXRecord {
    //     uint256 cumulatedAKeys; // player total A keys when tx happened
    //     uint256 currTotalAkeys; // total A keys when tx happened
    //     uint256 currTotalDivi; // total dividends when tx happened
    // }
   
    struct Player {
        // uint256 PID; // if new, assign new ID and update last PID;
        address account; //player address
        uint256 earning; // cumulated earning through out all rounds
        uint256 lastRound; // last played round
        // mapping (uint256 => PlayerRound) myRounds; // RID => PlayerRound
    }
    
    struct PlayerRound {
        uint256 AKeys; // set to 0 upon paying dividends
        uint256 BKeys; // only cleared at final stage
        
        // A keys given upon last payment. 
        // NOTE: # of full keys needs to be >= 1 to be eligible for last-player big-fat reward.
        uint256 lastAKeys; 
        
        // // dividends obtained after last claim, can be claimed at anytime
        // // cleared upon withdraw 
        // uint256 AEarning;
        // // dividends already claimed in this round. Cumulated.
        // uint256 claimedAEarning;
        
        // // total dividends of the round when the player registered for this round
        // uint256 initTotalDivi;
        
        // uint256 maxTxID;
        // uint256 startClaimTxID;
        uint256 cumu;
        
        // // # of A keys when the player last claimed dividends
        // // used to approx real time dividends
        // uint256 lastClaimAKeys;
        // uint256 BEarning; // calculated only at the end of round
    }
    
    struct Round {
        // uint256 RID; // primary key
        uint256 cumu;
        
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
    
    // fire when a new round is started
    event NewRound(uint256 roundID, uint256 startTime, uint256 endTime);
    
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
        // 1/1000 eth minimum, least pay for 0.1 actual init A key
        require(amount >= 1000000000000000); 
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
        require(now >= rounds[currRID].end);
        require(now >= EXPIRATIONTIME);
        _;
    }
    
    /**
     * @dev check if has passed launch time
     */
    modifier readyToLaunch() {
        require(now >= LAUNCHTIME);
        _;
    }
    
    /**
     * @dev constructor, initialize values
     */
    constructor() public {
        // init dynamically changing values
        lastAKeyPrice = INITAKEYPRICE;
        lastBKeyPrice = INITBKEYPRICE;
        lastPID = 0;
        currRID = 0;
    }
    
    /**
     * @dev only allow withdraw after a round has ended.
     */
    function withdraw(uint256 _rid) public hasLaunched {
        require(rounds[_rid].hasBeenEnded);
        uint256 toWithdraw = rounds[_rid].foundationReserved > address(this).balance ? address(this).balance : rounds[_rid].foundationReserved;
        owner.transfer(toWithdraw); 
    }
    
    /**
     * @dev only allow withdraw after the game has expired and no round is running.
     * The foundation cannot extract left money and run until 01/01/2020.
     */
    function withdrawLeftover() public hasExpired {
        require(isCurrRoundEnded());
        owner.transfer(address(this).balance); 
    }
    
    // /**
    //  * @dev Default fallback function. Receives ether and assign keys to the payer. 
    //  * NOTE: Payments with values outside the accepted range will be disgarded.
    //  * NOTE: Payments sent during cooling down or before launch will be ignored, that is to say, no keys given upon payment.
    //  */
    // function() public payable hasLaunched checkBoundaries(msg.value) {
    //     // do nothing before actual launch of the game
    //     // deal with the received payment
    //     // UI catch and deal with payment and do following operations
    //     emit PaymentReceived(msg.sender, msg.value);
    // }
    
    /**
     * @dev Fallback function. Receives ether and assign keys to the payer. 
     * NOTE: Payments with values outside the accepted range will be disgarded.
     * NOTE: Payments sent during cooling down or before launch will be ignored, that is to say, no keys given upen payment.
     */
    function () 
        public 
        payable 
        readyToLaunch 
        checkBoundaries(msg.value) 
    {
        // do nothing before actual launch of the game
        // deal with the received payment
       
        // launtch game
        if(currRID < 1){
             _startRound();
        }
        uint256 _pid = addrToPID[msg.sender];
        // 2 scenarios: 1. last round has ended; 2.you are still in a round.
        // 1 => 2
        ////////////////////////////////////////////////////////////////////////
        // trigger startRound(), or during cooling down
        if(isCurrRoundEnded()){
            // end round if needed
            if(!rounds[currRID].hasBeenEnded){
                _endRound();
            }
            if((msg.data).bytesToUint() == 2){
                claimRewards();
            }
            
            if(now < (rounds[currRID].end).add(ROUNDINTERVAL)){
                // in the cooling down interval, do nothing
                return;
            }
            else{
                // deal with extreme cases -- empty rounds
                // uint256 extra = (now.sub(rounds[currRID].end)).div(countdown.add(roundInterval));
                while(now >= (rounds[currRID].end).add(ROUNDINTERVAL)){
                    _startRound();
                    if(now >= (rounds[currRID].end)){
                        _endRound();
                    }
                }
            }
            
        }
        ////////////////////////////////////////////////////////////////////////
        //if hasn't ended yet, that is, curr round still active

        // update and pay. Round updated as well
        _updateAndRecalc(msg.sender, _pid, msg.value);
        // update referrer bonus
        if((msg.data).bytesToUint() == 1){
            withdrawDividends();
        }
        else {
            _addReferBonus(msg.data, msg.value);
        }
        
        // UI catch and deal with payment
        emit PaymentReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev private helper for adding referral bonus
     * @param referrer Actually the raw data the payer passed in but no big difference.
     * @param amount Amount that the referee sent to contract.
     */
    function _addReferBonus(bytes referrer, uint256 amount) private hasLaunched {
        address ref = referrer.bytesToAddress();
        // can't use self as a referrer
        require(ref != (msg.sender)); 
        // check player not crediting to self and add refer bonus
        uint256 _pid = addrToPID[ref];
        players[_pid].earning = (players[_pid].earning).add(amount.mul(REFERPERCENT) / 100);
    }
    
    /**
     * @dev Helper function to update round info upon payment.
     * Not included end time update!
     * @param _account The player who made the payment
     * @param _pid Player ID
     * @param _amount Amount of the payment
     */
     function _updateAndRecalc(address _account, uint256 _pid, uint256 _amount) 
        private 
        hasLaunched 
     {
            // calc keys. Only called once per payment
            uint256 _aKeys;
            (_aKeys, lastAKeyPrice) = AKeysOf(_amount);
            // give B keys with the curr value of the same amount of money paid
            uint256 _bKeys;
            (_bKeys, lastBKeyPrice) = BKeysOf(_amount); 
            // player is new
            if(_pid == 0){
                lastPID ++;
                playerRounds[lastPID][currRID].AKeys = _aKeys;
                playerRounds[lastPID][currRID].BKeys = _bKeys;
                playerRounds[lastPID][currRID].lastAKeys = _aKeys;
                // update instance variables
                players[lastPID].account = _account;
                addrToPID[_account] = lastPID;
            }
            // player exists in record
            else{
                if(playerRounds[_pid][currRID].BKeys == 0) {
                    _updatePlayerLast(_pid);
                }
                playerRounds[_pid][currRID].AKeys = playerRounds[_pid][currRID].AKeys.add(_aKeys);
                playerRounds[_pid][currRID].BKeys = playerRounds[_pid][currRID].BKeys.add(_bKeys);
            }
            
            // update round info
            _roundUpdate(_account, _amount, _aKeys, _bKeys);
            // update dividends
            _updateCumus(_pid, _amount, _aKeys);
     }
     
    /**
     * @dev Moves player's last round earning to the new round.
     * @param _pid PID
     */
    function _updatePlayerLast(uint256 _pid)
        private
    {
        // if the player has played a previous round,
        // move the previous earnings to curr round
        if (players[_pid].lastRound != 0) {
            updatePlayerEarn(_pid, players[_pid].lastRound);
        }
            
        // update player's last round played
        players[_pid].lastRound = currRID;
    }
    
    /**
     * @dev updates 'cumu' in Round and PlayerRound upon tx.
     * DOES NOT UPDATE DIVI POT.
     * @param _pid PID
     * @param _amount Total paid amount
     * @param _keys Purchased # of A keys
     * @return trivial error left over 
     */
    function _updateCumus(uint256 _pid, uint256 _amount, uint256 _keys)
        private
    {
        _amount = _amount.mul(AREWARDPERCENT) / 100;
        // calc profit per key & round cumu based on this buy
        uint256 _ppt = 0;
        if(rounds[currRID].totalAKeys > 0){
            _ppt  = _amount / rounds[currRID].totalAKeys;
        }
        rounds[currRID].cumu = _ppt.add(rounds[currRID].cumu);
        // calculate player earnings from their own purchase (only based on the keys just bought)
        // update player cumu
        uint256 _pearn = _ppt.mul(_keys);
        playerRounds[_pid][currRID].cumu = (((rounds[currRID].cumu).mul(_keys)).sub(_pearn)).add(playerRounds[_pid][currRID].cumu);
    } 

     /**
      * @dev Helper function to update round values.
      * @param _account Payer address
      * @param _amount Paid amount
      * @param _aKeys # of A keys
      * @param _bKeys # of B keys
      */
     function _roundUpdate
     (
        address _account, 
        uint256 _amount, 
        uint256 _aKeys, 
        uint256 _bKeys
     ) 
     private 
     hasLaunched
     {
            Round storage currRound = rounds[currRID];
            // assign dividends
            uint256 toDiv = ((_amount).mul(AREWARDPERCENT)) / 100;
            // update A's total dividends 
            // update other round info 
            uint256 newEnd = currRound.end;
            if(_aKeys >= KEYDECIMAL){
                //if purchased a full key
                newEnd = now.add(COUNTDOWN);
            }
            Round memory r = Round({
                cumu: currRound.cumu,
                totalAKeys: (currRound.totalAKeys).add(_aKeys),
                totalBKeys: (currRound.totalBKeys).add(_bKeys),
                pot: (currRound.pot).add(((_amount).mul(BREWARDPERCENT))/100),
                dividends: (currRound.dividends).add(toDiv),
                foundationReserved: (currRound.foundationReserved).add(((_amount).mul(RESERVEDPERCENT))/100),
                lastPlayerReward: (currRound.lastPlayerReward).add(((_amount).mul(LASTPLAYERPERCENT))/100),
                lastPlayer: _account,
                start: currRound.start,
                end: newEnd,
                hasBeenEnded: false                
            });
            rounds[currRID] = r;
            emit NewDividends(toDiv);
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
        view
        hasLaunched 
        returns (uint256, uint256) 
    {
        uint256 ret = 0;
        // dynamic step for approx the result without exceeding gas limit
        uint256 step = (_quantity/lastAKeyPrice)/10;
        uint256 price = lastAKeyPrice;
        if(step < 1) {
            step = 1;
        }
        uint256 rise = step.mul(18);
        while(_quantity.sub(price.mul(step)) >= 1) {
            _quantity = _quantity.sub(price.mul(step));
            price = price.mul((100000).add(rise))/100000;
            ret = ret.add(step);
        }
        // if left money greater than half of the next key price,
        // count as 1
        if(_quantity > price.mul(step)/2) {
            ret = ret.add(step);
            price = price.mul((100000).add(rise))/100000;
        }
        // no way to be lower than 1
        if(ret < 1){
            price = price.mul((100000).add(18))/100000;
        }
        return (ret,price);
     }
     
    /**
     * @dev calculates the number of B keys (decimal=100) given amount of eth in wei. 
     * NOTE: Limits minimum price to 1 to avoid crash.
     * @param _quantity The amount of eth paid
     */
     function BKeysOf(uint256 _quantity)    
        public 
        view
        hasLaunched 
        returns (uint256, uint256) 
    {
        uint256 ret = 0;
        // dynamic step for approx the result without exceeding gas limit
        uint256 step = (_quantity/lastBKeyPrice)/8;
        uint256 price = lastBKeyPrice;
        if(step < 1) {
            step = 1;
        }
        uint256 fall = step.mul(18);
        while(_quantity.sub(price.mul(step)) >= 1) {
            _quantity = _quantity.sub(price.mul(step));
            price = price.mul((100000).sub(fall))/100000; 
            ret = ret.add(step);
        }
        // if left money greater than half of the next key price,
        // count as 1        
        if(_quantity > price.mul(step)/2) {
            ret = ret.add(step);
            price = price.mul((100000).sub(fall))/100000;
        }
        // no way to be lower than 1
        if(ret < 1){
            price = price.mul((100000).sub(18))/100000;
        }
        return (ret,price);
     }
         
    /**
     * @dev Private func. 
     * Ends current round, starts cooling down. 
     * All players' data reset to default.
     * Pays last player reward and B key rewards.
     * Pays A rewards according to cumulated earnings.
     * Foundation withdraw.
     */
    function _endRound() private hasLaunched {
        require(currRID > 0 && now >= rounds[currRID].end);
        // update round info? no, except hasBeenEnded
        
        // do not update curr RID!!
        rounds[currRID].hasBeenEnded = true;
        // ready to claim A, B rewards
        // claim previous earnings as well

        // pay final winner
        checkAndPayLastPlayer();
        //foundation withdraw all eth left
        withdraw(currRID);
    }
    
    /**
     * @dev Private func.
     * Starts a new round.
     * NOTE: not set start to 'now' but the estimated time based on last end.
     */
    function _startRound() private readyToLaunch {
        // do not start until actual launchTime
        // check and return without doing anything if not ready to start
        require((rounds[currRID].end).add(ROUNDINTERVAL) <= now);
        
        // check if last round has ended. If not, need to end last round first
        if((currRID!=0) && (!rounds[currRID].hasBeenEnded)){
            _endRound();
        }
        //update parameters
        currRID = currRID + 1;

        //set a new round
        uint256 newStart;
        // launch the first game or use previous data to set start/end time
        if(currRID > 1){
            newStart = (rounds[currRID-1].end).add(ROUNDINTERVAL);
        }
        else{
            newStart = now;
        }

        rounds[currRID].start = newStart;
        rounds[currRID].end = newStart.add(COUNTDOWN);
        
        lastAKeyPrice = INITAKEYPRICE;
        lastBKeyPrice = INITBKEYPRICE;
        
        emit NewRound(currRID, newStart, rounds[currRID].end);
    }
    
    /**
     * @dev can be called by anyone to withdraw dividends + rewards and bonus balance.
     * Clears balance.
     */
    function withdrawDividends() public hasLaunched {
        //do nothing if not a valid registered player
        if(addrToPID[msg.sender] == 0) return;
        // fetch Player
        uint256 _pid = addrToPID[msg.sender];
        // update player earning
        updatePlayerEarn(_pid, currRID);
        // from cumulated earnings 
        uint256 _earnings = players[_pid].earning;
        if (_earnings > 0) {
            players[_pid].earning = 0;
            (msg.sender).transfer(_earnings);
        }

        emit DividendsPaid(msg.sender, _earnings);
    }
    
    /**
     * @dev Helper func for calculating dividends.
     * Calculates specified round DIVIDENDS only.
     * @return cumulated dividends
     */
    function calcPlayerDivi(uint256 _pid, uint256 _rid)
        public
        view
        returns(uint256)
    {
        return (((rounds[_rid].cumu).mul(playerRounds[_pid][_rid].AKeys)).sub(playerRounds[_pid][_rid].cumu));
    }
        
    /**
     * @dev Moves any uncalc round divi to all-round earning. 
     * Moves previous round B rewards as well.
     * Updates cumus and BKeys for clearing owned rewards.
     * @param _pid PID
     * @param _rid RID
     */
    function updatePlayerEarn(uint256 _pid, uint256 _rid)
        private 
    {
        // dividends
        uint256 _divis = calcPlayerDivi(_pid, _rid);
        if (_divis > 0) {
            // change player total all-round earning
            players[_pid].earning = _divis.add(players[_pid].earning);
            // zero out divi earning by updating cumu
            playerRounds[_pid][_rid].cumu = _divis.add(playerRounds[_pid][_rid].cumu);
        }
        if(rounds[_rid].hasBeenEnded){
            // B rewards
            Round storage r = rounds[_rid];
            PlayerRound storage pr = playerRounds[_pid][_rid];
            uint256 rewards;
            if(r.totalBKeys == 0){
                rewards = 0;
            }
            else {
                rewards = (r.pot).mul(pr.BKeys) / (r.totalBKeys);
            }   
            // clears B keys
            playerRounds[_pid][_rid].BKeys = 0;
            players[_pid].earning = rewards.add(players[_pid].earning);
        }
    }
    
    /**
     * @dev For front end to get total player earning.
     * @return round cumulated dividends + earning
     */
    function getPlayerEarning() public view returns(uint256) {
        uint256 pid = addrToPID[msg.sender];
        return (players[pid].earning).add(calcPlayerDivi(pid, currRID));
    }
    
    /**
     * @dev for players to claim their final B rewards after game ends.
     * NOTE: dividends in this round will be claimed AS WELL !!
     * Sends the ALL earnings to players.
     * Rewards paid at final stage of each round.
     * @return B rewards
     */
    function claimRewards() public hasLaunched returns(uint256){
        //do nothing if not a valid registered player
        require(addrToPID[msg.sender] >= 1);
        
        Round storage r = rounds[currRID];
        //do nothing if the current round has not ended
        if(!r.hasBeenEnded) {
            return;
        }
        // fetch Player
        uint256 _pid = addrToPID[msg.sender];
        
        PlayerRound storage pr = playerRounds[_pid][currRID];
        uint256 rewards;
        if(r.totalBKeys == 0){
            rewards = 0;
        }
        else {
            rewards = (r.pot).mul(pr.BKeys) / (r.totalBKeys);
        }   
        // clears B keys
        playerRounds[_pid][currRID].BKeys = 0;
        
        // add cumulated dividends as well
        updatePlayerEarn(_pid, currRID);
        uint256 _earnings = players[_pid].earning;
        if (_earnings > 0) {
            players[_pid].earning = 0;
        }
        
        rewards = rewards.add(_earnings);
        // actually pays the player automatically!
        (msg.sender).transfer(rewards);
         emit RewardsClear(msg.sender, rewards);
         return rewards;
    }
    
    
    /**
     * @dev Checks if the last player is eligible for last-player reward.
     * If so, pay the player.
     */
     function checkAndPayLastPlayer() private hasLaunched {
        // check if last round has ended. If not, need to end last round first
        require(rounds[currRID].hasBeenEnded);
        
        Round storage r = rounds[currRID];
        PlayerRound storage last = playerRounds[addrToPID[r.lastPlayer]][currRID];
        Player storage p = players[addrToPID[r.lastPlayer]];
        if(last.lastAKeys >= KEYDECIMAL){
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

