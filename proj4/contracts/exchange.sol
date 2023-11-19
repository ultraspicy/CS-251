// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import './token.sol';
import "hardhat/console.sol";


contract TokenExchange is Ownable {
    string public exchange_name = 'cs251swap';
    bool private locked;

    // TODO: paste token contract address here
    address tokenAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3; 
    Token public token = Token(tokenAddr);                                

    // Liquidity pool for the exchange
    uint private token_reserves = 0;
    uint private eth_reserves = 0;

    // Fee Pools
    uint private token_fee_reserves = 0;
    uint private eth_fee_reserves = 0;

    // Liquidity pool shares
    mapping(address => uint) private lps;

    // For Extra Credit only: to loop through the keys of the lps mapping
    address[] private lp_providers;      

    // Total Pool Shares
    uint private total_shares = 0;

    // liquidity rewards
    uint private swap_fee_numerator = 0;                
    uint private swap_fee_denominator = 100;

    // Constant: x * y = k
    uint private k;

    // For use with exchange rates
    uint private multiplier = 10**5;

    event SwapTokensForETHEvent(uint message);

    // modifier to limit the exchange rate
    modifier exchangeRateWithIn (uint max, uint min) {
        uint cur = TokenOverEthRate();
        require(cur < max, "exchange rate too high");
        require(cur > min, "exchange rate too low");
        _;
    }

    // non reentrancy 
    modifier nonReentrant() {
        require(!locked, "Reentrancy detected");
        locked = true;
        _;
        locked = false;
    }

    constructor() {}
    

    // Function createPool: Initializes a liquidity pool between your Token and ETH.
    // ETH will be sent to pool in this transaction as msg.value
    // amountTokens specifies the amount of tokens to transfer from the liquidity provider.
    // Sets up the initial exchange rate for the pool by setting amount of token and amount of ETH.
    function createPool(uint amountTokens)
        external
        payable
        onlyOwner
    {
        // This function is already implemented for you; no changes needed.

        // require pool does not yet exist:
        require (token_reserves == 0, "Token reserves was not 0");
        require (eth_reserves == 0, "ETH reserves was not 0.");

        // require nonzero values were sent
        require (msg.value > 0, "Need eth to create pool.");
        console.log("createPool");
        console.log(msg.value);
        uint tokenSupply = token.balanceOf(msg.sender);
        console.log(tokenSupply);
        console.log(amountTokens);
        require(amountTokens <= tokenSupply, "Not have enough tokens to create the pool");
        require (amountTokens > 0, "Need tokens to create pool.");

        token.transferFrom(msg.sender, address(this), amountTokens);
        token_reserves = token.balanceOf(address(this));
        eth_reserves = msg.value;
        k = token_reserves * eth_reserves;

        // Pool shares set to a large value to minimize round-off errors
        total_shares = 10**5;
        // Pool creator has some low amount of shares to allow autograder to run
        lps[msg.sender] = 100;
    }

    // For use for ExtraCredit ONLY
    // Function removeLP: removes a liquidity provider from the list.
    // This function also removes the gap left over from simply running "delete".
    function removeLP(uint index) private {
        require(index < lp_providers.length, "specified index is larger than the number of lps");
        lp_providers[index] = lp_providers[lp_providers.length - 1];
        lp_providers.pop();
    }

    // Function getSwapFee: Returns the current swap fee ratio to the client.
    function getSwapFee() public view returns (uint, uint) {
        return (swap_fee_numerator, swap_fee_denominator);
    }

    // ============================================================
    //                    FUNCTIONS TO IMPLEMENT
    // ============================================================
    
    /* ========================= Liquidity Provider Functions =========================  */ 

    // Function addLiquidity: Adds liquidity given a supply of ETH (sent to the contract as msg.value).
    // You can change the inputs, or the scope of your function, as needed.
    function addLiquidity(uint max_token_eth_ex_rate, uint min_token_eth_ex_rate) 
        external 
        payable
        exchangeRateWithIn(max_token_eth_ex_rate, min_token_eth_ex_rate)
        nonReentrant
    {   
        /******* TODO: Implement this function *******/
        // transfer the token into this account
        uint token_to_add =  msg.value * token_reserves / eth_reserves;
        uint tokenRemainingBalance = token.balanceOf(msg.sender);
        require(token_to_add <= tokenRemainingBalance, "Remaining balance of the send is not enough to provide the liquidity");
        bool transfer = token.transferFrom(msg.sender, address(this), token_to_add);
        assert(transfer);
        // step 2: update state variables of the contract 
        // aka token_reserves, eth_reserves, lps, total_shares and k
        token_reserves = token_to_add + token_reserves;
        eth_reserves = msg.value + eth_reserves;
        uint new_share = total_shares * msg.value / eth_reserves;
        uint old_share = lps[msg.sender];
        lps[msg.sender] = old_share + new_share;
        total_shares = total_shares + new_share;
        k = (token_to_add + token_reserves) * (msg.value + eth_reserves);
    }


    // Function removeLiquidity: Removes liquidity given the desired amount of ETH to remove.
    // You can change the inputs, or the scope of your function, as needed.
    function removeLiquidity(uint amountETH, uint max_token_eth_ex_rate, uint min_token_eth_ex_rate)
        public 
        payable
        exchangeRateWithIn(max_token_eth_ex_rate, min_token_eth_ex_rate)
        nonReentrant
    {
        /******* TODO: Implement this function *******/
        // step1: make sure user didn't excessively withdraw
        uint shares = lps[msg.sender];
        console.log("====== removeLiquidity ========");
        console.log(amountETH);
        console.log(eth_reserves * shares / total_shares);
        require(amountETH <= eth_reserves * shares / total_shares, "user doesn't have enough shares of pool to removeLiquidity");
        // step2: transfer eth and token back to user
        uint amountToken = amountETH * token_reserves / eth_reserves;
        bool transfer = token.transfer(msg.sender, amountToken);
        assert(transfer);
        payable(msg.sender).transfer(amountETH);
        // step3: update state variables
        token_reserves = token_reserves - amountToken;
        eth_reserves = eth_reserves - amountETH;
        uint share_to_remove = total_shares * amountETH / eth_reserves;
        console.log(lps[msg.sender]);
        console.log(share_to_remove);
        lps[msg.sender] = lps[msg.sender] - share_to_remove;
        total_shares = total_shares - share_to_remove;
        k = (token_reserves - amountToken) * (eth_reserves - amountETH);
    }

    // Function removeAllLiquidity: Removes all liquidity that msg.sender is entitled to withdraw
    // You can change the inputs, or the scope of your function, as needed.
    function removeAllLiquidity(uint max_token_eth_ex_rate, uint min_token_eth_ex_rate)
        external
        payable
        exchangeRateWithIn(max_token_eth_ex_rate, min_token_eth_ex_rate)
        nonReentrant
    {
        /******* TODO: Implement this function *******/
        // step1: transfer eth and token back to user
        uint shares = lps[msg.sender];
        uint ethAmount = eth_reserves * shares / total_shares;
        uint tokenAmount = token_reserves * shares / total_shares;
        bool transfer = token.transfer(msg.sender, tokenAmount);
        assert(transfer);
        payable(msg.sender).transfer(ethAmount);
        // step2: update state variables
        token_reserves = token_reserves - tokenAmount;
        eth_reserves = eth_reserves - ethAmount;
        total_shares = total_shares - lps[msg.sender];
        lps[msg.sender] = 0;
        k = (token_reserves - tokenAmount) * (eth_reserves - ethAmount);
    }
    /***  Define additional functions for liquidity fees here as needed ***/


    /* ========================= Swap Functions =========================  */ 

    // Function swapTokensForETH: Swaps your token with ETH
    // You can change the inputs, or the scope of your function, as needed.
    function swapTokensForETH(uint amountTokens, uint max_exchange_rate)
        external 
        payable
        nonReentrant
    {
        /******* TODO: Implement this function *******/
        // step0: 
        uint rate = TokenOverEthRate();
        console.log("rate = ");
        console.log(rate);
        console.log("max_exchange_rate =");
        console.log(max_exchange_rate);
        require(rate < max_exchange_rate, "Eth price has increased significantly. Slippage aborts the transaction");

        // console.log("token_reserves =");
        // console.log(token_reserves);
        // console.log("amountTokens = ");
        // console.log(amountTokens);
        // console.log("eth_reserves =");
        // console.log(eth_reserves);
        // step1: take token from user and transfer eth back to user
        uint amountETH = amountTokens * eth_reserves / (token_reserves + amountTokens);
        // console.log("amountETH = ");
        // console.log(amountETH);
        
        //uint allowance = token.allowance(msg.sender, address(this));
        // console.log("allowance = ");
        // console.log(allowance);
        bool tranfer = token.transferFrom(msg.sender, address(this), amountTokens);
        assert(tranfer);
        // console.log("pool balance = ");
        // console.log(token.balanceOf(address(this)));
        // console.log("msg.sender balance = ");
        // console.log(token.balanceOf(msg.sender));
        payable(msg.sender).transfer(amountETH);
        // step2: update pool state variables 
        token_reserves = token_reserves + amountTokens;
        eth_reserves = eth_reserves - amountETH;
    }



    // Function swapETHForTokens: Swaps ETH for your tokens
    // ETH is sent to contract as msg.value
    // You can change the inputs, or the scope of your function, as needed.
    function swapETHForTokens(uint max_exchange_rate)
        external
        payable 
        nonReentrant
    {
        /******* TODO: Implement this function *******/
        // step0: compute exchange rate 
        uint rate = EthOverTokenRate();
        console.log("rate = ");
        console.log(rate);
        console.log("max_exchange_rate =");
        console.log(max_exchange_rate);
        require(rate < max_exchange_rate, "token price has increased significantly. Slippage aborts the transaction");
        // step1: take eth from user and transfer token back to user
        uint amountToken = msg.value * token_reserves / (eth_reserves + msg.value);
        bool transfer = token.transfer(msg.sender, amountToken);
        assert(transfer);
        // step2: update pool state variables 
        token_reserves = token_reserves - amountToken;
        eth_reserves = eth_reserves + msg.value;
    }

    function EthOverTokenRate() internal view returns (uint256) {
        return multiplier * eth_reserves / token_reserves / 10 ** 18; 
    }

    function TokenOverEthRate() internal view returns (uint256) {
        return multiplier * token_reserves * (10 ** 18) / eth_reserves; 
    }
}
