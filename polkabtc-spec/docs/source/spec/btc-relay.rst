
.. _btc-relay:

BTC-Relay
==========


.. todo:: Link to BTC-Relay spec

Accepted Bitcoin Transaction Format
------------------------------------

Bitcoin transactions used in the :ref:`issue`, :ref:`redeem`, and :ref:`replace` protocols must be `P2PKH <https://en.bitcoinwiki.org/wiki/Pay-to-Pubkey_Hash>`_ or `P2WPKH <https://github.com/libbitcoin/libbitcoin-system/wiki/P2WPKH-Transactions>`_ transactions and follow the format below.



.. tabularcolumns:: |l|L|

===========================  ===========================================================
Inputs                       Outputs
===========================  ===========================================================
Arbitrary amount of inputs   UTXO 1: P2PKH / P2WPKH output to ``btcAddress`` Bitcoin address.

                             UTXO 2: OP_RETURN containing ``identifier``
                            
                             ...
                             
                             Arbitrary amount of other UTXOs
                             
                             ...
===========================  ===========================================================

The value and recipient address (``btcAddress``) of the first UTXO and the ``identifier`` in the (2nd) OP_RETURN UTXO depend on the executed PolkaBTC protocol:

  + In :ref:`issue-protocol` ``btcAddress`` is the Bitcoin address of the Vault selected by the user for the issuing process and ``identifier`` is the ``issueId`` of the ``IssueRequest`` in ``IssueRequests``.
  + In :ref:`redeem-protocol` ``btcAddress`` is the Bitcoin address of the user who triggered the redeem process and ``identifier`` is the ``redeemId`` of the ``RedeemRequest`` in ``RedeemRequests``.
  + In :ref:`replace-protocol` ``btcAddress`` is the Bitcoin address of the new Vault, which has agreed to replace the Vault which triggered the replace protocol and ``identifier`` is the ``replaceId`` of the ``ReplaceRequest`` in ``ReplaceRequests``.
