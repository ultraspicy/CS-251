from sys import exit
from bitcoin.core.script import *

from lib.utils import *
from lib.config import (my_private_key, my_public_key, my_address,
                    faucet_address, network_type)
from Q1 import send_from_P2PKH_transaction


######################################################################
# TODO: Complete the scriptPubKey implementation for Exercise 2
Q2a_txout_scriptPubKey = [
        OP_2DUP, 
        OP_ADD, 
        #OP_PUSHDATA2, 
        0x0292, 
        OP_EQUALVERIFY,
        OP_SUB, 
        #OP_PUSHDATA2, 
        0x1532, 
        OP_EQUAL
    ]
######################################################################

if __name__ == '__main__':
    ######################################################################
    # TODO: set these parameters correctly
    # make amount_to_send 
    #  - small enough to get faster confirmation
    #  - significant engough to ensure the redemption 
    amount_to_send = 0.003475 # amount of BTC in the output you're sending minus fee
    txid_to_spend = (
        'ac84188c049cf4f92348a7879d580bc0008faab3699c380b31e6580a01a92d60')
    utxo_index = 1 # index of the output you are spending, indices start at 0
    ######################################################################

    response = send_from_P2PKH_transaction(
        amount_to_send, txid_to_spend, utxo_index,
        Q2a_txout_scriptPubKey, my_private_key, network_type)
    print(response.status_code, response.reason)
    print(response.text)
