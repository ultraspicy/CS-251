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
    event New_IOU(address from, address to, uint32 amount);

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

    function add_IOU(address creditor, uint32 amount, address[] calldata path) public {
        if (path.length == 0) {
            balances[msg.sender].push(Entry(creditor, amount));
        } else {
            // if client provided a loop of debt, we need to make sure the loop 
            // does exist so we won't wipe out others debt
            uint32 min = 999;
            for(uint i = 0; i < path.length - 1; i++) {
                uint32 owned = lookup(path[i], path[i + 1]);
                require(owned > 0);
                if (min > owned) {
                    min = owned;
                }
            }
            // loop exist, then deduct the min from the loop
            if (min > amount) {
                min = amount;
            }
            for(uint i = 0; i < path.length - 1; i++) {
                Entry[] storage balance = balances[path[i]];
                for (uint j = 0; j < balance.length; j++) {
                    if(balance[j].creditor == path[i + 1]) {
                        balance[j].amount -= min;
                    }
                }
            }

            if (min != amount) {
                balances[msg.sender].push(Entry(creditor, amount - min));
            }
        }
    }

}
