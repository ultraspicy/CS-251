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

    bool private locked;

    modifier nonReentrant() {
        require(!locked, "Reentrancy detected");
        locked = true;
        _;
        locked = false;
    }

    mapping (address => mapping (address => uint32)) balances;

    function lookup(address debtor, address creditor) public view returns (uint32 ret) {
        return balances[debtor][creditor];
    }

    /**
     * potential malicicious use
     *  - client provides a loop that doesn't exist. Contract will double check the loop 
     *    to make sure it won't wipe out other's debt
     *  - client detects a loop but doesn't tell the contract. Then we still add the IOU
     *    but without resolving the loop. This would be fine since all owing is preserved
     *  - client adds IOU to itself, this will abort the transaction since this self-owning
     *    is not valid. We won't introduce any "self-loop"
     * Design decision
     *  - We we should be able to unify the implmentation of loop solving, making implementation
     *    less verbose. But the current implementation is more gas-efficient
     *  - All complex computation such as BFS will be done on the client side. To make contract be 
     *    as gas-efficient as possible, we only do two things 1) data update 2) necessary sanity 
     *    check against the input
     *  - add nonReentrant modifier
     *  - add check to make sure the creditor is owned more by msg.sender 
     *    after calling add_IOU()
     * @param creditor the address who i owed 
     * @param amount  the actual amount
     * @param path  the potential loop found by the client
     */
    function add_IOU(address creditor, uint32 amount, address[] calldata path) external nonReentrant {
        require(msg.sender != creditor);
        require(amount > 0);

        uint prevIOU = lookup(msg.sender, creditor);
        emit New_IOU(msg.sender, creditor, amount);
        // case 1 - no loop or two-node loop
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
        // case 2 - loop with # nodes > 2
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

        uint afterIOU = lookup(msg.sender, creditor);
        require(prevIOU < afterIOU);
    }

    function add_IOU_helper(address from, address to, uint32 delta, bool nagative) private {
        if (nagative) {
            balances[from][to] = balances[from][to] - delta;
        } else {
            balances[from][to] = balances[from][to] + delta;
        }
    }

}
