from sys import exit
from bitcoin.core.script import *
from bitcoin.wallet import CBitcoinSecret

from lib.utils import *
from lib.config import (my_private_key, my_public_key, my_address,
                    faucet_address, network_type)
from Q1 import send_from_P2PKH_transaction


cust1_private_key = CBitcoinSecret(
    'cRMoZXR1GBjTXP1ewoLe5BxfHyG8HcR3ye2pMTzrzEQTz4pMKwXz')
cust1_public_key = cust1_private_key.pub
cust2_private_key = CBitcoinSecret(
    'cR5gpkmcumrWmhkEs43m3ECWrLG6gUzWPYGiSneP5ox1ZkEWzvRA')
cust2_public_key = cust2_private_key.pub
cust3_private_key = CBitcoinSecret(
    'cTfNvtAYLiAtXFns2GAJqx5DD3Uo7oApLFcAE7q4GK1318eitdnE')
cust3_public_key = cust3_private_key.pub


######################################################################
# TODO: Complete the scriptPubKey implementation for Exercise 3

# You can assume the role of the bank for the purposes of this problem
# and use my_public_key and my_private_key in lieu of bank_public_key and
# bank_private_key.

Q3a_txout_scriptPubKey = [
        OP_1,
        cust1_public_key,
        cust2_public_key,
        cust3_public_key,
        OP_3,
        OP_CHECKMULTISIGVERIFY,
        my_public_key,
        OP_CHECKSIG
]
######################################################################

if __name__ == '__main__':
    ######################################################################
    # TODO: set these parameters correctly
    amount_to_send = 0.003375 # amount of BTC in the output you're sending minus fee
    txid_to_spend = (
        'ac84188c049cf4f92348a7879d580bc0008faab3699c380b31e6580a01a92d60')
    utxo_index = 2 # index of the output you are spending, indices start at 0
    ######################################################################

    response = send_from_P2PKH_transaction(amount_to_send, txid_to_spend, 
        utxo_index, Q3a_txout_scriptPubKey, my_private_key, network_type)
    print(response.status_code, response.reason)
    print(response.text)
