// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import './token.sol';
import "hardhat/console.sol";

// todo 
// 1) add check in swap contract that ensure there is at least 1 token and at least 1 eth  
// 3) in exchage.js, write test cases that test the slipage can block the transaction
// 4) in exchange.js, write test case that verify the fee distribution 
//         - when user suddenly has a great share of pool, but no swap happens , then no fee
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
    mapping(address => uint) token_fee_reserves_extra;
    mapping(address => uint) eth_fee_reserves_extra;

    // Total Pool Shares
    uint private total_shares = 0;

    // liquidity rewards
    uint private swap_fee_numerator = 3;                
    uint private swap_fee_denominator = 100;

    // Constant: x * y = k
    uint private k;

    // For use with exchange rates
    uint private multiplier = 10**5;

    event SwapTokensForETHEvent(uint message);

    // modifier to limit the exchange rate
    modifier exchangeRateWithIn (uint max, uint min) {
        uint cur = TokenOverEthRate();
        // console.log("===========================================================");
        // console.log(cur);
        // console.log(max);
        // console.log(min);
        // console.log("===========================================================");
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
        // console.log("createPool");
        // console.log(msg.value);
        uint tokenSupply = token.balanceOf(msg.sender);
        // console.log(tokenSupply);
        // console.log(amountTokens);
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

        // EXTRE CREDIT
        bool existingLP = false;
        for(uint256 i = 0; i < lp_providers.length; i++) {
            if (msg.sender == lp_providers[i]) {
                existingLP = true;
                break;
            }
        }
        if (!existingLP) {
            lp_providers.push(msg.sender);
        }
    }


    // Function removeLiquidity: Removes liquidity given the desired amount of ETH to remove.
    // You can change the inputs, or the scope of your function, as needed.
    function removeLiquidity(
        uint amountETH, 
        uint max_token_eth_ex_rate, 
        uint min_token_eth_ex_rate, 
        bool extraCreditMode
    )
        public 
        payable
        exchangeRateWithIn(max_token_eth_ex_rate, min_token_eth_ex_rate)
        nonReentrant
    {
        /******* TODO: Implement this function *******/
        // step1: make sure user didn't excessively withdraw
        uint shares = lps[msg.sender];
        // console.log("====== removeLiquidity ========");
        // console.log(amountETH);
        // console.log(eth_reserves * shares / total_shares);
        require(amountETH <= eth_reserves * shares / total_shares, "user doesn't have enough shares of pool to removeLiquidity");
        // step2.a: from token(eth)_reserve, transfer eth and token back to user
        uint amountToken = amountETH * token_reserves / eth_reserves;
        bool transfer = token.transfer(msg.sender, amountToken);
        assert(transfer);
        payable(msg.sender).transfer(amountETH);
        // step2.b: from fee_reserve, transfer eth and token back to user
        uint ethReward;
        uint tokenReward;
        if (extraCreditMode) {
            // EXTRA CREDIT
            // withdraw proportional fee_resever_extra as well
            uint about_remove_from_user = total_shares * amountETH / eth_reserves;
            uint total_share_of_user = lps[msg.sender];
            ethReward = eth_fee_reserves_extra[msg.sender] * about_remove_from_user / total_share_of_user;
            tokenReward = token_fee_reserves_extra[msg.sender] * about_remove_from_user / total_share_of_user;
        } else {
            ethReward = eth_fee_reserves * amountETH / eth_reserves;
            tokenReward = token_fee_reserves * amountETH / eth_reserves;
        }
        bool rewardTransfer = token.transfer(msg.sender, tokenReward);
        assert(rewardTransfer);
        payable(msg.sender).transfer(ethReward);
        // step3: update state variables
        token_reserves = token_reserves - amountToken;
        require(token_reserves > 1, "Need to make sure there is at least 1 token in pool");
        eth_reserves = eth_reserves - amountETH;
        require(eth_reserves > 10 ** 18, "Need to make sure there is at least 1 ETH in poll");
        token_fee_reserves = token_fee_reserves - tokenReward;
        eth_fee_reserves = eth_fee_reserves - ethReward;
        uint share_to_remove = total_shares * amountETH / eth_reserves;
        console.log(lps[msg.sender]);
        console.log(share_to_remove);
        lps[msg.sender] = lps[msg.sender] - share_to_remove;
        total_shares = total_shares - share_to_remove;
        k = (token_reserves - amountToken) * (eth_reserves - amountETH);
    }

    // Function removeAllLiquidity: Removes all liquidity that msg.sender is entitled to withdraw
    // You can change the inputs, or the scope of your function, as needed.
    function removeAllLiquidity(
        uint max_token_eth_ex_rate, 
        uint min_token_eth_ex_rate,
        bool extraCreditMode
    )
        external
        payable
        exchangeRateWithIn(max_token_eth_ex_rate, min_token_eth_ex_rate)
        nonReentrant
    {
        /******* TODO: Implement this function *******/
        // step1.a: from token(eth)_reserve, transfer eth and token back to user
        uint shares = lps[msg.sender];
        uint ethAmount = eth_reserves * shares / total_shares;
        uint tokenAmount = token_reserves * shares / total_shares;
        bool transfer = token.transfer(msg.sender, tokenAmount);
        assert(transfer);
        payable(msg.sender).transfer(ethAmount);
        // step1.b: from fee_reserve, transfer eth and token back to user
        uint ethRewardAmount;
        uint tokenRewardAmount;
        if (extraCreditMode) {
            ethRewardAmount = eth_fee_reserves_extra[msg.sender];
            tokenRewardAmount = token_fee_reserves_extra[msg.sender];
            uint256 lp_provider_index = 0;
            for(uint256 i = 0; i < lp_providers.length; i++) {
                if (msg.sender == lp_providers[i]) {
                    lp_provider_index = i;
                    break;
                }
            }
            removeLP(lp_provider_index);
        } else {
            ethRewardAmount = eth_fee_reserves * shares / total_shares;
            tokenRewardAmount = token_fee_reserves * shares / total_shares;
        }
        bool rewardTran = token.transfer(msg.sender, tokenRewardAmount);
        assert(rewardTran);
        payable(msg.sender).transfer(ethRewardAmount);
        // step2: update state variables
        token_reserves = token_reserves - tokenAmount;
        require(token_reserves > 1, "Need to make sure there is at least 1 token in pool");
        eth_reserves = eth_reserves - ethAmount;
        require(eth_reserves > 10 ** 18, "Need to make sure there is at least 1 ETH in poll");
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
        // console.log("rate = ");
        // console.log(rate);
        // console.log("max_exchange_rate =");
        // console.log(max_exchange_rate);
        require(rate < max_exchange_rate, "Eth price has increased significantly. Slippage aborts the transaction");
        // step1: token will be split into regular_reserve and fee_reserve
        uint phiX = amountTokens * numerator() / swap_fee_denominator;
        uint fee_reserve = amountTokens - phiX;
        uint amountETH = phiX * eth_reserves / (token_reserves + phiX);
        bool tranfer = token.transferFrom(msg.sender, address(this), amountTokens);
        assert(tranfer);
        payable(msg.sender).transfer(amountETH);
        // console.log("phiX");
        // console.log(phiX);
        // console.log("fee_reserve");
        // console.log(fee_reserve);
        // console.log("amountETH");
        // console.log(amountETH);
        // step2: update pool state variables 
        token_reserves = token_reserves + phiX;
        eth_reserves = eth_reserves - amountETH;
        token_fee_reserves = token_fee_reserves + fee_reserve;

        // EXTRA CREDIT
        for(uint256 i = 0; i < lp_providers.length; i++) {
            address lp_provider = lp_providers[i];
            uint exact_fee_shares = fee_reserve * lps[lp_provider] / total_shares;
            token_fee_reserves_extra[lp_provider] += exact_fee_shares;
        }
        
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
        // console.log("rate = ");
        // console.log(rate);
        // console.log("max_exchange_rate =");
        // console.log(max_exchange_rate);
        require(rate < max_exchange_rate, "token price has increased significantly. Slippage aborts the transaction");
        // step1: msg.value will be split into regular_reserve and fee_reserve
        uint phiX = msg.value * numerator() / swap_fee_denominator;
        uint fee_reserve =  msg.value - phiX;
        // take eth from user and transfer token back to user
        uint amountToken = phiX * token_reserves / (eth_reserves + phiX);
        bool transfer = token.transfer(msg.sender, amountToken);
        assert(transfer);
        // step2: update pool state variables 
        token_reserves = token_reserves - amountToken;
        eth_reserves = eth_reserves + phiX;
        eth_fee_reserves = eth_fee_reserves + fee_reserve;

        // EXTRA CREDIT
        for(uint256 i = 0; i < lp_providers.length; i++) {
            address lp_provider = lp_providers[i];
            uint exact_fee_shares = fee_reserve * lps[lp_provider] / total_shares;
            eth_fee_reserves_extra[lp_provider] += exact_fee_shares;
        }
    }

    function EthOverTokenRate() internal view returns (uint256) {
        return multiplier * eth_reserves / token_reserves / 10 ** 18; 
    }

    function TokenOverEthRate() internal view returns (uint256) {
        return multiplier * token_reserves * (10 ** 18) / eth_reserves; 
    }

    function numerator() internal view returns (uint256) {
        return swap_fee_denominator - swap_fee_numerator;
    }
}
