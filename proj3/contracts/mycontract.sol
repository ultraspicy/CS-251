// SPDX-License-Identifier: UNLICENSED

// DO NOT MODIFY BELOW THIS
pragma solidity ^0.8.17;

import "hardhat/console.sol";

contract Splitwise {
// DO NOT MODIFY ABOVE THIS

    // ADD YOUR CONTRACT CODE BELOW
    /**
     * Avoid any complex operation such as on-chain BFS
     * instead, move complex logic to client   
     */
    event NewCall(address ad);

    struct Entry {
        address creditor;
        uint32 amount;
    }
    mapping (address => Entry[]) balances;

    /**
     * loop up the the amount debtor owner to credtor 
     * @param debtor the address of person who owns
     * @param creditor the address of person who is owned
     * 
     *client action
     *  - lookup to traverse the graph
     *  - compute the possible loop of debt
     *  - resolve the loop of debt by deducting the path_min_val
     *    - by Splitwise.add_IOU() for the opposite direction 
     */
    function lookup(address debtor, address creditor) public view returns (uint32 ret) {
        Entry[] memory balance = balances[debtor];
        if (balance.length == 0) return 0;
        
        for (uint i = 0; i < balance.length; i++) {
            if (balance[i].creditor == creditor) {
                return balance[i].amount;
            }
        }
        return 0;
    }

    /**
     * Add owning transaction from msg.send to creditor. 
     * If reverse is true, creditor resolve credit from msg.sender
     * @param creditor person who own
     * @param amount the value of owning 
     * @param reverse if the transaction is a "reverse transaction"
     * 
     * Note that when reverse = true, the amount is the min_value in the loop, 
     * meaning we will never run into negative debt.
     * Also note the reverse = true is only used to resolve loop of debt
     */
    function add_IOU(address creditor, uint32 amount, bool reverse) public {
        // TODO add require to prevent malicous use  
        Entry[] storage balance = balances[msg.sender];

        //step 1: find if they have any unsettled payment/existing entry
        for (uint i = 0; i < balance.length; i++) {
            if (balance[i].creditor == creditor) {
                if (reverse) {
                    balance[i].amount = balance[i].amount - amount;
                } else {
                    balance[i].amount = balance[i].amount + amount;
                }
            }
        }

        // step 2: if not, this is the first transaction from msg.send to creditor
        balance.push(Entry(creditor, amount));
    }
}
