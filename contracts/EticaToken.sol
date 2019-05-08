pragma solidity ^0.5.2;
// ----------------------------------------------------------------------------
//this ICO smart contract has been compiled and tested with the Solidity Version 0.5.2
//There are some minor changes comparing to ICO contract compiled with versions < 0.5.0
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------

// Safe maths

// ----------------------------------------------------------------------------

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {

        c = a + b;

        require(c >= a);

    }

    function sub(uint a, uint b) internal pure returns (uint c) {

        require(b <= a);

        c = a - b;

    }

    function mul(uint a, uint b) internal pure returns (uint c) {

        c = a * b;

        require(a == 0 || c / a == b);

    }

    function div(uint a, uint b) internal pure returns (uint c) {

        require(b > 0);

        c = a / b;

    }

}



library ExtendedMath {


    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {

        if(a > b) return b;

        return a;

    }
}



contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);


    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



// -------- Mining system ----------------  //
// ----------------------------------------------------------------------------

// Contract function to receive approval and execute function in one call

//

// Borrowed from MiniMeToken

// ----------------------------------------------------------------------------

contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;

}

// ---------- Mining system ------------ //

contract EticaToken is ERC20Interface{

    using SafeMath for uint;
    using ExtendedMath for uint;

    string public name = "Etica";
    string public symbol = "ETI";
    uint public decimals = 18;

    uint public supply;
    // fixed inflation rate after etica supply has reached 21 Million
    uint public inflationrate;
    int public  periodrewardtemp; // Amount of ETI issued per period during phase1

    // We don't want fake Satoshi again. Using it to prove founder's identity
    address public founder;
    string public foundermsgproof;

    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) allowed;

    //allowed[0x1111....][0x22222...] = 100;

    // Mining system state variables
    uint public _totalMiningSupply;



     uint public latestDifficultyPeriodStarted;



    uint public epochCount;//number of 'blocks' mined


    uint public _BLOCKS_PER_READJUSTMENT = 1024;


    //a little number
    uint public  _MINIMUM_TARGET = 2**16;


      //a big number is easier ; just find a solution that is smaller
    //uint public  _MAXIMUM_TARGET = 2**224;  bitcoin uses 224
    uint public  _MAXIMUM_TARGET = 2**242; // used for tests 243 much faster, 242 seems to be the limit where mining gets much harder
    // uint public  _MAXIMUM_TARGET = 2**234; // used for prod


    uint public miningTarget;

    bytes32 public challengeNumber;   //generate a new one when a new reward is minted



    uint public rewardEra;
    uint public maxSupplyForEra;


    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;

    bool locked = false;

    mapping(bytes32 => bytes32) solutionForChallenge;

    uint public tokensMinted;

    // Mining system state variables




    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);


    constructor() public{
      supply = 100 * (10**18); // initial supply equals 100 ETI
      balances[address(this)] = balances[address(this)].add(100 * (10**18)); // 100 ETI as the default contract balance. To avoid any issue that could arise from negative contract balance because of significant numbers approximations


      // PHASE 1 (before 21 Million ETI has been reached) -->

      // 10 500 000 ETI to be issued as periodrewardtemp for ETICA reward system
      // 10 500 000 ETI to be MINED

      // phase1 periodrewardtemp:
      // fixed Etica issued per period during phase1 (before 21 Million ETI has been reached)
      // calculation:
      // The amount of reward will be half of first rewards of phase 2
      // Calculation of first rewards of phase 2:
      // 21 000 000 * 0.26180339887498948482045868343656 = 549 787,13763747791812296323521678‬ ETI (first year reward)
      // 549 787,13763747791812296323521678‬ / 52.1429 = 10 543,854247413893706007207792754‬ ETI (first weeks reward of phase2)
      // 10 543,854247413893706007207792754‬ * 2 = 21087,708494827787412014415585507 ETI
      periodrewardtemp = 21087708494827787412014415585507; // 21087,708494827787412014415585507 ETI per period (7 days) will take about 9,5491502812526287948853291408588 years to reach 10 500 000 ETI



      // phase1 mining:

      _totalMiningSupply = 21000000 * 10**uint(decimals);

      if(locked) revert();
      locked = true;

      tokensMinted = 0;

      rewardEra = 0;
      maxSupplyForEra = _totalMiningSupply.div(2);

      miningTarget = _MAXIMUM_TARGET;

      latestDifficultyPeriodStarted = block.number;

      _startNewMiningEpoch();


      //The owner gets nothing! You must mine this ERC20 token
      //balances[owner] = _totalMiningSupply;
      //Transfer(address(0), owner, _totalMiningSupply);


      // PHASE 1 <--

      // --> PHASE 2
      // Golden number power 2: 1,6180339887498948482045868343656 * 1,6180339887498948482045868343656 = 2.6180339887498948482045868343656; (need to multiple by 10^(-34) to get 0.26180339887498948482045868343656);
      inflationrate = 26180339887498948482045868343656;

       // PHASE 2 <--



      founder = msg.sender;
      foundermsgproof = "Discovering our best Futures. Kevin Wad";
    }


    function allowance(address tokenOwner, address spender) view public returns(uint){
        return allowed[tokenOwner][spender];
    }


    //approve allowance
    function approve(address spender, uint tokens) public returns(bool){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    //transfer tokens from the  owner account to the account that calls the function
    function transferFrom(address from, address to, uint tokens) public returns(bool){

      balances[from] = balances[from].sub(tokens);

      allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

      balances[to] = balances[to].add(tokens);

      emit Transfer(from, to, tokens);

      return true;
    }

    function totalSupply() public view returns (uint){
        return supply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance){
         return balances[tokenOwner];
     }


    function transfer(address to, uint tokens) public returns (bool success){
         require(tokens > 0);

         balances[msg.sender] = balances[msg.sender].sub(tokens);

         balances[to] = balances[to].add(tokens);

         emit Transfer(msg.sender, to, tokens);

         return true;
     }


     // -------------  Mining system functions ---------------- //

         function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {


             //the PoW must contain work that includes a recent ethereum block hash (challenge number) and the msg.sender's address to prevent MITM attacks
             bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

             //the challenge digest must match the expected
             if (digest != challenge_digest) revert();

             //the digest must be smaller than the target
             if(uint256(digest) > miningTarget) revert();


             //only allow one reward for each challenge
              bytes32 solution = solutionForChallenge[challengeNumber];
              solutionForChallenge[challengeNumber] = digest;
              if(solution != 0x0) revert();  //prevent the same answer from awarding twice


             uint reward_amount = getMiningReward();

             balances[msg.sender] = balances[msg.sender].add(reward_amount);

             tokensMinted = tokensMinted.add(reward_amount);


             //Cannot mint more tokens than there are
             assert(tokensMinted <= maxSupplyForEra);

             //set readonly diagnostics data
             lastRewardTo = msg.sender;
             lastRewardAmount = reward_amount;
             lastRewardEthBlockNumber = block.number;


              _startNewMiningEpoch();

               emit Mint(msg.sender, reward_amount, epochCount, challengeNumber );

            return true;

         }


     //a new 'block' to be mined
     function _startNewMiningEpoch() internal {

       //if max supply for the era will be exceeded next reward round then enter the new era before that happens

       //40 is the final reward era, almost all tokens minted
       //once the final era is reached, more tokens will not be given out because the assert function
       if( tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 39)
       {
         rewardEra = rewardEra + 1;
       }

       //set the next minted supply at which the era will change
       // total supply is 2100000000000000  because of 8 decimal places
       maxSupplyForEra = _totalMiningSupply - _totalMiningSupply.div( 2**(rewardEra + 1));

       epochCount = epochCount.add(1);

       //every so often, readjust difficulty. Dont readjust when deploying
       if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
       {
         _reAdjustDifficulty();
       }


       //make the latest ethereum block hash a part of the next challenge for PoW to prevent pre-mining future blocks
       //do this last since this is a protection mechanism in the mint() function
       challengeNumber = blockhash(block.number - 1);






     }




     //https://en.bitcoin.it/wiki/Difficulty#What_is_the_formula_for_difficulty.3F
     //as of 2017 the bitcoin difficulty was up to 17 zeroes, it was only 8 in the early days

     //readjust the target by 5 percent
     function _reAdjustDifficulty() internal {


         uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
         //assume 360 ethereum blocks per hour

         //we want miners to spend 10 minutes to mine each 'block', about 60 ethereum blocks = one Mining system epoch
         uint epochsMined = _BLOCKS_PER_READJUSTMENT; //256

         uint targetEthBlocksPerDiffPeriod = epochsMined * 60; //should be 60 times slower than ethereum

         //if there were less eth blocks passed in time than expected
         if( ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod )
         {
           uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div( ethBlocksSinceLastDifficultyPeriod );

           uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
           // If there were 5% more blocks mined than expected then this is 5.  If there were 100% more blocks mined than expected then this is 100.

           //make it harder
           miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));   //by up to 50 %
         }else{
           uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div( targetEthBlocksPerDiffPeriod );

           uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000

           //make it easier
           miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));   //by up to 50 %
         }



         latestDifficultyPeriodStarted = block.number;

         if(miningTarget < _MINIMUM_TARGET) //very difficult
         {
           miningTarget = _MINIMUM_TARGET;
         }

         if(miningTarget > _MAXIMUM_TARGET) //very easy
         {
           miningTarget = _MAXIMUM_TARGET;
         }
     }


     //this is a recent ethereum block hash, used to prevent pre-mining future blocks
     function getChallengeNumber() public view returns (bytes32) {
         return challengeNumber;
     }

     //the number of zeroes the digest of the PoW solution requires.  Auto adjusts
      function getMiningDifficulty() public view returns (uint) {
         return _MAXIMUM_TARGET.div(miningTarget);
     }

     function getMiningTarget() public view returns (uint) {
        return miningTarget;
    }



     //21m coins total
     //reward begins at 50 and is cut in half every reward era (as tokens are mined)
     function getMiningReward() public view returns (uint) {
         //once we get half way thru the coins, only get 25 per block

          //every reward era, the reward amount halves.

          return (50 * 10**uint(decimals) ).div( 2**rewardEra ) ;

     }

     //help debug mining software
     function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {

         bytes32 digest = keccak256(abi.encodePacked(challenge_number,msg.sender,nonce));

         return digest;

       }

         //help debug mining software
       function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {

           bytes32 digest = keccak256(abi.encodePacked(challenge_number,msg.sender,nonce));

           if(uint256(digest) > testTarget) revert();

           return (digest == challenge_digest);

         }




     // ------------------------------------------------------------------------

     // Token owner can approve for `spender` to transferFrom(...) `tokens`

     // from the token owner's account. The `spender` contract function

     // `receiveApproval(...)` is then executed

     // ------------------------------------------------------------------------

     function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {

         allowed[msg.sender][spender] = tokens;

         emit Approval(msg.sender, spender, tokens);

         ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);

         return true;

     }



     // ------------------------------------------------------------------------

     // Don't accept ETH

     // ------------------------------------------------------------------------

     function () payable external {

         revert();

     }


// ------------------      Mining system functions   -------------------------  //



}
