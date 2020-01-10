.. _events:

Events
======

Initialized
--------------------

If the first block header was stored successfully, emit an event with the stored block’s height and the (PoW) block hash.

*Event Signature*

``Initialized(blockHeight, blockHash)``

*Parameters*

* ``blockHeight``: height of the current block submission.
* ``blockHash``: hash of the current block submission.

*Functions*

* :ref:`initialize`

*Substrate* ::

  Initialized(U256, Hash);

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

*Substrate* ::

  StoreMainChainHeader(U256, Hash);

StoreForkHeader
---------------

If the submitted block header is on a fork, emit an event with the fork’s id, block height and the (PoW) block hash.

*Event Signature*

``StoreForkHeader(forkId, blockHeight, blockHash)``

*Parameters*

* ``forkId``: unique identifier of the tracked fork.
* ``blockHeight``: height of the current block submission.
* ``blockHash``: hash of the current block submission.

*Functions*

* :ref:`storeForkBlockHeader`

*Substrate* ::

  StoreForkHeader(U256, U256, Hash);

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

*Substrate* ::

  ChainReorg(Hash, U256, U256);

VerifyTransaction
-----------------

If the verification of the transaction inclusion proof was successful, emit an event for the given transaction identifier (``txId``), block height (``txBlockHeight``), and the specified number of ``confirmations``.

*Event Signature*

``VerifyTransaction(txId, blockHeight, confirmations)``

*Parameters*

* ``txId``: the hash of the transaction.
* ``txBlockHeight``: height of block of the transaction.
* ``confirmations``: number of confirmations requested for the transaction verification.

*Functions*

* :ref:`verifyTransaction`

*Substrate* ::

  VerifyTransaction(Hash, U256, U256);
