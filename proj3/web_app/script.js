// =============================================================================
//                                  Config
// =============================================================================
const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
var defaultAccount;

// Constant we use later
var GENESIS = '0x0000000000000000000000000000000000000000000000000000000000000000';

// This is the ABI for your contract (get it from Remix, in the 'Compile' tab)
// ============================================================
var abi = [
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "address",
          "name": "from",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "address",
          "name": "to",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint32",
          "name": "amount",
          "type": "uint32"
        }
      ],
      "name": "New_IOU",
      "type": "event"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "creditor",
          "type": "address"
        },
        {
          "internalType": "uint32",
          "name": "amount",
          "type": "uint32"
        },
        {
          "internalType": "address[]",
          "name": "path",
          "type": "address[]"
        }
      ],
      "name": "add_IOU",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "debtor",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "creditor",
          "type": "address"
        }
      ],
      "name": "lookup",
      "outputs": [
        {
          "internalType": "uint32",
          "name": "ret",
          "type": "uint32"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    }
  ]; // FIXME: fill this in with your contract's ABI //Be sure to only have one array, not two
// ============================================================
abiDecoder.addABI(abi);
// call abiDecoder.decodeMethod to use this - see 'getAllFunctionCalls' for more

var contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // FIXME: fill this in with your contract's address/hash

var BlockchainSplitwise = new ethers.Contract(contractAddress, abi, provider.getSigner());

// =============================================================================
//                            Functions To Implement
// =============================================================================

// TODO: Add any helper functions here!

// helper function 
// Get all users that owns postive amount to user
async function getNeighbors(user) {
	var ret = [];

	users = await getUsers();
	for (var i = 0; i < users.length; i++) {
		if(users[i] == user) continue;
		var owned = await BlockchainSplitwise.lookup(user, users[i]);
		if  (owned > 0) {
			console.log("find edge from: " + user + ", to: " + users[i])
			ret.push(users[i].toLowerCase());
		}
	}
	return ret;
}

// Return a list of all users (creditors or debtors) in the system
// All users in the system are everyone who has ever sent or received an IOU
// IMPL: loop through all add_IOU() calls and add (from, to) into a set for dedup
async function getUsers() {
	calls = await getAllFunctionCalls(contractAddress, "add_IOU");
	ret = new Set();
	//console.log(calls);
	for (let i = 0; i < calls.length; i++) {
		ret.add(calls[i].from);
		ret.add(calls[i].creditor.value);
	}
	return Array.from(ret);
}

// Get the total amount owed by the user specified by 'user'
// IMPL: loop through all users and accumulate the owned amount
async function getTotalOwed(user) {
	users = await getUsers();
	var ret = 0;
	for (var i = 0; i < users.length; i++) {
		if(users[i] == user) continue;
		var owned = await BlockchainSplitwise.lookup(user, users[i]);
		ret += owned;
	}
	return ret;
}

// Get the last time this user has sent or received an IOU, in seconds since Jan. 1, 1970
// Return null if you can't find any activity for the user.
// HINT: Try looking at the way 'getAllFunctionCalls' is written. You can modify it if you'd like.
async function getLastActive(user) {
	var ret = 0;
	calls = await getAllFunctionCalls(contractAddress, "add_IOU");
	// console.log("==================================================");
	// console.log(user);
	for (let i = 0; i < calls.length; i++) {
		// console.log("calls[i].from " + calls[i].from);
		// console.log("calls[i].creditor.value " + calls[i].creditor.value);
		if (calls[i].from.toLowerCase() === user.toLowerCase() || calls[i].creditor.value.toLowerCase() === user.toLowerCase()) {
			ret = ret > calls[i].t ? ret : calls[i].t;
			//console.log("latest active timestamp udpated: " + ret);
		}
	}
	//console.log("==================================================");
	return ret == 0 ? null : ret;
}

// add an IOU ('I owe you') to the system
// The person you owe money is passed as 'creditor'
// The amount you owe them is passed as 'amount'
async function add_IOU(creditor, amount) {

	console.log("==================================================");
	console.log("add_IOU_from " + defaultAccount);
	console.log("add_IOU_to " + creditor.toLowerCase());
	console.log(provider.getSigner())
	path = await doBFS(creditor.toLowerCase(), defaultAccount.toLowerCase(), getNeighbors);

	if (path == null) {
		console.log("path is []");
		await BlockchainSplitwise
			.connect(provider.getSigner())
			.add_IOU(creditor, amount, []);
	} else {
		console.log("path = " + path);
		await BlockchainSplitwise
			.connect(provider.getSigner())
			.add_IOU(creditor, amount, Array.from(path));
	}
}

// =============================================================================
//                              Provided Functions
// =============================================================================
// Reading and understanding these should help you implement the above

// This searches the block history for all calls to 'functionName' (string) on the 'addressOfContract' (string) contract
// It returns an array of objects, one for each call, containing the sender ('from'), arguments ('args'), and the timestamp ('t')
async function getAllFunctionCalls(addressOfContract, functionName) {
	var curBlock = await provider.getBlockNumber();
	var function_calls = [];

	while (curBlock !== GENESIS) {
	  var b = await provider.getBlockWithTransactions(curBlock);
	  var txns = b.transactions;
	  for (var j = 0; j < txns.length; j++) {
	  	var txn = txns[j];

	  	// check that destination of txn is our contract
		if(txn.to == null){continue;}
	  	if (txn.to.toLowerCase() === addressOfContract.toLowerCase()) {
	  		var func_call = abiDecoder.decodeMethod(txn.data);
				//console.log(func_call);
				// check that the function getting called in this txn is 'functionName'
				if (func_call && func_call.name === functionName) {
					var timeBlock = await provider.getBlock(curBlock);
					var args = func_call.params.map(function (x) {return x.value});
					// console.log("=====================");
					// console.log(txn);
					function_calls.push({
						from: txn.from.toLowerCase(),
						creditor: func_call.params[0],
						args: args,
						t: timeBlock.timestamp
					})
	  		}
	  	}
	  }
	  curBlock = b.parentHash;
	}
	return function_calls;
}

// We've provided a breadth-first search implementation for you, if that's useful
// It will find a path from start to end (or return null if none exists)
// You just need to pass in a function ('getNeighbors') that takes a node (string) and returns its neighbors (as an array)
async function doBFS(start, end, getNeighbors) {
	var queue = [[start]];
	while (queue.length > 0) {
		var cur = queue.shift();
		var lastNode = cur[cur.length-1]
		if (lastNode.toLowerCase() === end.toString().toLowerCase()) {
			return cur;
		} else {
			var neighbors = await getNeighbors(lastNode);
			for (var i = 0; i < neighbors.length; i++) {
				queue.push(cur.concat([neighbors[i]]));
			}
		}
	}
	return null;
}

// =============================================================================
//                                      UI
// =============================================================================

// This sets the default account on load and displays the total owed to that
// account.
provider.listAccounts().then((response)=> {
	defaultAccount = response[0];

	getTotalOwed(defaultAccount).then((response)=>{
		$("#total_owed").html("$"+response);
	});

	getLastActive(defaultAccount).then((response)=>{
		time = timeConverter(response)
		$("#last_active").html(time)
	});
});

// This code updates the 'My Account' UI with the results of your functions
$("#myaccount").change(function() {
	defaultAccount = $(this).val();

	getTotalOwed(defaultAccount).then((response)=>{
		$("#total_owed").html("$"+response);
	})

	getLastActive(defaultAccount).then((response)=>{
		time = timeConverter(response)
		$("#last_active").html(time)
	});
});

// Allows switching between accounts in 'My Account' and the 'fast-copy' in 'Address of person you owe
provider.listAccounts().then((response)=>{
	var opts = response.map(function (a) { return '<option value="'+
			a.toLowerCase()+'">'+a.toLowerCase()+'</option>' });
	$(".account").html(opts);
	$(".wallet_addresses").html(response.map(function (a) { return '<li>'+a.toLowerCase()+'</li>' }));
});

// This code updates the 'Users' list in the UI with the results of your function
getUsers().then((response)=>{
	$("#all_users").html(response.map(function (u,i) { return "<li>"+u+"</li>" }));
});

// This runs the 'add_IOU' function when you click the button
// It passes the values from the two inputs above
$("#addiou").click(function() {
	defaultAccount = $("#myaccount").val(); //sets the default account
  add_IOU($("#creditor").val(), $("#amount").val()).then((response)=>{
		window.location.reload(false); // refreshes the page after add_IOU returns and the promise is unwrapped
	})
});

// This is a log function, provided if you want to display things to the page instead of the JavaScript console
// Pass in a discription of what you're printing, and then the object to print
function log(description, obj) {
	$("#log").html($("#log").html() + description + ": " + JSON.stringify(obj, null, 2) + "\n\n");
}


// =============================================================================
//                                      TESTING
// =============================================================================

// This section contains a sanity check test that you can use to ensure your code
// works. We will be testing your code this way, so make sure you at least pass
// the given test. You are encouraged to write more tests!

// Remember: the tests will assume that each of the four client functions are
// async functions and thus will return a promise. Make sure you understand what this means.

function check(name, condition) {
	if (condition) {
		console.log(name + ": SUCCESS");
		return 3;
	} else {
		console.log(name + ": FAILED");
		return 0;
	}
}

async function sanityCheck2() {
	await sanityCheck()

	console.log ("\nTEST", "start sanityCheck2");
	var score = 0;
	var accounts = await provider.listAccounts();
	defaultAccount = accounts[1];
	
	console.log("defaultAccount: " + defaultAccount);

	const privateKey1 = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
	const signer1 = new ethers.Wallet(privateKey1);
	
	BlockchainSplitwise = new ethers.Contract(contractAddress, abi, signer1);
	await add_IOU(accounts[2], "20");

	var users = await getUsers();
	score += check("getUsers() now length 3", users.length === 3);

	var lookup_1_2 = await BlockchainSplitwise.lookup(accounts[1], accounts[2]);
	console.log("lookup(1, 2) current value " + lookup_1_2);
	score += check("lookup(1,2) now 20", parseInt(lookup_1_2, 10) === 20);

	// defaultAccount = accounts[2];
	// await add_IOU(accounts[0], "10");

	// owed = await getTotalOwed(accounts[0]);
	// score += check("getTotalOwed(0) now 0", owed === 0);
}

async function sanityCheck() {
	console.log ("\nTEST", "Simplest possible test: only runs one add_IOU; uses all client functions: lookup, getTotalOwed, getUsers, getLastActive");

	var score = 0;

	var accounts = await provider.listAccounts();
	defaultAccount = accounts[0];

	var users = await getUsers();
	score += check("getUsers() initially empty", users.length === 0);

	var owed = await getTotalOwed(accounts[1]);
	score += check("getTotalOwed(0) initially empty", owed === 0);

	var lookup_0_1 = await BlockchainSplitwise.lookup(accounts[0], accounts[1]);
	console.log("lookup(0, 1) current value" + lookup_0_1);
	score += check("lookup(0,1) initially 0", parseInt(lookup_0_1, 10) === 0);

	var response = await add_IOU(accounts[1], "10");

	users = await getUsers();
	console.log(users);
	score += check("getUsers() now length 2", users.length === 2);

	owed = await getTotalOwed(accounts[0]);
	score += check("getTotalOwed(0) now 10", owed === 10);

	lookup_0_1 = await BlockchainSplitwise.lookup(accounts[0], accounts[1]);
	score += check("lookup(0,1) now 10", parseInt(lookup_0_1, 10) === 10);

	var timeLastActive = await getLastActive(accounts[0]);
	var timeNow = Date.now()/1000;
	var difference = timeNow - timeLastActive;
	score += check("getLastActive(0) works", difference <= 60 && difference >= -3); // -3 to 60 seconds

	console.log("Final Score: " + score +"/21");
}

sanityCheck2() //Uncomment this line to run the sanity check when you first open index.html
