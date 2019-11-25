
Functions
=========

setInitialParent
----------------


storeBlockHeader
----------------

The ``storeBlockHeader`` function parses, verifies and stores Bitcoin block
headers. The maintainance of a sequence of Bitcoin block headers, representing
the main chain (i.e., the longest chain known to the network), serves as basis
for all further queries to the chain relay (such as checking for transaction
inclusion). Specifically, ``storeBlockHeader`` must be called and successfully
executed for a block header at a given block height (``txBlockHeight``), before
being referenced in ``verifyTransaction``.


Specification
~~~~~~~~~~~~~~
*Function Signature*

``storeBlockHeader(blockHeaderBytes, forkId)``

*Parameters*

* ``blockHeaderBytes``: raw Bitcoin block header bytes (80 bytes).
* ``forkId``: if block header is on a fork, specifies which fork is being extended (or being newly created).


*Returns*

* ``True``: if the block header passes all checks and is successfully stored in the chain relay. 
  + the block extends the longest known chain of block headers known to the chain relay
  + the block creates a new or extends an existing fork of the currenlty known longest chain
* ``False``: otherwise.

*Events*

* ``StoreHeader(blockHeight, blockHash)``: if the block header was stored successfully, emit an event with the current block height (``blockHeight``) and the (PoW) block hash (``blockHash``).
* ``StoreForkHeader(blockHeight, blockHash)``: if the submitted block header is on a fork, emit an event with the fork's (now most significant) block height (``blockHeight``) and the (PoW) block hash (``blockHash``).
*  ``ChainReorg(newChainTip, startHeight, forkId)``: if the submitted block header on a fork results in a reorganization (fork longer than current main chain), emit an event with the block hash of the new highest block (``newChainTip``), the start block height of the fork (``startHeight``) and the fork identifier (``forkId``).

*Errors*

* ``ERR_INVALID_FORK_ID`` = "Incorrect fork identifier.": raise an exception when a non-existent fork identifiert or ``0`` (blocked for special meaning) is passed. 
* ``ERR_INVALID_HEADER_SIZE`` = "Invalid block header size": raise exception if the submitted block header is not exactly 80 bytes long.
* ``ERR_DUPLICATE_BLOCK`` = "Block already stored": raise exception if the submitted block header is already stored in the chain relay (same PoW ``blockHash``). 
* ``ERR_PREV_BLOCK`` = "Previous block hash not found": raise an exception if the submitted block does not reference an already stored block header as predecessor (via ``prevBlockHash``). 
* ``ERR_LOW_DIFF`` = "PoW hash does not meet difficulty target of header": raise exception when the header's ``blockHash`` does not meet the ``target`` specified in the block header.
* ``ERR_DIFF_TARGET_HEADER`` = "Incorrect difficulty target specified in block header": raise exception if the ``target`` specified in the block header is incorrect for its block height (difficulty re-target not executed).
* ``ERR_NOT_MAIN_CHAIN`` = "Main chain submission indicated, but submitted block is on a fork": raise exception if the block header submission indicates that it is extending the current longest chain, but is actually on a (new) fork.
* ``ERR_FORK_PREV_BLOCK`` = "Previous block hash does not match last block in fork submission": raise exception if the block header does not reference the heighest block in the fork specified by ``forkId`` (via ``prevBlockHash``). 
* ``ERR_NOT_FORK`` = "Indicated fork submission, but block is in main chain":  raise exception if the block header creates a new or extends an existing fork, but is actually extending the current longest chain.


User Story
~~~~~~~~

A user calls the ``storeBlockHeader`` function when submitting a new Bitcoin block header to the chain relay. 
Thereby, the user performes the following steps:

1. The user determines if the to-be-submitted Bitcoin block header extends the longest (main) chain *tracked by the chain relay* or creates a new / extends an existing fork *tracked by the chain relay*. (Note: the chain relay does not necessarily have the same view of the Bitcoin main chain as the user's local client. See `Relay Poisoning <#>`_ for details.).
2. If the block header is on an existing *fork tracked by the chain relay*, the user looks up the ``forkId`` in the chain relay.
3. The user calls the function passing an 80bytes block header (``blockHeaderBytes``) and, if necessary, a ``forkId``, and receives one of two possible results:

    a. ``True``: the block header was successfully verified and stored.
    b. ``False``: the block header cannot be verifier (see exception raised for reason).

.. note:: The 80 bytes block header can be retrieved from the `bitcoin-rpc client <https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list>`_ by calling the `getBlock <https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/blockchain/getblock/>`_ and settign verbosity to ``0`` (``getBlock <blockHash> 0``).

Use Cases
~~~~~~~~~

**Verification of Transaction Inclusion**:
To be able to verify that a transaction is included in the Bitcoin blockchain, the corresponding block at the specified ``txBlockHeight`` must be first submitted, verified and stored in the chain relay via ``storeBlockHeader``. 



Function Sequence
~~~~~~~~~~


A block header is successfully verified and stored if the following conditions are met.

1. The ``blockHeaderBytes`` are 80 bytes long.
2. The block header is not yet stored in the chain relay (``blockHash`` is unique in chain relay storage).
3. The block header references a block already stored in the chain relay via ``prevBlockHash``.
4. The PoW hash (``blockHash``) matches the ``target`` specified in the block header
5. The ``target`` specified in the block header is correct (as per Bitcoin's difficulty adustment mechanism, see `here <https://github.com/bitcoin/bitcoin/blob/78dae8caccd82cfbfd76557f1fb7d7557c7b5edb/src/pow.cpp>`_).
6. TODO: fork handling





storeForkBlockHeader
----------------


**Detection and Tracking of Forks**:
Blockchain reorganizations or forks which occur on Bitcoin are detected and set up for tracking when a block header is submitted whose block height is lower than the currently tracked main chain height.

verifyTransaction
-----------------

The ``verifyTransaction`` function is one of the core components of the chain relay:
this function returns whether a given transaction is valid by considering a number of parameters.
The core idea is that a user submits a transaction hash including the parameters to proof to another party that  the transaction is included in the Bitcoin blockchain.
Since the verification is based on the data in the chain relay, other parties can rely on the trustworthiness of such a proof.

Sequence
~~~~~~~~

Generally, a user has to follow four steps to successfully verify a transaction:


1. The user ensures that the Bitcoin block header, in which his transaction is included, is stored in the BTCRelay (see `storeBlockHeader`_).
2. The user ensures that the block has the minimum number of required confirmations (typically ``6``).
3. The user prepares the necessary input parameters from the Bitcoin blockchain to call the ``verifyTransaction`` function. The user can receive these parameters from the `bitcoin-rpc client <https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list>`_.

    a. The *transaction hash* is the transaction that should be verified. The user should note the transaction hash when sending a Bitcoin transaction he wants to verify.
    b. The *block height* refers to the block in which the transaction is included. The user receives the block height from the `getrawtransaction <https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/rawtransactions/getrawtransaction/>`_ ``bitcoin-rpc`` method by querying for his transaction hash and receiving the ``blockindex``.
    c. The *transaction index* specifies the index of the transaction in the block. The user receives the index from the ``bitcoin-rpc`` method `getblock <https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/blockchain/getblock/>`_ by geting the index from the ``tx`` array storing the all transaction hashes in that block.
    d. The *Merkle proof* encodes how to calculate the Merkle root from the transaction hash. The user receives the proof from the ``bitcoin-rpc`` method `gettxoutproof <https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/blockchain/gettxoutproof/>`_.

4. The user submits the above parameters to the ``verifyTransaction`` function and receives one of two possible results.

    a. ``True``: the transaction is successfully verified.
    b. ``False``: the transaction cannot be verified given the input parameters provided by the user.

Conditions
~~~~~~~~~~

A transaction is successfully verified if the following conditions are met.

1. The user submits a valid *transaction hash*. The transaction hash is 32 bytes long.
2. The submitted *block height* is stored in BTCRelay.
3. The block in which the transaction is included has enough confirmations (default ``6``).
4. The user submitted a valid *Merkle proof*. The Merkle proof needs to contain the *transaction hash* in its first 32 bytes. Further, the last hash in the Merkle proof must be the block header hash in which the transaction is included.
5. The *Merkle proof* parses correctly. The *transaction hash* is combined with each hash in the Merkle proof until the resulting hash must equal the Merkle root. Details on this are included in the `Bitcoin developer reference <https://bitcoin.org/en/developer-reference#parsing-a-merkleblock-message>`_.



Use Cases
~~~~~~~~~

**Issue of Bitcoin-backed Assets**: Users can create Bitcoin-backed tokens on Polkadot by proving to the Polkadot blockchain that they have sent a number of Satoshis to a vault's Bitcoin address. To realize this, a user acts as a so-called CbA Requester. First the CbA-Requester transfers the Satoshis to the Bitcoin address of a Vault on the Bitcoin blockchain. The CbA-Requester notes the transaction hash of this transaction. Next, the CbA-Requester proves to the Polka-BTC bridge that the vault has received his Satoshis. He achieves this by ensuring that the block header of his transaction is included in the BTCRelay and has enough confirmations. He then extracts the input parameters as described in step 3 of the `Process`_ above. With these input parameters he calls the ``verifyTransaction`` to receive a successful transaction inclusion proof.


Implementation
~~~~~~~~~~~~~~

*Function Signature*

``verifyTransaction(txId, txBlockHeight, txIndex, merkleProof)``

*Parameters*

* ``txId``: the hash of the transaction.
* ``txBlockHeight``: block height at which transacton is supposedly included.
* ``txIndex``: index of transaction in the block's tx Merkle tree.
* ``merkleProof``: Merkle tree path (concatenated LE sha256 hashes).

*Returns*

* ``True``: if txId is at the claimed position in the block at the given txBlockHeight.
* ``False``: otherwise.

*Events*

* ``VerifyTransaction(txId, blockHeight, result)``: issue an event for a given txId and a blockHeight and return the result of the verification (either ``True`` or ``False``).

*Errors*

* ``ERR_INVALID_TXID = "Invalid transaction identifier"``: raise an exception when the transaction id (``txId``) is malformed.
* ``ERR_CONFIRMATIONS = "Transaction has less confirmations than requested"``: raise an exception when the number of confirmations is less than required.
* ``ERR_MERKLE_PROOF = "Invalid Merkle Proof structure"``: raise an exception when the Merkle proof is malformed.

Helper Methods
--------------

There are several helper methods available that abstract Bitcoin internals away in the main function implementation.

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
