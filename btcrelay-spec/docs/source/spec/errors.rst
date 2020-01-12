.. _errors:

Error Codes
===================

A summary of error codes raised in exceptions by BTC-Relay, and their meanings, are provided below.


``ERR_ALREADY_INITIALIZED``


* **Message:** "Already initialized."

* **Function:** :ref:`initialize`

* **Cause**:  Raised if the ``initialize`` function is called when BTC-Relay has already been initialized.



``ERR_NOT_MAIN_CHAIN``


* **Message:** "Main chain submission indicated, but submitted block is on a fork"

* **Function:** :ref:`storeMainChainBlockHeader`

* **Cause**:   Raised if the block header submission indicates that it is extending the current longest chain, but is actually on a (new) fork.


``ERR_FORK_PREV_BLOCK``

* **Message:**  "Previous block hash does not match last block in fork submission"

* **Function:** :ref:`storeForkBlockHeader`

* **Cause**: Raised if the block header does not reference the highest block in the fork specified by ``forkId`` (via ``prevBlockHash``). 

``ERR_NOT_FORK`` 

* **Message**: "Indicated fork submission, but block is in main chain"

* **Function**: :ref:`storeForkBlockHeader` 

* **Cause**:  Raised if raise exception if the submitted block header is actually extending the current longest chain tracked by BTC-Relay (``MainChain``), instead of a fork.

``ERR_INVALID_FORK_ID``

* **Message**:  "Incorrect fork identifier."

* **Function**: :ref:`storeForkBlockHeader`

* **Cause**: Raised if a non-existent fork identifier is passed. 

``ERR_INVALID_HEADER_SIZE``


* **Message**: "Invalid block header size": 

* **Function**: :ref:`verifyBlockHeader`

* **Cause**: Raised if the submitted block header is not exactly 80 bytes long.


``ERR_DUPLICATE_BLOCK``


* **Message**: "Block already stored"

* **Function**: :ref:`verifyBlockHeader`

* **Cause**: Raised if the submitted block header is already stored in the BTC-Relay (duplicate PoW ``blockHash``). 

``ERR_PREV_BLOCK``


* **Message**: "Previous block hash not found"

* **Function**: :ref:`verifyBlockHeader`

* **Cause**: Raised if the submitted block does not reference an already stored block header as predecessor (via ``prevBlockHash``). 


``ERR_LOW_DIFF``


* **Message**:"PoW hash does not meet difficulty target of header"

* **Function**: :ref:`verifyBlockHeader`

* **Cause**: Raised if the header's ``blockHash`` does not meet the ``target`` specified in the block header.


``ERR_DIFF_TARGET_HEADER``


* **Message**: "Incorrect difficulty target specified in block header"

* **Function**: :ref:`verifyBlockHeader`

* **Cause**: Raised if the ``target`` specified in the block header is incorrect for its block height (difficulty re-target not executed).


``ERR_INVALID_TXID``


* **Message**: "Invalid transaction identifier"

* **Function**: :ref:`verifyTransaction`

* **Cause**: Raised if the transaction id (``txId``) is malformed.

``ERR_CONFIRMATIONS``

* **Message**: "Transaction has less confirmations than requested"

* **Function**: :ref:`verifyTransaction`

* **Cause**: Raised if the number of confirmations is less than required.

``ERR_MERKLE_PROOF``


* **Message**: "Invalid Merkle Proof structure"

* **Function**: :ref:`verifyTransaction`

* **Cause**: Exception raised in ``verifyTransaction`` when the Merkle proof is malformed.

``ERR_FORK_ID_NOT_FOUND``

* **Message**: "Fork ID not found for specified block hash"

* **Function**: :ref:`getForkIdByBlockHash`

* **Cause**: Return this error if there exists no ``forkId`` for the given ``blockHash``.


``ERR_PARTIAL``

* **Message**: "BTC Parachain partially deactivated"

* **Function**: :ref:`verifyTransaction`

* **Cause**: The BTC Parachain has been partially deactivated since a specific block height.

``ERR_HALTED``

* **Message**: "BTC Parachain is halted"

* **Function**: :ref:`verifyTransaction`

* **Cause**: The BTC Parachain has been halted.

``ERR_SHUTDOWN``
* **Message**: "BTC Parachain has shut down"

* **Function**: :ref:`verifyTransaction` | :ref:`storeForkBlockHeader` | :ref:`storeMainChainBlockHeader`
* **Cause**: The BTC Parachain has been shutdown by a manual intervention of the governance mechanism.

