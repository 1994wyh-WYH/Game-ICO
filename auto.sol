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
    
      /**
      * @dev Integer division of two numbers, truncating the quotient.
      * Returns the first value if requirement doesn't hold.
      */
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        if(b <= 0) return 0;
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

library Util {
    function toBytes(address a) internal constant returns (bytes b){
    assembly {
        let m := mload(0x40)
        mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
        mstore(0x40, add(m, 52))
        b := m
   }
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
    
    //NOTE: 10 key units = 1 actual key for purchase
    // 0.18% up per new actual key => 0.018% per key uint
    // 0.01 ETH per A key => 0.001 ETH per A key unit
    uint256 public initAKeyPrice = 1000000000000000; 
    // 0.18% down per new actual key => 0.018% per key uint
    // 0.1 ETH per B key => 0.01 ETH per B key unit
    uint256 public initBKeyPrice = 10000000000000000; 
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
    
    // 10 key units = 1 actual key
    uint256 public keyDecimal = 10; 

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
    
    mapping (bytes => uint256) referBonus;
   
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
    function () public payable hasLaunched checkBoundaries(msg.value) {
        // do nothing before actual launch of the game
        // deal with the received payment
        uint256 _pid = addrToPID[msg.sender];

        // 2 scenarios: last round has ended; you are still in a round
        ////////////////////////////////////////////////////////////////////////
        // last round ended, or during cooling down
        if(isCurrRoundEnded()){
            // end round
            if(!rounds[currRID].hasBeenEnded){
                _endRound();
            }
            if(now >= (rounds[currRID].end).add(roundInterval)){
                _startRound();
                // deal with extreme cases -- empty rounds
                while(now >= rounds[currRID].end){
                    _endRound();
                    if(now >= (rounds[currRID].end).add(roundInterval)){
                        _startRound();
                    }
                }
                _updateAndRecalc(msg.sender, msg.value);
                // update referrer bonus
                // address referrer = _convertToAddr(msg.data);
                _addReferBonus(msg.data, msg.value);
            }
            else{
                // do nothing
            }
        }
        ////////////////////////////////////////////////////////////////////////
        //if hasn't ended yet, that is, curr round still active
        else{
            // update and pay. A Keys updated here
            
            // calc keys. Only called once per payment
            uint256 _aKeys;
            (_aKeys, lastAKeyPrice)= AKeysOf(msg.value);

            // give B keys with the curr value of the same amount of money paid
            uint256 _bKeys;
            (_bKeys,lastBKeyPrice) = BKeysOf(msg.value);
 
            // player is new
            if(_pid == 0){
                lastPID ++;
                Player memory p = Player ({
                    PID: lastPID,
                    account: msg.sender
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
                addrToPID[msg.sender] = p.PID;
            }
            // player exists in record
            else{
                PlayerRound storage pr2 = playerRounds[_pid][currRID];
                PlayerRound memory pr3 = PlayerRound ({
                    PID: _pid,
                    RID: currRID,
                    AKeys: (pr2.AKeys).add(_aKeys),
                    BKeys: (pr2.BKeys).add(_bKeys),
                    lastAKeys: _aKeys,
                    claimedAEarning: pr2.claimedAEarning,
                    initTotalDivi: pr2.initTotalDivi
                });
                playerRounds[_pid][currRID] = pr3;
            }
            
            // update round info
            Round storage currRound = rounds[currRID];
            // update A's total dividends 
            // update other round info 
            // update round end time
            uint256 newEnd = currRound.end;
            if(_aKeys >= keyDecimal){
                //if purchased a full key
                if(countdown < ((currRound.end).sub(now)).add(_aKeys.mul(increaseStep).div(100))){
                    newEnd = now.add(countdown);
                }
                else{
                    newEnd = (currRound.end).add(_aKeys.mul(increaseStep).div(100));
                }
                emit EndUpdate(newEnd);
            }
            Round memory r = Round({
                RID: currRID,
                totalAKeys: (currRound.totalAKeys).add(_aKeys),
                totalBKeys: (currRound.totalBKeys).add(_bKeys),
                pot: (currRound.pot).add(((msg.value).mul(BRewardPercent)).div(100)),
                dividends: (currRound.dividends).add(((msg.value).mul(ARewardPercent)).div(100)),
                foundationReserved: (currRound.foundationReserved).add(((msg.value).mul(reservedPercent)).div(100)),
                lastPlayerReward: (currRound.lastPlayerReward).add(((msg.value).mul(lastPlayerPercent)).div(100)),
                lastPlayer: msg.sender,
                start: currRound.start,
                end: newEnd,
                hasBeenEnded: false                
            });
            rounds[currRID] = r;
            emit NewDividends(r.dividends);
            emit PotIncr(currRound.pot);
            
            // update referrer bonus
            // referrer = _convertToAddr(msg.data);
            _addReferBonus(msg.data, msg.value);
        }
        
        // UI catch and deal with payment
        emit PaymentReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev private helper checking if referrer is valid.
     * @param data TX optional data
     * @return the converted address, 0 if not valid.
     */
     function _convertToAddr(bytes data) private view returns(address) {
         bytes32 out;
         for (uint i = 0; i < 32; i++) {
            out |= bytes32(data[i] & 0xFF) >> (i * 8);
         }
         address toTest = address(out);
         if(addrToPID[toTest] > 0){
             return toTest;
         }
         else{
             return address(0x0);
         }
     }
    
    /**
     * @dev private helper for adding referral bonus
     * @param referrer Actually the raw data the payer passed in but no big difference.
     * @param amount Amount that the referee sent to contract.
     */
    function _addReferBonus(bytes referrer, uint256 amount) private hasLaunched {
        // require(addrToPID[referrer] > 0); // already checked
        referBonus[referrer] = amount.mul(5).div(100);
    }
    
    /**
     * @dev Helper for dealing with any incoming tx.
     * @param sender The payer
     * @param value The amount sent to contract
     */
    function dealWithPay(address sender, uint256 value) 
        private 
        hasLaunched 
    {
        // for time consistency throughout the function
        uint256 _now = now;

        // 2 scenarios: last round has ended; you are still in a round
        // NOTE: numbers of keys bought are calculated differently upon diff scenarios
        ////////////////////////////////////////////////////////////////////////
        // last round ended
        if(isCurrRoundEnded()){
            // foundation reserve in endround()
            // NOTE: currRound changes
            uint256 lastEnd = rounds[currRID].end;
            if(!rounds[currRID].hasBeenEnded){
                _endRound();
            }
            
            if (_now >= lastEnd.add(roundInterval)) {
                // has ended and passed cooling down but not yet started a new round
                // End curr round
                // Start a new round!
                _startRound();
                _updateAndRecalc(sender, value);
            }
            else{
                //do nothing during cool down time. Payments ignored.
            }
        }
        ////////////////////////////////////////////////////////////////////////
        //if hasn't ended yet, that is, curr round still active
        else{
        
            // update and pay. A Keys updated here
            _updateAndRecalc(sender, value);
            // update round end time
            PlayerRound storage pr = playerRounds[addrToPID[sender]][currRID];
            uint256 aKeys2 = pr.lastAKeys;
            if(aKeys2 >= keyDecimal){
                //if purchased a full key
                Round storage currRound2 = rounds[currRID];
                uint256 newEnd;
                if(countdown < ((currRound2.end).sub(_now)).add(aKeys2.mul(increaseStep).div(100))){
                    newEnd = _now.add(countdown);
                }
                else{
                    newEnd = (currRound2.end).add(aKeys2.mul(increaseStep).div(100));
                }
                Round memory r = Round({
                    RID: currRID,
                    totalAKeys: currRound2.totalAKeys,
                    totalBKeys: currRound2.totalBKeys,
                    pot: currRound2.pot,
                    dividends: currRound2.dividends,
                    foundationReserved: currRound2.foundationReserved,
                    lastPlayerReward: currRound2.lastPlayerReward,
                    lastPlayer: currRound2.lastPlayer,
                    start: currRound2.start,
                    end: newEnd,
                    hasBeenEnded: false
                });
                rounds[currRID] = r;
                emit EndUpdate(newEnd);
            }
            else{
                // if not a full actual key
                // no update of end time
            }
        }
    }
    
    
    /**
     * @dev Helper function to update round info upon payment.
     * Not included end time update!
     * @param _account The account made the payment
     * @param _amount Amount of the payment
     */
     function _updateAndRecalc(address _account, uint256 _amount) 
        private 
        hasLaunched 
     {
            uint256 _pid = addrToPID[_account];
            // calc keys. Only called once per payment
            uint256 _aKeys;
            (_aKeys, lastAKeyPrice)= AKeysOf(_amount);
            // give B keys with the curr value of the same amount of money paid
            uint256 _bKeys;
            (_bKeys, lastBKeyPrice)= BKeysOf(_amount); 
            
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
                PlayerRound storage pr2 = playerRounds[_pid][currRID];
                PlayerRound memory pr3 = PlayerRound ({
                    PID: _pid,
                    RID: currRID,
                    AKeys: (pr2.AKeys).add(_aKeys),
                    BKeys: (pr2.BKeys).add(_bKeys),
                    lastAKeys: _aKeys,
                    claimedAEarning: pr2.claimedAEarning,
                    initTotalDivi: pr2.initTotalDivi
                });
                playerRounds[_pid][currRID] = pr3;
            }
            
            // update round info
            _roundUpdate(_account, _amount, _aKeys, _bKeys);
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
            uint256 toPay = ((_amount).mul(ARewardPercent)).div(100);
            // update A's total dividends 
            // update other round info 
            Round memory r = Round({
                RID: currRID,
                totalAKeys: (currRound.totalAKeys).add(_aKeys),
                totalBKeys: (currRound.totalBKeys).add(_bKeys),
                pot: (currRound.pot).add(((_amount).mul(BRewardPercent)).div(100)),
                dividends: (currRound.dividends).add(toPay),
                foundationReserved: (currRound.foundationReserved).add(((_amount).mul(reservedPercent)).div(100)),
                lastPlayerReward: (currRound.lastPlayerReward).add(((_amount).mul(lastPlayerPercent)).div(100)),
                lastPlayer: _account,
                start: currRound.start,
                end: currRound.end,
                hasBeenEnded: false                
            });
            rounds[currRID] = r;
            emit NewDividends(toPay);
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
        uint256 step = _quantity.div(lastAKeyPrice).div(10);
        uint256 price = lastAKeyPrice;
        if(step < 1) {
            step = 1;
        }
        uint256 rise = step.mul(18);
        while(_quantity.sub(price.mul(step)) >= 1) {
            _quantity = _quantity.sub(price.mul(step));
            price = price.mul((100000).add(rise)).div(100000);
            ret = ret.add(step);
        }
        // if left money greater than half of the next key price,
        // count as 1
        if(_quantity > price.mul(step).div(2)) {
            ret = ret.add(step);
            price = price.mul((100000).add(rise)).div(100000);
        }
        // no way to be lower than 1
        if(ret < 1){
            price = price.mul((100000).add(18)).div(100000);
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
        uint256 step = _quantity.div(lastBKeyPrice).div(8);
        uint256 price = lastBKeyPrice;
        if(step < 1) {
            step = 1;
        }
        uint256 fall = step.mul(18);
        while(_quantity.sub(price.mul(step)) >= 1) {
            _quantity = _quantity.sub(price.mul(step));
            price = price.mul((100000).sub(fall)).div(100000); 
            ret = ret.add(step);
        }
        // if left money greater than half of the next key price,
        // count as 1        
        if(_quantity > price.mul(step).div(2)) {
            ret = ret.add(step);
            price = price.mul((100000).sub(fall)).div(100000);
        }
        // no way to be lower than 1
        if(ret < 1){
            price = price.mul((100000).sub(18)).div(100000);
        }
        return (ret,price);
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
        Round storage currRound = rounds[currRID];
        Round memory r = Round ({
            RID: currRID,
            totalAKeys: currRound.totalAKeys,
            totalBKeys: currRound.totalBKeys,
            pot: currRound.pot,
            dividends: currRound.dividends,
            foundationReserved: currRound.foundationReserved,
            lastPlayerReward: currRound.lastPlayerReward,
            lastPlayer: currRound.lastPlayer,
            start: currRound.start,
            end: currRound.end,
            hasBeenEnded: true
        });
        rounds[currRID] = r;
        
        // ready to claim B rewards
        // claim dividends as you want
        
        // pay final winner
        checkAndPayLastPlayer();
       
        //foundation withdraw all eth left
        withdraw(currRID);
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
        Round storage currRound = rounds[currRID];
        Round memory r = Round ({
            RID: currRID,
            totalAKeys: currRound.totalAKeys,
            totalBKeys: currRound.totalBKeys,
            pot: currRound.pot,
            dividends: currRound.dividends,
            foundationReserved: currRound.foundationReserved,
            lastPlayerReward: currRound.lastPlayerReward,
            lastPlayer: currRound.lastPlayer,
            start: currRound.start,
            end: currRound.end,
            hasBeenEnded: true
        });
        rounds[currRID] = r;
        
        // ready to claim B rewards
        // claim dividends as you want
        
        // pay final winner
        checkAndPayLastPlayer();
       
        //foundation withdraw all eth left
        withdraw(currRID);
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
        
        lastAKeyPrice = initAKeyPrice;
        lastBKeyPrice = initBKeyPrice;
        
        emit NewRound(r.RID, r.start, r.end);
    }
    
    /**
     * @dev Private func.
     * Starts a new round.
     * NOTE: not set start to 'now' but the estimated time based on last end.
     */
    function _startRound() private readyToLaunch {
        // do not start until actual launchTime
        // check and return without doing anything if not ready to start
        require((rounds[currRID].end).add(roundInterval) <= now || currRID == 0);
        
        // check if last round has ended. If not, need to end last round first
        if((currRID!=0) && (!rounds[currRID].hasBeenEnded)){
            endRound();
        }
        //update parameters
        currRID = currRID.add(1);

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
        
        lastAKeyPrice = initAKeyPrice;
        lastBKeyPrice = initBKeyPrice;
        
        emit NewRound(r.RID, r.start, r.end);
    }
    
    /**
     * @dev can be called by anyone to withdraw dividends balance.
     * Clears balance.
     * @param _rid Round ID from which the dividends to be withdraw.
     */
    function withdrawDividends(uint256 _rid) public hasLaunched {
        //do nothing if not a valid registered player
        if(addrToPID[msg.sender] == 0) return;
        
        // fetch Player
        PlayerRound storage pr = playerRounds[addrToPID[msg.sender]][_rid];
        //fetch round
        Round storage r = rounds[_rid]; //view, no need to be memory
        
        // calc current earning
        // check claimed earning >= current 
        
        // currrent earn 
        // = # of A Keys * (total curr divi - init divi when player entered game)
        // / total current A keys
        uint256 currEarn = (pr.AKeys).mul((r.dividends).sub(pr.initTotalDivi)).div(r.totalAKeys);
        uint256 toSend = currEarn.sub(pr.claimedAEarning); // for proper serialization
        // add referral bonus as well
        toSend = toSend.add(referBonus[msg.sender.toBytes()]);
        if(toSend > 0){
            PlayerRound memory pr2 = PlayerRound ({
                PID: pr.PID,
                RID: _rid,
                AKeys: pr.AKeys,
                BKeys: pr.BKeys,
                lastAKeys: pr.lastAKeys,
                claimedAEarning: pr.claimedAEarning.add(toSend),
                initTotalDivi: pr.initTotalDivi
            });
            playerRounds[addrToPID[msg.sender]][_rid] = pr2;
            // make actual tx
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
        PlayerRound storage pr = playerRounds[addrToPID[msg.sender]][_rid];
        uint256 rewards = (r.pot).mul(pr.BKeys).div(r.totalBKeys);
        pr.BKeys = 0;
        
        uint256 currEarn = (pr.AKeys).mul((r.dividends).sub(pr.initTotalDivi)).div(r.totalAKeys);
        uint256 toSend = currEarn.sub(pr.claimedAEarning); // for proper serialization
        
        PlayerRound memory pr2 = PlayerRound ({
            PID: pr.PID,
            RID: _rid,
            AKeys: pr.AKeys,
            BKeys: 0,
            lastAKeys: pr.lastAKeys,
            claimedAEarning: pr.claimedAEarning.add(toSend),
            initTotalDivi: pr.initTotalDivi
        });
        playerRounds[addrToPID[msg.sender]][_rid] = pr2;
        
        rewards = rewards.add(toSend);
        // actually pays the player automatically!
        (msg.sender).transfer(rewards);
         emit RewardsClear(msg.sender, rewards);
    }
    
    
    /**
     * @dev Checks if the last player is eligible for last-player reward.
     * If so, pay the player.
     */
     function checkAndPayLastPlayer() public hasLaunched {
        // check if last round has ended. If not, need to end last round first
        require(rounds[currRID].hasBeenEnded);
        
        Round storage r = rounds[currRID];
        PlayerRound storage last = playerRounds[addrToPID[r.lastPlayer]][currRID];
        Player storage p = PIDToPlayers[last.PID];
        if(last.lastAKeys >= keyDecimal){
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

