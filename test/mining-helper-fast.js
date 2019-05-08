//var sha3_256 = require('js-sha3').sha3_256;

var solidityHelper = require('./solidity-helper')

var leftpad =  require('leftpad');

const BN = require('bn.js');


module.exports =  {



  async init(web3, contract, mining_account,networkInterface)
  {
    tokenContract = contract;

    this.networkInterface = networkInterface;


    this.testMode = false;
    this.debugMode = false;

    this.mining=true;
    this.triesThisCycle = 0;


    var eth_account  = mining_account;


    setInterval(function(){ this.printMiningStats()}.bind(this), 5000)

      var index = 0;

      var self = this;

      //var difficulty = miningDifficulty;
    //  var challenge_number = challengeNumber;
      var minerEthAddress = eth_account.address;

      let contractData = {}; //passed around as a reference and edited globally

      await self.collectDataFromContract(contractData);

     function mineStuff(contractData){
       //console.log('mine stuff')


          if( self.mining){
            self.mineCoins(web3, contractData,minerEthAddress )
            self.triesThisCycle+=1;

            index++;
            setTimeout(function(){mineStuff(contractData)},0)
          }
      }

      setInterval(function(){self.collectDataFromContract(contractData)},10000);

      console.log("Mining for  "+ minerEthAddress)
      console.log("contractData Target  "+ contractData.miningTarget)
      mineStuff( contractData );



  },

  async collectDataFromContract(contractData)
  {


    console.log('collecting data from smartcontract');



    var lastRewardAmountString = await tokenContract.lastRewardAmount.call()  ;
    var lastRewardAmount = parseInt(lastRewardAmountString)


    var miningDifficultyString = await tokenContract.getMiningDifficulty.call()  ;
    var miningDifficulty = parseInt(miningDifficultyString)

    var miningTargetString = await tokenContract.getMiningTarget.call()  ;
    var miningTarget = web3.utils.toBN(miningTargetString)

    var challengeNumber = await tokenContract.getChallengeNumber.call() ;

    console.log('lastRewardAmount:', lastRewardAmount);
    console.log('difficulty:', miningDifficulty);
    console.log('target:', miningTarget);
    console.log('challenge number:', challengeNumber)

    contractData.miningDifficulty= miningDifficulty;
      contractData.challengeNumber= challengeNumber;
      contractData.miningTarget= miningTarget;


    return contractData;

  },

  async submitNewMinedBlock( addressFrom, solution_number,digest_bytes,challenge_number)
  {
     console.log('Submitting block for reward')
     console.log(solution_number,digest_bytes)

     this.networkInterface.queueMiningSolution( addressFrom, solution_number , digest_bytes , challenge_number)




  },



  /*
  The challenge word will be...

  //we have to find the latest mining hash by asking the contract

  sha3( challenge_number , minerEthAddress , solution_number )


  */
  mineCoins(web3, contractData , minerEthAddress)
  {
      //may need a second solution_number !!

             var solution_numbera = web3.utils.randomHex(32)  //solution_number like bitcoin
             var solution_numberb = web3.utils.randomHex(32)  //solution_number like bitcoin
             var solution_numberc = web3.utils.randomHex(32)  //solution_number like bitcoin

             var challenge_number = contractData.challengeNumber;
             var target = contractData.miningTarget;

              var digesta =  web3.utils.soliditySha3( challenge_number , minerEthAddress, solution_numbera )
              var digestb =  web3.utils.soliditySha3( challenge_number , minerEthAddress, solution_numberb )
              var digestc =  web3.utils.soliditySha3( challenge_number , minerEthAddress, solution_numberc )


            //  console.log(web3.utils.hexToBytes('0x0'))
            var digestBytes32a = web3.utils.hexToBytes(digesta)
              var digestBigNumbera = web3.utils.toBN(digesta)

              var digestBytes32b = web3.utils.hexToBytes(digestb)
                var digestBigNumberb = web3.utils.toBN(digestb)

                var digestBytes32c = web3.utils.hexToBytes(digestc)
                  var digestBigNumberc = web3.utils.toBN(digestc)


          //  console.log('digestBytes32',digestBytes32);

        //  var digestBytes32 = solidityHelper.stringToSolidityBytes32(digest);


          // digestBytes32 is 64 characters, 32 bytes.  Every 2 characters is a byte!

            //  var zeroesCount = this.countZeroBytesInFront(digestBytes32)

            //  console.log(trimmedDigestBytes32)

            // var miningTargetString =  '2.6959946667150639794667015087019630673637144422540572481103610249216e+67' ;
             var miningTarget = web3.utils.toBN(target).mul(new BN(1)) ;


             //should make difficulty about 2^4 times easier !!




            //  console.log('digestBigNumber',digestBigNumber.toString())
              // console.log('miningTarget',miningTarget.toString())

   // --- CHECK SOLUTION_NUMBERA
                 if ( digestBigNumbera.lt(miningTarget) )
                 {


                    console.log(minerEthAddress)
                     console.log('------')
                     console.log(solution_numbera)
                      console.log(challenge_number)
                        console.log(solution_numbera)
                    console.log('------')
                     console.log( web3.utils.bytesToHex(digestBytes32a))
                 }
                 else{
                   // console.log('miningTarget still higher Try again !')
                 }


             if ( digestBigNumbera.lt(miningTarget)  )
             {
               //pass in digest bytes or trimmed ?

               if(this.testMode){
                 this.mining = false;

                 this.networkInterface.checkMiningSolution( minerEthAddress, solution_numbera , web3.utils.bytesToHex( digestBytes32a ),challenge_number,miningTarget,
                   function(result){
                    console.log('checked mining soln:' ,result)
                  })
              }else {
                console.log('submit mined solution with challenge ', challenge_number)
                console.log('submit mined solution with solution ', solution_numbera)
                this.submitNewMinedBlock( minerEthAddress, solution_numbera,   web3.utils.bytesToHex( digestBytes32a ) , challenge_number);
              }
             }

   // --- CHECK SOLUTION_NUMBERB
             if ( digestBigNumberb.lt(miningTarget) )
             {


                console.log(minerEthAddress)
                 console.log('------')
                 console.log(solution_numberb)
                  console.log(challenge_number)
                    console.log(solution_numberb)
                console.log('------')
                 console.log( web3.utils.bytesToHex(digestBytes32b))
             }


         if ( digestBigNumberb.lt(miningTarget)  )
         {
           //pass in digest bytes or trimmed ?

           if(this.testMode){
             this.mining = false;

             console.log('checking mined solution with challenge ', challenge_number)
             console.log('checking mined solution with solution ', solution_numberb)

             this.networkInterface.checkMiningSolution( minerEthAddress, solution_numberb , web3.utils.bytesToHex( digestBytes32b ),challenge_number,miningTarget,
               function(result){
                console.log('checked mining soln:' ,result)
              })
          }else {
            console.log('submit mined solution with challenge ', challenge_number)
            console.log('submit mined solution with solution ', solution_numberb)
            this.submitNewMinedBlock( minerEthAddress, solution_numberb,   web3.utils.bytesToHex( digestBytes32b ) , challenge_number);
          }
         }


   // --- CHECK SOLUTION_NUMBERC
         if ( digestBigNumberc.lt(miningTarget) )
         {


            console.log(minerEthAddress)
             console.log('------')
             console.log(solution_numberc)
              console.log(challenge_number)
                console.log(solution_numberc)
            console.log('------')
             console.log( web3.utils.bytesToHex(digestBytes32c))
         }


     if ( digestBigNumberc.lt(miningTarget)  )
     {
       //pass in digest bytes or trimmed ?

       if(this.testMode){
         this.mining = false;

         this.networkInterface.checkMiningSolution( minerEthAddress, solution_numberc , web3.utils.bytesToHex( digestBytes32c ),challenge_number,miningTarget,
           function(result){
            console.log('checked mining soln:' ,result)
          })
      }else {
        console.log('submit mined solution with challenge ', challenge_number)
        console.log('submit mined solution with solution ', solution_numberc)
        this.submitNewMinedBlock( minerEthAddress, solution_numberc,   web3.utils.bytesToHex( digestBytes32c ) , challenge_number);
      }
     }


  },

  countZeroBytesInFront(array)
  {
    var zero_char_code = '30'

    var char;
    var count = 0;
    var length = array.length;

    for(var i=0;i<array.length;i+=1)
    {
      if(array[i] === 0)
      {
        count++;
      }else{
        break
      }
    }

    return count;

  },

  countZeroCharactersInFront(s)
  {
    var zero_char_code = '30'

    var char;
    var count = 0;
    var length = s.length;

    for(var i=0;i<s.length;i+=2)
    {
      if(s.substring(i,i+2) === zero_char_code)
      {
        count++;
      }else{
        break
      }
    }

    return count;

  },


  getRandomInt(max) {
    return Math.floor(Math.random() * Math.floor(max));
  },

  printMiningStats()
  {
    console.log('Hash rate:',  this.triesThisCycle / 5);
    this.triesThisCycle = 0;
  }



}