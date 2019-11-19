
Functions
=========



Main Functions
--------------

setInitialParent
~~~~~~~~~~~~~~~~


storeBlockHeader
~~~~~~~~~~~~~~~~


verifyTransaction
~~~~~~~~~~~~~~~~~

The ``verifyTransaction`` function is one of the core components of the chain relay:
this function reports whether or not a given transaction is valid by considering a number of parameters.
The core idea is that a user submits a transaction hash including the parameters to proof to another party that indeed the transaction happened on Bitcoin.
Since the confirmation is based on the stored data in the chain relay, the other party can rely on the trustworthiness of such proof.
Generally, a user has to follow this process to receive a successful transaction verification:


1. The user ensures that the Bitcoin block header, in which his transaction is included, is stored in the BTCRelay (see `storeBlockHeader`_).
2. The user ensures that there are at least the minimum number of confirmations available (typically 6).
3. The user prepares the necessary information to call the function:

    a. The *transaction hash* of the transaction he wants to verify.
    b. The **

4. dsa


Use Cases
^^^^^^^^^
**Issue of Bitcoin-backed Assets**: A CbA Requester transfers a number of Satoshis to the address of a Vault on the Bitcoin blockchain.
The CbA REquester now needs to prove to the Polka-BTC bridge that this indeed happened.
Further, we need to ensure that the transaction is *finalized* on the Bitcoin side, such that the transaction cannot be abandoned.
The CbA Requester achieves this by following the following steps:



Function
^^^^^^^^
*Function Signature*

``verifyTransaction(txid, txBlockHeight, txIndex, merkleProof, confirmations)``

*Parameters*

* ``txid``: the hash of the transaction.
* ``txBlockHeight``: block height at which transacton is supposedly included
* ``txIndex``: index of transaction in the block's tx merkle tree
* ``merkleProof``: merkle tree path (concatenated LE sha256 hashes)

*Returns*

* ``True``: if txid is at the claimed position in the block at the given blockheight
* ``False``: otherwise

*Events*

*Errors*

Helper Methods
--------------

dblSha
~~~~~~

nBitsToTarget
~~~~~~~~~~~~~

checkCorrectTarget
~~~~~~~~~~~~~~~~~~


computeNewTarget
~~~~~~~~~~~~~~~~

computeMerkle
~~~~~~~~~~~~~

concatSha256Hash
~~~~~~~~~~~~~~~~

Getters
~~~~~~~