from bitcoin.core.script import *

######################################################################
# These functions will be used by Alice and Bob to send their respective
# coins to a utxo that is redeemable either of two cases:
# 1) Recipient provides x such that hash(x) = hash of secret
#    and recipient signs the transaction.
# 2) Sender and recipient both sign transaction
#
# TODO: Fill these in to create scripts that are redeemable by both
#       of the above conditions.
# See this page for opcode documentation: https://en.bitcoin.it/wiki/Script

# This is the ScriptPubKey for the swap transaction
def coinExchangeScript(public_key_sender, public_key_recipient, hash_of_secret):
    return [
        OP_IF,
        OP_2, public_key_sender, public_key_recipient, OP_2, OP_CHECKMULTISIG,
        OP_ELSE,
        public_key_recipient, OP_CHECKSIGVERIFY, OP_HASH160, hash_of_secret, OP_EQUAL,
        OP_ENDIF
    ]

# This is the ScriptSig that the receiver will use to redeem coins
def coinExchangeScriptSig1(sig_recipient, secret):
    return [
        secret, sig_recipient,  OP_0
    ]

# This is the ScriptSig for sending coins back to the sender if unredeemed
# x sig1 sig2 ... <number of signatures> pub1 pub2 <number of public keys>
def coinExchangeScriptSig2(sig_sender, sig_recipient):
    return [
        OP_0, sig_sender, sig_recipient, OP_1
    ]
######################################################################

######################################################################
#
# Configured for your addresses
#
# TODO: Fill in all of these fields
#

alice_txid_to_spend     = "134710e43e78f5c24ecd6509248fdd0ebb3a6f1969d77eced66867c1b0e28876"
alice_utxo_index        = 0 # can be 0, 1, 2
alice_amount_to_send    = 0.0000001

bob_txid_to_spend       = "cd0f38551e9f1857d9ef91982a64d4c1c16f533bf60acb609fa86ce927979c91"
bob_utxo_index          = 0
bob_amount_to_send      = 0.0000002

# Get current block height (for locktime) in 'height' parameter for each blockchain (will be used in swap.py):
#  curl https://api.blockcypher.com/v1/btc/test3
btc_test3_chain_height  = 2532863

#  curl https://api.blockcypher.com/v1/bcy/test
bcy_test_chain_height   = 1023046

# Parameter for how long Alice/Bob should have to wait before they can take back their coins
# alice_locktime MUST be > bob_locktime
alice_locktime = 5
bob_locktime = 3

tx_fee = 0.00005 # 0.0001 Change it to be 1/10 of the setting, no sufficient fund afer split

# While testing your code, you can edit these variables to see if your
# transaction can be broadcasted succesfully.
broadcast_transactions = False
alice_redeems = True

######################################################################
