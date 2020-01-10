.. _storage-verification:

Functions: Storage and Verification
====================================

.. _initialize:

initialize
----------
Initializes BTC-Relay with the first Bitcoin block to be tracked and initializes all data structures (see :ref:`data-model`).

.. note:: BTC-Relay **does not** have to be initialized with Bitcoin's genesis block! The first block to be tracked can be selected freely. 

.. warning:: Caution when setting the first block in BTC-Relay: only succeeding blocks can be submitted and **predecessors will be rejected**!


Specification
~~~~~~~~~~~~~~

*Function Signature*

``initialize(blockHeaderBytes, blockHeight)``

*Parameters*

* ``blockHeaderBytes``: 80 byte raw Bitcoin block header.
* ``blockHeight``: integer Bitcoin block height of the submitted block header 

*Returns*

* ``True``: if initialization is executed correctly (and for the first time only)
* ``False`` (or throws exception): otherwise.

*Events*

* ``Initialized(blockHeight, blockHash)``: if the first block header was stored successfully, emit an event with the stored block's height (``blockHeight``) and the (PoW) block hash (``blockHash``).

*Errors*

* ``ERR_ALREADY_INITIALIZED`` = "Already initialized"``: raise exception if this function is called after BTC-Relay has already been initialized.

*Substrate*

::

  fn initialize(origin, blockHeaderBytes: T::BTCBlockHeader, blockHeight: U256) -> Result {...}

Preconditions
~~~~~~~~~~~~~

* This is the first time this function is called, i.e., when BTC-Relay is being deployed. 

.. note:: Calls to ``initialize`` will likely be restricted through the governance mechanism of the BTC Parachain. This is to be defined.  



Function sequence
~~~~~~~~~~~~~~~~~

The ``initialize`` function takes as input an 80 byte raw Bitcoin block header and the corresponding Bitcoin block height, and follows the sequence below:

1. Check if ``initialize`` is called for the first time. This can be done by checking if ``BestBlock == None``. Raise ``ERR_ALREADY_INITIALIZED`` if BTC-Relay has already been initialized. 

2. Parse ``blockHeaderBytes``, extracting the ``merkleRoot`` using :ref:`extractMerkleRoot`, compute the Bitcoin block hash (``hashCurrentBlock``) of the block header (use :ref:`sha256d`), and store the block header data in ``BlockHeaders``. 

3. Store ``hashCurrentBlock`` in ``MainChain`` using the given ``blockHeight`` as key. 

4. Set ``BestBlock = hashCurrentBlock`` and ``BestBlockHeight = blockHeight``.

5. Return ``True``. 

.. warning:: Attention: the Bitcoin block header submitted to ``initialize`` must be in the Bitcoin main chain - this must be checked outside of the BTC Parachain **before** making this function call! A wrong initialization will cause the entire BTC Parachain to fail, since verification requires that all submitted blocks **must** (indirectly) point to the initialized block (i.e., have it as ancestor, just like the actual Bitcoin genesis block).

.. _storeMainChainBlockHeader:

storeMainChainBlockHeader
-------------------------
Method to submit block headers to the BTC-Relay, which extend the Bitcoin main chain (as tracked in ``MainChain`` in BTC-Relay). 
This function calls  :ref:`verifyBlockHeader` proving the 80 bytes Bitcoin block header as input, and, if the latter returns ``True``, extracts from the block header and stores (i) the hash, height and Merkle tree root of the given block header in ``BlockHeaders`` and (ii) the hash and block height in ``MainChain``.


Specification
~~~~~~~~~~~~~

*Function Signature*

``storeMainChainBlockHeader(blockHeaderBytes)``

*Parameters*

* ``blockHeaderBytes``: 80 byte raw Bitcoin block header.

*Returns*

* ``True``: if ``verifyBlockHeader`` returns ``True`` and the extraction and storage of the block header data was executed correctly. 
* ``False`` (or throws exception): otherwise.

*Events*

* ``StoreMainChainHeader(blockHeight, blockHash)``: if the block header was stored successfully, emit an event with the stored block's height (``blockHeight``) and the (PoW) block hash (``blockHash``).

*Errors*

* ``ERR_NOT_MAIN_CHAIN`` = "Main chain submission indicated, but submitted block is on a fork"``: raise exception if the block header submission indicates that it is extending the current longest chain, but is actually on a (new) fork.

*Substrate*

::

  fn storeMainChainBlockHeader(origin, blockHeaderBytes: T::BTCBlockHeader) -> Result {...}

Preconditions
~~~~~~~~~~~~~

* The to-be-submitted Bitcoin block header must extend ``MainChain`` as *tracked by the BTC-Relay*. 

.. warning:: The BTC-Relay does not necessarily have the same view of the Bitcoin blockchain as the user's local Bitcoin client. This can happen if (i) the BTC-Relay is under attack, (ii) the BTC-Relay is out of sync, or, similarly, (iii) if the user's local Bitcoin client is under attack or out of sync (see :ref:`security`). 

.. note:: The 80 bytes block header can be retrieved from the `bitcoin-rpc client <https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list>`_ by calling the `getBlock <https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/blockchain/getblock/>`_ and setting verbosity to ``0`` (``getBlock <blockHash> 0``).


Function sequence
~~~~~~~~~~~~~~~~~

The ``storeMainChainBlockHeader`` function takes as input the 80 byte raw Bitcoin block header and follows the sequence below:

1. Check that the submitted block header is extending the ``MainChain`` of BTC-Relay. That is, ``hashPrevBlock`` (extract using :ref:`extractHashPrevBlock`) must be equal to ``BestBlock``. Raise ``ERR_NOT_MAIN_CHAIN`` error if this check fails.

2. Call :ref:`verifyTransaction` passing ``blockHeaderBytes)`` as function parameter. If this call **does not return** ``True`` (i.e., fails or returns ``False``), then abort and return ``False``. 

3. Store the ``height`` and ``merkleRoot`` of the block header in the ``BlockHeaders`` map, using ``hashCurrentBlock`` as key.

    + ``hashCurrentBlock`` is the double SHA256 hash over the 80 bytes block header and can be calculated via :ref:`sha256d`.
    + ``merkleRoot`` is the root of the transaction Merkle tree of the block header. Use :ref:`extractMerkleRoot` to extract from block header. 
    + ``height`` is the blockchain height of the submitted block header. Compute by incrementing the height of the block header referenced by ``hashPrevBlock`` (retrieve from ``BlockHeaders`` using ``hashPrevBlock`` as key).

3. Emit a ``StoreMainChainBlockHeader`` event using ``height`` and ``hashCurrentBlock`` as input (``StoreMainChainHeader(height, hashCurrentBlock)``). 

4. Return ``True``.
 

.. figure:: ../figures/storeMainChainBlockHeader-sequence.png
    :alt: storeMainChainBlockHeader sequence diagram

    Sequence diagram showing the function sequence of ``storeMainChainBlockHeader``.

.. _storeForkBlockHeader:

storeForkBlockHeader
--------------------
Method to submit block headers to the BTC-Relay, which extend an existing (as tracked in ``Forks`` in BTC-Relay) of create a new *fork*. 
This function calls :ref:`verifyBlockHeader` passing the 80 bytes Bitcoin block header as parameter, and, if the latter returns ``True``, extracts from the block header and stores (i) the hash, height and Merkle tree root of the given block header in ``BlockHeaders`` and (ii) the hash of the block header as well as the starting block height of the fork and the current length (1 if a new fork) in ``Forks``.

Specification
~~~~~~~~~~~~~~

*Function Signature*

``storeForkHeader(blockHeaderBytes, forkId)``

*Parameters*

* ``blockHeaderBytes``: 80 byte raw Bitcoin block header.
* ``forkId``: integer tracked fork identifier. Set to ``-1`` if a new fork is being created (default).

*Returns*

* ``True``: if the block header passes all checks and creates a new or extends an existing fork of the currently known longest chain
* ``False`` (or raises exception): otherwise.

*Events*

* ``StoreForkHeader(forkId, blockHeight, blockHash)``: if the submitted block header is on a fork, emit an event with the fork's id (``forkId``), block height (``blockHeight``) and the (PoW) block hash (``blockHash``).
*  ``ChainReorg(newChainTip, startHeight, forkId)``: if the submitted block header on a fork results in a reorganization (fork longer than current main chain), emit an event with the block hash of the new highest block (``newChainTip``), the start block height of the fork (``startHeight``) and the fork identifier (``forkId``).

*Errors*

* ``ERR_INVALID_FORK_ID`` = "Incorrect fork identifier"``: raise an exception when a non-existent fork identifier or ``0`` (blocked for special meaning) is passed. 
* ``ERR_FORK_PREV_BLOCK`` = "Previous block hash does not match last block in fork submission`"`: raise exception if the block header does not reference the highest block in the fork specified by ``forkId`` (via ``prevBlockHash``). 
* ``ERR_NOT_FORK`` = "Indicated fork submission, but block is in main chain"``:  raise exception if the submitted block header is actually extending the current longest chain tracked by BTC-Relay (``MainChain``).

*Substrate*

::

  fn storeForkBlockHeader(origin, blockHeaderBytes: T::BTCBlockHeader, forkId: U256) -> Result {...}


Preconditions
~~~~~~~~~~~~~~

* The submitted block header must either create a new fork or extend an existing fork (in ``Forks``) as tracked by BTC-Relay.
* If the submission extends an existing fork, the ``forkId`` must be set to the correct identifier as tracked in ``Forks``.
* If the submission creates a new fork, the ``forkId`` must be set to ``-1``.

Function Sequence
~~~~~~~~~~~~~~~~~

The ``storeForkBlockHeader`` function takes as input the 80 byte raw Bitcoin block header and a ``forkId`` and follows the following sequence:

1.  Call :ref:`verifyTransaction` passing ``blockHeaderBytes`` as parameter. If this call **does not return** ``True`` (i.e., fails or returns ``False``), then abort and return ``False``. 

2. Check if ``forkId == -1``.

    a. If ``forkId == -1``, generate a new ``forkId`` and create a new entry in ``Forks``, setting the ``height`` of the block header as the ``startHeight`` of the fork.
    
    b. Otherwise:

        b.1) Check if a fork is tracked in ``Forks`` under the specified ``forkId``. If no fork can be found, raise an ``ERR_INVALID_FORK_ID`` exception and abort. 

        b.2) Check that the ``hashPrevBlock`` of the submitted block header indeed references the last block submitted to the fork, specified by ``forkId``. Raise ``ERR_FORK_PREV_BLOCK`` exception and abort if this check fails.


3. Store the ``height`` and ``merkleRoot`` of the block header in the ``blockHeaders`` map, using ``hashCurrentBlock`` as key (compute using :ref:`sha256d`).

4. Update ``Fork[forkId]`` entry, incrementing the fork ``length`` and inserting ``hashCurrentBlock`` into the list of block hashes contained in that fork (``forkBlockHashes``).  

5. Emit a ``StoreForkBlockHeader`` event using ``height`` and ``hashCurrentBlock`` as input (``StoreMainChainHeader(height, hashCurrentBlock)``). 

6. Check if the fork at ``forkId`` has become longer than the current ``MainChain``. This is the case if the block height ``height`` of the submitted block header exceeds the ``BestBlockHeight``. 

    a. If ``height > BestBlockHeight`` call ``chainReorg(forkId)`` and return the value returned form this call.

4. Return ``True``.

.. figure:: ../figures/storeForkBlockHeader-sequence.png
    :alt: storeForkBlockHeader sequence diagram

    Sequence diagram showing the function sequence of ``storeForkBlockHeader``.


.. _verifyBlockHeader:

verifyBlockHeader
-----------------

The ``verifyBlockHeader`` function parses and verifies Bitcoin block
headers. 

.. Warning:: This function must called and return ``True`` **before**  a Bitcoin block header is stored in the BTC-Relay (i.e., must be called by the :ref:`storeMainChainBlockHeader` and :ref:`storeForkBlockHeader` functions).

.. note:: This function does not check whether the submitted block header extends the main chain or a fork. This check is performed in :ref:`storeMainChainBlockHeader` and :ref:`storeForkBlockHeader` respectively.

Other operations, such as verification of transaction inclusion, can only be executed once a block header has been verified and consequently stored in the BTC-Relay. 


Specification
~~~~~~~~~~~~~~
*Function Signature*

``verifyBlockHeader(blockHeaderBytes)``

*Parameters*

* ``blockHeaderBytes``: 80 byte raw Bitcoin block header.


*Returns*

* ``True``: if the block header passes all checks.
* ``False`` (or throws exception): otherwise.

*Errors*

* ``ERR_INVALID_HEADER_SIZE`` = "Invalid block header size"``: raise exception if the submitted block header is not exactly 80 bytes long.
* ``ERR_DUPLICATE_BLOCK`` = "Block already stored"``: raise exception if the submitted block header is already stored in BTC-Relay (duplicate PoW ``blockHash``). 
* ``ERR_PREV_BLOCK`` = "Previous block hash not found"``: raise exception if the submitted block does not reference an already stored block header as predecessor (via ``prevBlockHash``). 
* ``ERR_LOW_DIFF`` = "PoW hash does not meet difficulty target of header"``: raise exception when the header's ``blockHash`` does not meet the ``target`` specified in the block header.
* ``ERR_DIFF_TARGET_HEADER`` = "Incorrect difficulty target specified in block header"``: raise exception if the ``target`` specified in the block header is incorrect for its block height (difficulty re-target not executed).

*Substrate*

::

  fn verifyBlockHeader(origin, blockHeaderBytes: T::BTCBlockHeader) -> Result {...}

Function Sequence
~~~~~~~~~~~~~~~~~
The ``verifyBlockHeader`` function takes as input the 80 byte raw Bitcoin block header and follows the sequence below:

1. Check that the ``blockHeaderBytes`` is 80 bytes long. Raise ``ERR_INVALID_HEADER_SIZE`` exception and abort otherwise.
2. Check that the block header is not yet stored in BTC-Relay (``blockHash`` is unique in ``blockHeaders``). Raise ``ERR_DUPLICATE_BLOCK`` exception and abort otherwise. 
3. Check that the previous block referenced by the submitted block header (``hashPrevBlock``) exists in ``BlockHeaders``. Raise ``ERR_PREV_BLOCK`` exception and abort otherwise. 
4. Check that the Proof-of-Work hash (``blockHash``) is below the ``target`` specified in the block header. Raise ``ERR_LOW_DIFF`` exception and abort otherwise.
5. Check that the ``target`` specified in the block header is correct by calling ``correctTarget(hashPrevBlock, height, target)`` (as per Bitcoin's difficulty adustment mechanism, see `here <https://github.com/bitcoin/bitcoin/blob/78dae8caccd82cfbfd76557f1fb7d7557c7b5edb/src/pow.cpp>`_). If this call returns ``False``, raise ``ERR_DIFF_TARGET_HEADER`` exception and abort. 
6. Return ``True``

.. figure:: ../figures/verifyBlockHeader-sequence.png
    :alt: verifyBlockHeader sequence diagram

    Sequence diagram showing the function sequence of ``verifyBlockHeader``.


.. _verifyTransaction:

verifyTransaction
-----------------

The ``verifyTransaction`` function is one of the core components of the BTC-Relay: this function checks if a given transaction was indeed included in a given block (as stored in ``BlockHeaders`` and tracked by ``MainChain``), by reconstructing the Merkle tree root (given a Merkle proof). Also checks if sufficient confirmations have passed since the inclusion of the transaction (considering the current state of the BTC-Relay ``MainChain``).

Specification
~~~~~~~~~~~~~

*Function Signature*

``verifyTransaction(txId, txBlockHeight, txIndex, merkleProof, confirmations)``

*Parameters*

* ``txId``: 32 byte hash identifier of the transaction.
* ``txBlockHeight``: integer block height at which transaction is supposedly included.
* ``txIndex``: integer index of transaction in the block's tx Merkle tree.
* ``merkleProof``: Merkle tree path (concatenated LE sha256 hashes, dynamic sized).
* ``confirmations``: integer number of confirmation required.

.. note:: The Merkle proof for a Bitcoin transaction can be retrieved using the ``bitcoin-rpc`` `gettxoutproof <https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/blockchain/gettxoutproof/>`_ method and dropping the first 170 characters.


*Returns*

* ``True``: if the given ``txId`` appears in at the position specified by ``txIndex`` in the transaction Merkle tree of the block at height ``blockHeight`` and sufficient confirmations have passed since inclusion.
* ``False`` (or throws exception): otherwise.

*Events*

* ``VerifyTransaction(txId, txBlockHeight, confirmations)``: if verification was successful, emit an event specifying the ``txId``, the ``blockHeight`` and the requested number of ``confirmations``.

*Errors*

* ``ERR_INVALID_TXID = "Invalid transaction identifier"``: raise exception if the transaction identifier (``txId``) is malformed.
* ``ERR_CONFIRMATIONS = "Transaction has less confirmations than requested"``: raise exception if the block in which the transaction specified by ``txId`` was included has less confirmations than requested.
* ``ERR_MERKLE_PROOF = "Invalid Merkle Proof structure"``: raise exception if the Merkle proof is malformed.

*Substrate*

::

  fn verifyTransaction(origin, txId: T::Hash, txBlockHeight: U256, txIndex: u64, merkleProof: String, confirmations: u64) -> Result {...}


Function Sequence
~~~~~~~~~~~~~~~~~

The ``verifyTransaction`` function follows the function sequence below:


1. Check that ``txId`` is 32 bytes long. Raise ``ERR_INVALID_FORK_ID`` error if this check fails. 

2. Check that the current ``BestBlockHeight`` exceeds ``blockHeight`` by the specified number of ``confirmation``. Raise ``ERR_CONFIRMATIONS`` if this check fails. 

3. Extract the block header from ``BlockHeaders`` using the ``blockHash`` tracked in ``MainChain`` at the passed ``blockHeight``.    

3. Check that the first 32 bytes of ``merkleProof`` are equal to the ``txId`` and the last 32 bytes are equal to the ``merkleRoot`` of the specified block header. Also check that the ``merkleProof`` size is either exactly 32 bytes, or is 64 bytes or more and a power of 2. Raise ``ERR_MERKLE_PROOF`` error if one of these checks fails.

4. Call :ref:`computeMerkle` passing ``txId``, ``txIndex`` and ``merkleProof`` as parameters. 

  a. If this call returns the ``merkleRoot``, emit a ``VerifyTransaction(txId, blockHeight, confirmations)`` event and return ``True``.
  
  b. Otherwise return ``False``. 

.. figure:: ../figures/verifyTransaction-sequence.png
    :alt: verifyTransaction sequence diagram

    The steps to verify a transaction in the ``verifyTransaction`` function.



