Error Codes
===================

A summary of error codes raised in exceptions by BTC-Relay, and their meanings, are provided below.


``ERR_ALREADY_INITIALIZED``


* **Message:** "Already initialized."

* **Function:** ``initialize``

* **Cause**:  Exception raised in ``initialize`` if this function is called when BTC-Relay is already initialized.



``ERR_NOT_MAIN_CHAIN``


* **Message:** "Main chain submission indicated, but submitted block is on a fork"

* **Function:** ``storeMainChainBlockHeader``

* **Cause**:   Exception raised in ``storeMainChainBlockHeader`` if the block header submission indicates that it is extending the current longest chain, but is actually on a (new) fork.


``ERR_FORK_PREV_BLOCK``

* **Message:**  "Previous block hash does not match last block in fork submission"

* **Function:** ``storeForkBlockHeader``

* **Cause**:   Exception raised in ``storeForkBlockHeader`` if the block header does not reference the heighest block in the fork specified by ``forkId`` (via ``prevBlockHash``). 

``ERR_NOT_FORK`` 


* **Message**: "Indicated fork submission, but block is in main chain"

* **Function**: ``storeForkBlockHeader`` 

* **Cause**:  Exception raised  in ``storeForkBlockHeader`` if the block header creates a new or extends an existing fork, but is actually extending the current longest chain.

``ERR_INVALID_FORK_ID``

* **Message**:  "Incorrect fork identifier."

* **Function**: ``storeForkBlockHeader``

* **Cause**: Exception raised  in ``storeForkBlockHeader`` when a non-existent fork identifiert or ``0`` (blocked for special meaning) is passed. 

``ERR_INVALID_HEADER_SIZE``


* **Message**: "Invalid block header size": 

* **Function**: ``verifyBlockHeader``

* **Cause**: Exception raised in ``verifyBlockHeader`` if the submitted block header is not exactly 80 bytes long.


``ERR_DUPLICATE_BLOCK``


* **Message**: "Block already stored"

* **Function**: ``verifyBlockHeader``

* **Cause**: Exception raised in ``verifyBlockHeader`` if the submitted block header is already stored in the BTC-Relay (same PoW ``blockHash``). 

``ERR_PREV_BLOCK``


* **Message**: "Previous block hash not found"

* **Function**: ``verifyBlockHeader``

* **Cause**: Exception raised in ``verifyBlockHeader``  if the submitted block does not reference an already stored block header as predecessor (via ``prevBlockHash``). 


``ERR_LOW_DIFF``


* **Message**:"PoW hash does not meet difficulty target of header"

* **Function**: ``verifyBlockHeader``

* **Cause**: Exception raised in ``verifyBlockHeader``  when the header's ``blockHash`` does not meet the ``target`` specified in the block header.


``ERR_DIFF_TARGET_HEADER``


* **Message**: "Incorrect difficulty target specified in block header"

* **Function**: ``verifyBlockHeader``

* **Cause**: Exception raised in ``verifyBlockHeader`` if the ``target`` specified in the block header is incorrect for its block height (difficulty re-target not executed).


``ERR_INVALID_TXID``


* **Message**: "Invalid transaction identifier"

* **Function**: ``verifyTransaction``

* **Cause**: Exception raised in ``verifyTransaction`` when the transaction id (``txId``) is malformed.

``ERR_CONFIRMATIONS``

* **Message**: "Transaction has less confirmations than requested"

* **Function**: ``verifyTransaction``

* **Cause**: Exception raised in ``verifyTransaction`` when the number of confirmations is less than required.

``ERR_MERKLE_PROOF``


* **Message**: "Invalid Merkle Proof structure"

* **Function**: ``verifyTransaction``

* **Cause**: Exception raised in ``verifyTransaction`` when the Merkle proof is malformed.
