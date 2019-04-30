var EticaBosoms = artifacts.require("./EticaBosoms.sol");

// test suite
contract('EticaBosoms', function(accounts){
  var eticaBosomsInstance;
  var coinbaseuser = accounts[0];
  var eptestusersa = accounts[1];
  var eptestusersb = accounts[2];
  var eptestusersc = accounts[3];
  var eptestusersd = accounts[4];
  var eptestuserse = accounts[5];
  var eptestusersf = accounts[6];
  var eptestusersg = accounts[7];
  var eptestusersh = accounts[8];
  var eptestusersi = accounts[9];


  var oldbalancecoinbase = accounts[0];
  var oldbalancea = accounts[1];
  var oldbalanceb = accounts[2];
  var oldbalancec = accounts[3];
  var oldbalanced = accounts[4];
  var oldbalancee = accounts[5];
  var oldbalancef = accounts[6];
  var oldbalanceg = accounts[7];
  var oldbalanceh = accounts[8];
  var oldbalancei = accounts[9];

  var i;


  it("supply must equal initial supply 618033980 ETI", function() {
    return EticaBosoms.deployed().then(function(instance){
      eticaBosomsInstance = instance;
      return eticaBosomsInstance.totalSupply();
    }).then(function(receipt){
      // supply must equal initial supply
      console.log(receipt.toString());
      assert.equal(web3.utils.fromWei(receipt, "ether" ), "618033980", "supply must equal 618033980.000000000000000000");
    })
  });

  it("centuryreward should equal 381966020 ETI and weeklyreward should equal 73253.697051755847871906 ETI", function() {
    return EticaBosoms.deployed().then(function(instance){
      eticaBosomsInstance = instance;
      return eticaBosomsInstance.centuryreward();
    }).then(function(receipt){
      // century reward must equal 381966020 ETI
      console.log(receipt.toString());
      assert.equal(web3.utils.fromWei(receipt, "ether" ), "381966020", "centuryreward must equal 381966020.000000000000000000" + receipt.toString());
      return eticaBosomsInstance.weeklyreward();
    }).then(function(resp){
      // weekly reward must equal 73253.697051755847871906 ETI
      console.log(resp.toString());
      assert.equal(web3.utils.fromWei(resp, "ether" ), "73253.697051755847871906", "weeklyreward must equal 73253.697051755847871906, not:" + resp.toString());
    })
  });


  it("founder should have 49442718.4 ETI (8% of initial supply)", function() {
    return EticaBosoms.deployed().then(function(instance){
      eticaBosomsInstance = instance;
      return eticaBosomsInstance.founder();
    }).then(function(founder){
      return eticaBosomsInstance.balanceOf(founder);
    }).then(function(founderbalance){
      // founder must have 8% of the initial token supply
      console.log("checking founder balance is 8% of initial supply");
      assert.equal(web3.utils.fromWei(founderbalance, "ether" ), "49442718.4", "the founder account should have 49442718,4 ETI! Instead it has -> " + web3.utils.fromWei(founderbalance, "ether" ));
      console.log("checked founder balance 8% of initial supply ok:", web3.utils.fromWei(founderbalance, "ether" ));
    })
  });

  it("contract balance must equal the initial supply minus the founder's balance", function() {
    let balance_founder;
    let etica_initialsupply;
    let supplyminusfounder;
    return EticaBosoms.deployed().then(function(instance){
      eticaBosomsInstance = instance;
      return eticaBosomsInstance.founder();
    }).then(function(founder){
      return eticaBosomsInstance.balanceOf(founder);
    }).then(function(founderbalance){
      balance_founder = founderbalance;
      return eticaBosomsInstance.supply();
    }).then(function(supply){
      etica_initialsupply = supply;
      supplyminusfounder = supply - balance_founder;
      return eticaBosomsInstance.balanceOf(eticaBosomsInstance.address);
    }).then(function(contractbalance){
      // Contract balance should be equal to supply minus founder balance:
      assert.equal(contractbalance, supplyminusfounder, "contract balance should equal initialsupply minus founderbalance ->" + supplyminusfounder);
      console.log('checked contract balance success -> contract balance is: ', web3.utils.fromWei(contractbalance, "ether" ), 'ETI');
    })
  });

  it("all balances except founder and contract must be at 0 ETI", function() {
    for (i = 1; i < 10; i++) {
    return EticaBosoms.deployed().then(function(instance){
      eticaBosomsInstance = instance;
      return eticaBosomsInstance.balanceOf(accounts[i]);
    }).then(function(receipt){
      // supply must equal initial supply
      assert.equal(web3.utils.fromWei(receipt, "ether" ), 0x0, "this account should not have any ETI! index of accounts is:" + i);
    })
    }
  });

});
