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

    mapping (address => mapping (address => uint32)) balances;

    function lookup(address debtor, address creditor) public view returns (uint32 ret) {
        return balances[debtor][creditor];
    }

    function add_IOU_helper(address from, address to, uint32 delta, bool nagative) private {
        if (nagative) {
            balances[from][to] = balances[from][to] - delta;
        } else {
            balances[from][to] = balances[from][to] + delta;
        }
    }

    function add_IOU(address creditor, uint32 amount, address[] calldata path) public {
        emit New_IOU(msg.sender, creditor, amount);
        if (path.length == 0) {
            uint32 owned = lookup(creditor, msg.sender);
            if (owned == 0) {
                // no previous debt
                add_IOU_helper(msg.sender, creditor, amount, false);
            } else {
                // two node loop
                if (owned > amount) {
                    balances[creditor][msg.sender] -= amount;
                } else {
                    balances[msg.sender][creditor] = amount - owned;
                    balances[creditor][msg.sender] = 0;
                }
            }
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
                add_IOU_helper(path[i], path[i + 1], min, true);
            }

            if (min != amount) {
                add_IOU_helper(msg.sender, creditor, amount - min, false);
            }
        }
    }

}
