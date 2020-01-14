
.. _accepted-tx-format:

Accepted Bitcoin Transaction Format
====================================

The :ref:`parser` module of BTC-Relay can in theory be used to parse arbitrary Bitcoin transactions. 
However, the PolkaBTC component of the BTC Parachain restricts the format of Bitcoin transactions to ensure consistency and prevent protocol failure due to parsing errors. 

As such, Bitcoin transactions for which transaction inclusion proofs are submitted to BTC-Relay as part of the in the PolkaBTC *Issue*, *Redeem*, and *Replace* protocols must be `P2PKH <https://en.bitcoinwiki.org/wiki/Pay-to-Pubkey_Hash>`_ or `P2WPKH <https://github.com/libbitcoin/libbitcoin-system/wiki/P2WPKH-Transactions>`_ transactions and follow the format below.

.. note:: Please refer to the PolkaBTC specification for more details on the *Issue*, *Redeem* and *Replace* protocols. 


.. tabularcolumns:: |l|L|

============================  ===========================================================
Inputs                        Outputs
============================  ===========================================================
*Arbitrary number of inputs*  *Index 0: Payment UTXO*: P2PKH / P2WPKH output to ``btcAddress`` Bitcoin address.

                              *Index 1: Data UTXO*: OP_RETURN containing ``identifier``
                            
                             
                             
                              *Arbitrary numnber of other UTXOs*
                             
                             
============================  ===========================================================

The value and recipient address (``btcAddress``) of the *Payment UTXO* and the ``identifier`` in the *Data UTXO* (OP_RETURN) depend on the executed PolkaBTC protocol:

  + In *Issue* ``btcAddress`` is the Bitcoin address of the Vault selected by the user for the issuing process and ``identifier`` is the ``issueId`` of the ``IssueRequest`` in ``IssueRequests``.
  + In *Redeem* ``btcAddress`` is the Bitcoin address of the user who triggered the redeem process and ``identifier`` is the ``redeemId`` of the ``RedeemRequest`` in ``RedeemRequests``.
  + In *Replace* ``btcAddress`` is the Bitcoin address of the new Vault, which has agreed to replace the Vault which triggered the replace protocol and ``identifier`` is the ``replaceId`` of the ``ReplaceRequest`` in ``ReplaceRequests``.



P2PKH / P2WPKH
---------------

.. todo:: Add brief explanation and reference to Bitcoin wiki. `P2PKH <https://en.bitcoinwiki.org/wiki/Pay-to-Pubkey_Hash>`_ or `P2WPKH <https://github.com/libbitcoin/libbitcoin-system/wiki/P2WPKH-Transactions>`_

OP_RETURN
----------
The `OP_RETURN <https://bitcoin.org/en/transactions-guide#term-null-data>`_ field can be used to store `40 bytes in a given Bitcoin transaction <https://bitcoin.stackexchange.com/questions/29554/explanation-of-what-an-op-return-transaction-looks-like>`_. The transaction output that includes the OP_RETURN is provably unspendable. We require specific information in the OP_RETURN field to prevent replay attacks in PolkaBTC.


.. todo:: Add links to PolkaBTC specification.
