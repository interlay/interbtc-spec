Events
======

StoreMainChainHeader
--------------------

If the block header was stored successfully, emit an event with the stored block’s height and the (PoW) block hash.

*Event Signature*

``StoreMainChainHeader(blockHeight, blockHash)``

*Parameters*

* ``blockHeight``: height of the current block submission.
* ``blockHash``: hash of the current block submission.

*Functions*

* :ref:`storeMainChainBlockHeader`


StoreForkHeader
---------------

If the submitted block header is on a fork, emit an event with the fork’s id, block height and the (PoW) block hash.

*Event Signature*

``StoreForkHeader(forkId, blockHeight, blockHash)``

*Parameters*

* ``forkId``: a unique id for the fork.
* ``blockHeight``: height of the current block submission.
* ``blockHash``: hash of the current block submission.

*Functions*

* :ref:`storeForkBlockHeader`

ChainReorg
----------

If the submitted block header on a fork results in a reorganization (fork longer than current main chain), emit an event with the block hash of the new highest block, the start block height of the fork and the fork identifier.

*Event Signature*

``ChainReorg(newChainTip, startHeight, forkId)``

*Parameters*

* ``newChainTip``: hash of the new highest block.
* ``startHeight``: height of the new highest block.
* ``forkId``: a unique id for the fork.

*Functions*

* :ref:`storeForkBlockHeader`

VerifyTransaction
-----------------

Issue an event for a given transaction id and a block height and return the result of the transaction verification.

*Event Signature*

``VerifyTransaction(txId, blockHeight, result)``

*Parameters*

* ``txId``: the hash of the transaction.
* ``txBlockHeight``: height of block of the transaction.
* ``result``: result of the verification as true or false.

*Functions*

* :ref:`verifyTransaction`