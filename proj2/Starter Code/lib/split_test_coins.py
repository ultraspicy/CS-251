from bitcoin import SelectParams
from bitcoin.core import CMutableTransaction, x
from bitcoin.core.script import CScript, SignatureHash, SIGHASH_ALL
from bitcoin.core.scripteval import VerifyScript, SCRIPT_VERIFY_P2SH

from bitcoin.wallet import CBitcoinSecret, P2PKHBitcoinAddress

from config import (my_private_key, my_public_key, my_address,
    alice_secret_key_BTC, alice_public_key_BTC, alice_address_BTC, 
    bob_secret_key_BTC, bob_public_key_BTC, bob_address_BTC,
    alice_secret_key_BCY, alice_public_key_BCY, alice_address_BCY, 
    bob_secret_key_BCY, bob_public_key_BCY, bob_address_BCY,
    faucet_address, network_type)

from utils import create_txin, create_txout, broadcast_transaction


# This function split amount_to_send coins from txid_to_spend into n euqal pieces
# Input 
#   - txid_to_spend, the funding transaction id 
#   - utxo_index, the index of the output of the funding transaction. txid_to_spend and utxo_index will locate a UTXO
#   - n, the # of shares
#   - 
def split_coins(amount_to_send, txid_to_spend, utxo_index, n, network):
    txin_scriptPubKey = address.to_scriptPubKey()
    txin = create_txin(txid_to_spend, utxo_index)
    txout_scriptPubKey = address.to_scriptPubKey()
    txout = create_txout(amount_to_send / n, txout_scriptPubKey)
    tx = CMutableTransaction([txin], [txout]*n)
    ### why do we need txin_scriptPubKey
    sighash = SignatureHash(txin_scriptPubKey, tx,
                            0, SIGHASH_ALL)
    txin.scriptSig = CScript([private_key.sign(sighash) + bytes([SIGHASH_ALL]),
                              public_key])
    VerifyScript(txin.scriptSig, txin_scriptPubKey,
                 tx, 0, (SCRIPT_VERIFY_P2SH,))
    response = broadcast_transaction(tx, network)
    print(response.status_code, response.reason)
    print(response.text)

if __name__ == '__main__':
    SelectParams('testnet')

    ######################################################################
    # TODO: set these parameters correctly
    private_key = my_private_key
    public_key = private_key.pub
    # https://github.com/petertodd/python-bitcoinlib/blob/master/bitcoin/wallet.py
    # def from_pubkey() uses bitcoin.core.Hash160(pubkey) NOT HASH160
    address = P2PKHBitcoinAddress.from_pubkey(public_key)

    amount_to_send = 0.0143  # amount of BTC in the output you're splitting minus fee
    txid_to_spend = (
        'ff20733b329b395a0e185b4ffc84f775ca80624a748207c628866c32a3f1c095')
    utxo_index = 0 # index of the output you are spending, indices start at 0
    n = 4 # number of outputs to split the input into
    # For n, choose a number larger than what you immediately need, 
    # in case you make mistakes.
    ######################################################################

    split_coins(amount_to_send, txid_to_spend, utxo_index, n, network_type)
