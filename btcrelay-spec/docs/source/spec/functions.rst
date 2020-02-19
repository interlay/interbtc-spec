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

*Events*

* ``Initialized(blockHeight, blockHash)``: if the first block header was stored successfully, emit an event with the stored block's height (``blockHeight``) and the (PoW) block hash (``blockHash``).

*Errors*

* ``ERR_ALREADY_INITIALIZED = "Already initialized"``: return error if this function is called after BTC-Relay has already been initialized.

*Substrate*

::

  fn initialize(origin, blockHeaderBytes: RawBlockHeader, blockHeight: U256) -> Result {...}

Preconditions
~~~~~~~~~~~~~

* This is the first time this function is called, i.e., when BTC-Relay is being deployed. 

.. note:: Calls to ``initialize`` will likely be restricted through the Governance Mechanism of the BTC Parachain. This is to be defined.  



Function sequence
~~~~~~~~~~~~~~~~~

The ``initialize`` function takes as input an 80 byte raw Bitcoin block header and the corresponding Bitcoin block height, and follows the sequence below:

1. Check if ``initialize`` is called for the first time. This can be done by checking if ``BestBlock == None``. Return ``ERR_ALREADY_INITIALIZED`` if BTC-Relay has already been initialized. 

2. Parse ``blockHeaderBytes``, extracting  the ``merkleRoot`` (:ref:`extractMerkleRoot`), ``timestamp`` (:ref:`extractTimestamp`) and ``target`` (:ref:`extractNBits` and :ref:`nBitsToTarget`) from ``blockHeaderBytes``, and compute the block hash (``hashCurrentBlock``) using :ref:`sha256d` (passing ``blockHeaderBytes`` as parameter).

3. Create a new ``BlockChain`` entry in ``Chains``:

    - ``chainId =``:ref:`getChainsCounter`
    - ``maxHeight = blockHeight``
    - ``noData = False``
    - ``invalid = False``
    - Insert ``hashCurrentBlock`` in the ``chain`` mapping using ``blockHeight`` as key. 

4. Insert a pointer to ``BlockChain`` into ``ChainsIndex`` using  ``chainId`` as key.

5. Store a new ``BlockHeader`` struct containing ``merkleRoot``, ``blockHeight``, ``timestamp``, ``target``, and a pointer (``chainRef``) to the ``BlockChain`` struct - as associated with this block header - in ``BlockHeaders``, using ``hashCurrentBlock`` as key. 

6. Set ``BestBlock = hashCurrentBlock`` and ``BestBlockHeight = blockHeight``.

7. Emit a ``Initialized`` event using ``height`` and ``hashCurrentBlock`` as input (``Initialized(height, hashCurrentBlock)``). 

.. warning:: Attention: the Bitcoin block header submitted to ``initialize`` must be in the Bitcoin main chain - this must be checked outside of the BTC Parachain **before** making this function call! A wrong initialization will cause the entire BTC Parachain to fail, since verification requires that all submitted blocks **must** (indirectly) point to the initialized block (i.e., have it as ancestor, just like the actual Bitcoin genesis block).

.. _storeBlockHeader:

storeBlockHeader
----------------
Method to submit block headers to the BTC-Relay. This function calls  :ref:`verifyBlockHeader` providing the 80 bytes Bitcoin block header as input, and, if the latter returns ``True``, extracts from the block header and stores the hash, height and Merkle tree root of the given block header in ``BlockHeaders``.
If the block header extends an existing ``BlockChain`` entry in ``Chains``, it appends the block hash to the ``chains`` mapping and increments the ``maxHeight``. Otherwise, a new ``Blockchain`` entry is created.

Specification
~~~~~~~~~~~~~

*Function Signature*

``storeBlockHeader(blockHeaderBytes)``

*Parameters*

* ``blockHeaderBytes``: 80 byte raw Bitcoin block header.

*Events*

* ``StoreMainChainHeader(blockHeight, blockHash)``: if the block header was successful appended to the currently longest chain (*main chain*) emit an event with the stored block's height (``blockHeight``) and the (PoW) block hash (``blockHash``).
* ``StoreForkHeader(forkId, blockHeight, blockHash)``: f the block header was successful appended to a new or existing fork, emit an event with the block height (``blockHeight``) and the (PoW) block hash (``blockHash``).


*Errors*

* ``ERR_SHUTDOWN = "BTC Parachain has shut down"``: the BTC Parachain has been shutdown by a manual intervention of the Governance Mechanism.

*Substrate*

::

  fn storeBlockHeader(origin, blockHeaderBytes: RawBlockHeader) -> Result {...}

Preconditions
~~~~~~~~~~~~~

* The BTC Parachain status must not be set to ``SHUTDOWN: 3``.

.. warning:: The BTC-Relay does not necessarily have the same view of the Bitcoin blockchain as the user's local Bitcoin client. This can happen if (i) the BTC-Relay is under attack, (ii) the BTC-Relay is out of sync, or, similarly, (iii) if the user's local Bitcoin client is under attack or out of sync (see :ref:`security`). 

.. note:: The 80 bytes block header can be retrieved from the `bitcoin-rpc client <https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list>`_ by calling the `getBlock <https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/blockchain/getblock/>`_ and setting verbosity to ``0`` (``getBlock <blockHash> 0``).


Function sequence
~~~~~~~~~~~~~~~~~

The ``storeBlockHeader`` function takes as input the 80 byte raw Bitcoin block header and follows the sequence below:

1. Check if the BTC Parachain status is set to ``SHUTDOWN``. If true, return ``ERR_SHUTDOWN``. 

2. Call :ref:`verifyBlockHeader` passing ``blockHeaderBytes`` as function parameter. If this call **returns an error** , then abort and return the raised error. If successful, this call returns the hash of the previous block (``hashPrevBlock``), referenced in ``blockHeaderBytes``, as stored in ``BlockHeaders``.

3. Determine which ``BlockChain`` entry in ``Chains`` this block header is extending, or if it is a new fork and hence a new ``BlockChain`` entry needs to be created. For this, get the ``prevBlockHeader`` stored in ``BlockHeaders`` with ``hashPrevBlock`` and use its ``chainRef`` pointer as key to lookup the associated ``BlockChain`` struct. Then, check if the  ``prevBlockHeader.blockHeight`` (as referenced by ``hashPrevBlock``) is equal  to ``BlockChain.maxHeight``.

   a. If not equal (can only be less in this case), then the current submission is creating a **new fork**. 
     
    i ) Create a new ``BlockChain`` struct, setting ``BlockChain.maxHeight = BlockHeader.blockHeight + 1`` (as referenced in ``hashPrevBlock``), and appending ``hashCurrentBlock`` to the (currently empty) ``BlockChain.chain`` mapping. 
     
    ii ) Insert the new ``BlockChain`` into ``Chains``.
       
  b. Otherwise, if equal, then the current submission is **extending** the ``BlockChain`` referenced by ``BlockHeader.chainRef`` (as per``hashPrevBlock``). 

    i )  Append the ``hashCurrentBlock`` to the ``chain``  map in ``BlockChain`` and increment ``maxHeight``

    ii ) Check ordering in ``Chains`` needs updating. For this, call :ref:`checkAndDoReorg` passing the pointer to ``BlockChain`` as parameter.
  

4. Extract the ``merkleRoot`` (:ref:`extractMerkleRoot`), ``timestamp`` (:ref:`extractTimestamp`) and ``target`` (:ref:`extractNBits` and :ref:`nBitsToTarget`) from ``blockHeaderBytes``, and compute the block hash using :ref:`sha256d` (passing ``blockHeaderBytes`` as parameter).

5.  Store the ``height``, ``merkleRoot``, ``timestamp`` and ``target`` as a new entry in the ``BlockHeaders`` map, using ``hashCurrentBlock`` as key.

    + ``merkleRoot`` is the root of the transaction Merkle tree of the block header. Use :ref:`extractMerkleRoot` to extract from block header. 
    + ``timestamp`` is the UNIX timestamp indicating when the block was generated in Bitcoin.
    + ``target`` indicated the PoW difficulty target of this block.

6. Emit event. 

   a. If submission was to *main chain* (``BlockChain`` entry with highest ``maxChain``), emit ``StoreMainChainBlockHeader`` event using ``height`` and ``hashCurrentBlock`` as input (``StoreMainChainHeader(height, hashCurrentBlock)``). 

   b. If submission was to another ``BlockChain`` entry (new or existing), emit ``StoreForkHeader(height, hashCurrentBlock)``.

7. Return.


.. figure:: ../figures/storeBlockHeader-sequence.png
    :alt: storeBlockHeader sequence diagram

    Sequence diagram showing the function sequence of :ref:`storeBlockHeader`.


.. _checkAndDoReorg:

checkAndDoReorg
---------------

This function is called from :ref:`storeBlockHeader` and checks if a block header submission resulted in a chain reorganization.
Updates the ordering in / re-balances ``Chains`` if necessary.


Specification
~~~~~~~~~~~~~

*Function Signature*

``checkAndDoReorg(blockChain)``

*Parameters*

* ``&blockChain``: pointer to a ``BlockChain`` entry in ``Chains``. 

*Events*

*  ``ChainReorg(newChainTip, blockHeight, forkDepth)``: if the submitted block header on a fork results in a reorganization (fork longer than current main chain), emit an event with the block hash of the new highest block (``newChainTip``), the new maximum block height (``blockHeight``) and the depth of the fork (``forkDepth``).

*Substrate*

::

  fn checkAndDoReorg(blockChain: &BlockChain) -> Result {...}


Function Sequence
~~~~~~~~~~~~~~~~~

1.  Check ordering of the ``BlockChain`` entry needs updating. For this, check the ``maxHeight`` of the "next-highest" ``BlockChain`` (parent in heap or predecessor in sorted linked list). 

   a. If ``BlockChain`` is the top-level element, do nothing.
   
   b. Else if the "next-highest" entry has a lower ``maxHeight``, switch position - continue, until reaching the "top" of the data structure or a ``BlockChain`` entry with a higher ``maxHeight``. 

2. If ordering was updated, check if the top-level element in the ``Chains`` data structure changed. If yes, emit a ``ChainReorg(hashCurrentBlock, blockHeight, forkDepth)``, where ``forkDepth`` is the size of the ``chain`` mapping in the new top-level ``BlockChain`` (new *main chain*) entry.

3. Check that ``noData`` or ``invalid`` are both set to ``False`` for this  ``BlockChain`` entry. If this is the case, check if we need to update the BTC Parachain state.

   a. If ``Errors`` in :ref:`security` contains ``NO_DATA_BTC_RELAY`` or ``INVALID_BTC_RELAY`` call :ref:`recoverFromLIQUIDATION` to recover the BTC Parachain from ``LIQUIDATION`` error.

3. Return.

.. note:: The exact implementation of :ref:`checkAndDoReorg` depends on the data structure used for ``Chains``.



.. _verifyBlockHeader:

verifyBlockHeader
-----------------

The ``verifyBlockHeader`` function parses and verifies Bitcoin block headers. 
If all checks are successful, returns the hash of the predecessor of the passed block header, as stored in ``BlockHeaders``.

.. note:: This function does not check whether the submitted block header extends the main chain or a fork. This check is performed in :ref:`storeBlockHeader`.



Specification
~~~~~~~~~~~~~~
*Function Signature*

``verifyBlockHeader(blockHeaderBytes)``

*Parameters*

* ``blockHeaderBytes``: 80 byte raw Bitcoin block header.


*Returns*

* ``hashPrevBlock``: if all checks pass successfully, return the hash of the previous block header, as stored in ``BlockHeaders``.

*Errors*

* ``ERR_INVALID_HEADER_SIZE = "Invalid block header size"``: return error if the submitted block header is not exactly 80 bytes long.
* ``ERR_DUPLICATE_BLOCK = "Block already stored"``: return error if the submitted block header is already stored in BTC-Relay (duplicate PoW ``blockHash``). 
* ``ERR_PREV_BLOCK = "Previous block hash not found"``: return error if the submitted block does not reference an already stored block header as predecessor (via ``prevBlockHash``). 
* ``ERR_LOW_DIFF = "PoW hash does not meet difficulty target of header"``: return error when the header's ``blockHash`` does not meet the ``target`` specified in the block header.
* ``ERR_DIFF_TARGET_HEADER = "Incorrect difficulty target specified in block header"``: return error if the ``target`` specified in the block header is incorrect for its block height (difficulty re-target not executed).

*Substrate*

::

  fn verifyBlockHeader(origin, blockHeaderBytes: RawBlockHeader) -> H256 {...}

Function Sequence
~~~~~~~~~~~~~~~~~
The ``verifyBlockHeader`` function takes as input the 80 byte raw Bitcoin block header and follows the sequence below:

1. Check that the ``blockHeaderBytes`` is 80 bytes long. Return ``ERR_INVALID_HEADER_SIZE`` exception and abort otherwise.

2. Compute ``hashCurrentBlock``, the double SHA256 hash over the 80 bytes block header, using :ref:`sha256d` (passing ``blockHeaderBytes`` as parameter).  

3. Check that the block header is not yet stored in BTC-Relay (``hashCurrentBlock`` must not yet be in ``BlockHeaders``). Return ``ERR_DUPLICATE_BLOCK`` otherwise. 

4. Get the ``BlockHeader`` referenced by the submitted block header via ``hashPrevBlock`` (extract from ``blockHeaderBytes`` using :ref:`extractHashPrevBlock`). Return ``ERR_PREV_BLOCK`` if no such entry was found.

5. Check that the Proof-of-Work hash (``blockHash``) is below the ``target`` specified in the block header. Return ``ERR_LOW_DIFF`` otherwise.

6. Check that the ``target`` specified in the block header (extract using :ref:`extractNBits` and :ref:`nBitsToTarget`) is correct by calling :ref:`checkCorrectTarget` passing ``hashPrevBlock``, ``height`` and ``target`` as parameters (as per Bitcoin's difficulty adjustment mechanism, see `here <https://github.com/bitcoin/bitcoin/blob/78dae8caccd82cfbfd76557f1fb7d7557c7b5edb/src/pow.cpp>`_). If this call returns ``False``, return ``ERR_DIFF_TARGET_HEADER``. 

7. Return ``hashPrevBlock``.

.. figure:: ../figures/verifyBlockHeader-sequence.png
    :alt: verifyBlockHeader sequence diagram

    Sequence diagram showing the function sequence of :ref:`verifyBlockHeader`.




.. _verifyTransaction:

verifyTransactionInclusion
--------------------------

The ``verifyTransactionInclusion`` function is one of the core components of the BTC-Relay: this function checks if a given transaction was indeed included in a given block (as stored in ``BlockHeaders`` and tracked by ``Chains``), by reconstructing the Merkle tree root (given a Merkle proof). Also checks if sufficient confirmations have passed since the inclusion of the transaction (considering the current state of the BTC-Relay ``Chains``).

Specification
~~~~~~~~~~~~~

*Function Signature*

``verifyTransactionInclusion(txId, txBlockHeight, txIndex, merkleProof, confirmations)``

*Parameters*

* ``txId``: 32 byte hash identifier of the transaction.
* ``txBlockHeight``: integer block height at which transaction is supposedly included.
* ``txIndex``: integer index of transaction in the block's tx Merkle tree.
* ``merkleProof``: Merkle tree path (concatenated LE sha256 hashes, dynamic sized).
* ``confirmations``: integer number of confirmation required.

.. note:: The Merkle proof for a Bitcoin transaction can be retrieved using the ``bitcoin-rpc`` `gettxoutproof <https://bitcoin-rpc.github.io/en/doc/0.17.99/rpc/blockchain/gettxoutproof/>`_ method and dropping the first 170 characters.


*Returns*

* ``True``: if the given ``txId`` appears in at the position specified by ``txIndex`` in the transaction Merkle tree of the block at height ``blockHeight`` and sufficient confirmations have passed since inclusion.
* Error otherwise.

*Events*

* ``VerifyTransaction(txId, txBlockHeight, confirmations)``: if verification was successful, emit an event specifying the ``txId``, the ``blockHeight`` and the requested number of ``confirmations``.

*Errors*

* ``ERR_INVALID = "BTC-Relay has detected an invalid block in the current main chain, and has been halted"``: the BTC Parachain has been halted because Staked Relayers reported an invalid block.
* ``ERR_NO_DATA = "BTC-Relay has a NO_DATA failure and the requested block cannot be verified reliably": the ``txBlockHeight`` is greater or equal to the hight of a ``BlockHeader`` which is flagged with ``NO_DATA_BTC_RELAY``.
* ``ERR_SHUTDOWN = "BTC Parachain has shut down"``: the BTC Parachain has been shutdown by a manual intervention of the Governance Mechanism.
* ``ERR_MALFORMED_TXID = "Malformed transaction identifier"``: return error if the transaction identifier (``txId``) is malformed.
* ``ERR_CONFIRMATIONS = "Transaction has less confirmations than requested"``: return error if the block in which the transaction specified by ``txId`` was included has less confirmations than requested.
* ``ERR_INVALID_MERKLE_PROOF = "Invalid Merkle Proof"``: return error if the Merkle proof is malformed or fails verification (does not hash to Merkle root).


*Substrate*

::

  fn verifyTransactionInclusion(txId: H256, txBlockHeight: U256, txIndex: u64, merkleProof: String, confirmations: U256) -> Result {...}

Preconditions
~~~~~~~~~~~~~

* If the BTC Parachain status is set to ``PARTIAL: 1``, transaction verification is disabled for the latest blocks.
* The BTC Parachain status must not be set to ``HALTED: 2``. If ``HALTED`` is set, all transaction verification is disabled.
* The BTC Parachain status must not be set to ``SHUTDOWN: 3``. If ``SHUTDOWN`` is set, all transaction verification is disabled.

Function Sequence
~~~~~~~~~~~~~~~~~

The ``verifyTransactionInclusion`` function follows the function sequence below:

1. Check if the BTC Parachain status is set to ``SHUTDOWN``. If true, return ``ERR_SHUTDOWN`` and return. 

2. Check if the BTC Parachain status is set to ``ERROR``. If yes, retrieve ``Errors`` from the *Security* module of PolkaBTC is set to ``INVALID_BTC_RELAY``.

3. If ``Errors`` contains ``INVALID_BTC_RELAY``, abort and return a ``ERR_INVALID`` error.

4. If ``Errors`` contains ``NO_DATA_BTC_RELAY``, the first ``NO_DATA_BTC_RELAY`` block (i.e., a block where ``BlockHeader.noData == True``). For this, 

  a. Retrieve the top-most ``BlockChain`` entry from ``Chains``,
  b. Iterate over ``BlockChain.chain`` until a block header with ``BlockHeader.noData == True`` is found. 
  c. If ``txBlockHeight`` is greater or equal to the block height of the found block, abort and return ``ERR_NO_DATA``.

5. Check if the BTC Parachain status is set to ``NO_DATA_BTC_RELAY``. If true, check if the ``txBlockHeight`` is equal to or greater than the first ``NO_DATA_BTC_RELAY`` block. If false, return ``ERR_PARTIAL`` and return.

6. Check that ``txId`` is 32 bytes long. Return ``ERR_INVALID_FORK_ID`` error if this check fails. 

7. Check that the current ``BestBlockHeight`` exceeds ``txBlockHeight`` by the specified number of ``confirmations``. Return ``ERR_CONFIRMATIONS`` if this check fails. 

8. Extract the block header from ``BlockHeaders`` using the ``blockHash`` tracked in ``Chains`` at the passed ``txBlockHeight``.  

9. Check that the first 32 bytes of ``merkleProof`` are equal to the ``txId`` and the last 32 bytes are equal to the ``merkleRoot`` of the specified block header. Also check that the ``merkleProof`` size is either exactly 32 bytes, or is 64 bytes or more and a power of 2. Return ``ERR_INVALID_MERKLE_PROOF`` if one of these checks fails.

10. Call :ref:`computeMerkle` passing ``txId``, ``txIndex`` and ``merkleProof`` as parameters. 

  a. If this call returns the ``merkleRoot``, emit a ``VerifyTransaction(txId, txBlockHeight, confirmations)`` event and return ``True``.
  
  b. Otherwise return ``ERR_INVALID_MERKLE_PROOF``. 

.. figure:: ../figures/verifyTransaction-sequence.png
    :alt: verifyTransactionInclusion sequence diagram

    The steps to verify a transaction in the :ref:`verifyTransactionInclusion` function.





.. _validateTransaction:

validateTransaction
--------------------

Given a raw Bitcoin transaction, this function 

1) Parses and extracts 

   a. the value of the first output, 
   b. the recipient address of the first output and 
   c. the OP_RETURN value of the second output of the transaction.

2) Validates the extracted values against the function parameters.

.. note:: See :ref:`bitcoin-data-model` for more details on the transaction structure, and :ref:`accepted-tx-format` for the transaction format of Bitcoin transactions validated in this function.

Specification
~~~~~~~~~~~~~

*Function Signature*

``validateTransaction(txId, rawTx, paymentValue, recipientBtcAddress, opReturnId)``

*Parameters*

* ``txId``: 32 byte hash identifier of the transaction.
* ``rawTx``:  raw Bitcoin transaction including the transaction inputs and outputs.
* ``paymentValue``: integer value of BTC sent in the (first) *Payment UTXO* of transaction.
* ``recipientBtcAddress``: 20 byte Bitcoin address of recipient of the BTC in the (first) *Payment UTXO*.
* ``opReturnId``: 32 byte hash identifier expected in OP_RETURN (see :ref:`_replace-attacks`).

*Returns*

* ``True``: if the transaction was successfully parsed and validation of the passed values was correct. 
* Error otherwise.

*Events*

* ``ValidateTransaction(txId, paymentValue, recipientBtcAddress, opReturnId)``: if parsing and validation was successful, emit an event specifying the ``txId``, the ``paymentValue``, the ``recipientBtcAddress`` and the ``opReturnId``.

*Errors*

* ``ERR_SHUTDOWN = "BTC Parachain has shut down"``: the BTC Parachain has been shutdown by a manual intervention of the Governance Mechanism.
* ``ERR_INVALID = "BTC-Relay has detected an invalid block in the current main chain, and has been halted"``: the BTC Parachain has been halted because Staked Relayers reported an invalid block.
* ``ERR_INVALID_TXID = "Transaction hash does not match given txid"``: return error if the transaction identifier (``txId``) does not match the actual hash of the transaction.
* ``ERR_INSUFFICIENT_VALUE = "Value of payment below requested amount"``: return error the value of the (first) *Payment UTXO* is lower than ``paymentValue``.
* ``ERR_TX_FORMAT = "Transaction has incorrect format"``: return error if the transaction has an incorrect format (see :ref:`accepted-tx-format`).
* ``ERR_WRONG_RECIPIENT = "Incorrect recipient Bitcoin address"``: return error if the recipient specified in the (first) *Payment UTXO* does not match the given ``recipientBtcAddress``.
* ``ERR_INVALID_OPRETURN = "Incorrect identifier in OP_RETURN field"``: return error if the OP_RETURN field of the (second) *Data UTXO* does not match the given ``opReturnId``.

*Substrate*

::

  fn validateTransaction(txId: H256, rawTx: String, paymentValue: Balance, recipientBtcAddress: H160, opReturnId: H256) -> Result {...}

Preconditions
~~~~~~~~~~~~~

* The BTC Parachain status must not be set to ``SHUTDOWN: 3``. If ``SHUTDOWN`` is set, all transaction validation is disabled.

Function Sequence
~~~~~~~~~~~~~~~~~

See the `raw Transaction Format section in the Bitcoin Developer Reference <https://bitcoin.org/en/developer-reference#raw-transaction-format>`_ for a full specification of Bitcoin's transaction format (and how to extract inputs, outputs etc. from the raw transaction format). 

1. Check if the BTC Parachain status is set to ``SHUTDOWN``. If true, return ``ERR_SHUTDOWN`` and return. 

2. Check if the BTC Parachain status is set to ``ERROR``. If yes, retrieve ``Errors`` from the *Security* module of PolkaBTC is set to ``INVALID_BTC_RELAY``. If ``Errors`` contains ``INVALID_BTC_RELAY``, abort and return a ``ERR_INVALID`` error.

3. Check that the double SHA256 hash of ``rawTx`` (use :ref:`sha256d`) equals to the ``txid``. Return ``ERR_INVALID_TXID`` if this check fails. 

4. Extract the ``outputs`` from ``rawTx`` using :ref:`extractOutputs`.

  a. Check that the transaction (``rawTx``) has at least 2 outputs. The first output (*Payment UTXO*) must be a `P2PKH <https://en.bitcoinwiki.org/wiki/Pay-to-Pubkey_Hash>`_ or `P2WPKH <https://github.com/libbitcoin/libbitcoin-system/wiki/P2WPKH-Transactions>`_ output. The second output (*Data UTXO*) must be an `OP_RETURN <https://bitcoin.org/en/transactions-guide#term-null-data>`_ output. Raise ``ERR_TX_FORMAT`` if this check fails. 

5. Extract the value of the (first) *Payment UTXO* (``outputs[0]``) using :ref:`extractOutputValue` and check that it is equal (or greater) than ``paymentValue``. Return ``ERR_INSUFFICIENT_VALUE`` if this check fails. 

6. Extract the Bitcoin address specified as recipient in the (first) *Payment UTXO* (``outputs[0]``)  using :ref:`extractOutputAddress`  and check that it matches ``recipientBtcAddress``. Return ``ERR_WRONG_RECIPIENT`` if this check fails, or the error returned by :ref:`extractOutputAddress` (if the output was malformed).

7. Extract the OP_RETURN value from the (second) *Data UTXO* (``outputs[1]``) using :ref:`extractOPRETURN` and check that it matches ``opReturnId``. Return ``ERR_INVALID_OPRETURN`` error if this check fails, or the error returned by :ref:`extractOPRETURN` (if the output was malformed).

8. Return ``True``.


.. _flagBlockError:

flagBlockError
----------------

Flags tracked Bitcoin block headers when Staked Relayers report and agree on a ``NO_DATA_BTC_RELAY`` or ``INVALID_BTC_RELAY`` failure.

.. attention:: This function **does not** validate the Staked Relayers accusation. Instead, it is put up to a majority vote among all Staked Relayers in the form of a  

.. note:: This function can only be called from the *Security* module of PolkaBTC, after Staked Relayers have achieved a majority vote on a BTC Parachain status update indicating a BTC-Relay failure.

Specification
~~~~~~~~~~~~~~

*Function Signature*

``flagBlockError(blockHash, errors)``


*Parameters*

* ``blockHash``: SHA256 block hash of the block containing the error. 
* ``errors``: list of ``ErrorCode`` entries which are to be flagged for the block with the given blockHash. Can be "NO_DATA_BTC_RELAY" or "INVALID_BTC_RELAY".

*Returns*

* ``None``

*Events*

* ``FlagBTCBlockError(blockHash, chainId, errors)`` - emits an event indicating that a Bitcoin block hash (identified ``blockHash``) in a ``BlockChain`` entry (``chainId``) was flagged with errors (``errors`` list of ``ErrorCode`` entries).

*Errors*

* ``ERR_UNKNOWN_ERRORCODE = "The reported error code is unknown"``: The reported ``ErrorCode`` can only be ``NO_DATA_BTC_RELAY`` or ``INVALID_BTC_RELAY``.
* ``ERR_BLOCK_NOT_FOUND  = "No Bitcoin block header found with the given block hash"``: No ``BlockHeader`` entry exists with the given block hash.
* ``ERR_ALREADY_REPORTED = "This error has already been reported for the given block hash and is pending confirmation"``: The error reported for the given block hash is currently pending a vote by Staked Relayers.

*Substrate* ::

  fn reportBTCRelayFailure(chainId: U256, errorCode: ErrorCode) -> Result {...}

Function Sequence
.................

1. Check if ``errors`` contains  ``NO_DATA_BTC_RELAY`` or ``INVALID_BTC_RELAY``. If neither match, return ``ERR_UNKNOWN_ERRORCODE``.

2. Retrieve the ``BlockHeader`` entry from ``BlockHeaders`` using ``blockHash``. Return ``ERR_BLOCK_NOT_FOUND`` if no block header can be found.

3. Set error code of the ``BlockHeader``.

   a. If ``errors`` contains ``NO_DATA_BTC_RELAY``, set ``BlockHeader.noData = True`` and set ``BlockChain.noData = True`` accordingly (as per the ``BlockHeader.chainRef``).

   b. If ``errors`` contains ``INVALID_BTC_RELAY``, set ``BlockHeader.invalid = True`` and set ``BlockChain.noData = True`` accordingly (as per the ``BlockHeader.chainRef``).

4. Emit ``FlagBTCBlockError(blockHash, chainId, errors)`` event, with the given ``blockHash``, the ``chainId`` of the flagged ``BlockChain`` entry and the given ``errors`` as parameters.

5. Return



.. _clearBlockError:

clearBlockError
------------------

Clears ``ErrorCode`` entries given as parameters from the status of a ``BlockHeader``.  Can be ``NO_DATA_BTC_RELAY`` or ``INVALID_BTC_RELAY`` failure.

.. note:: This function can only be called from the *Security* module of PolkaBTC, after Staked Relayers have achieved a majority vote on a BTC Parachain status update indicating that a ``BlockHeader`` entry no longer has the specified errors.


Specification
~~~~~~~~~~~~~~

*Function Signature*

``flagBlockError(blockHash, errors)``


*Parameters*

* ``blockHash``: SHA256 block hash of the block containing the error. 
* ``errors``: list of ``ErrorCode`` entries which are to be **cleared** from the block with the given blockHash. Can be ``NO_DATA_BTC_RELAY`` or ``INVALID_BTC_RELAY``.

*Returns*

* ``None``

*Events*

* ``ClearBlockError(blockHash, chainId, errors)`` - emits an event indicating that a Bitcoin block hash (identified ``blockHash``) in a ``BlockChain`` entry (``chainId``) was cleared from the given errors (``errors`` list of ``ErrorCode`` entries).

*Errors*

* ``ERR_UNKNOWN_ERRORCODE = "The reported error code is unknown"``: The reported ``ErrorCode`` can only be ``NO_DATA_BTC_RELAY`` or ``INVALID_BTC_RELAY``.
* ``ERR_BLOCK_NOT_FOUND  = "No Bitcoin block header found with the given block hash"``: No ``BlockHeader`` entry exists with the given block hash.
* ``ERR_ALREADY_REPORTED = "This error has already been reported for the given block hash and is pending confirmation"``: The error reported for the given block hash is currently pending a vote by Staked Relayers.

*Substrate* ::

  fn reportBTCRelayFailure(chainId: U256, errors: Vec<ErrorCode>) -> Result {...}

Function Sequence
.................

1. Check if ``errors`` contains  ``NO_DATA_BTC_RELAY`` or ``INVALID_BTC_RELAY``. If neither match, return ``ERR_UNKNOWN_ERRORCODE``.

2. Retrieve the ``BlockHeader`` entry from ``BlockHeaders`` using ``blockHash``. Return ``ERR_BLOCK_NOT_FOUND`` if no block header can be found.

3. Un-flag error codes in the ``BlockHeader``.

   a. If ``errors`` contains ``NO_DATA_BTC_RELAY``:
   
     i ) Set ``BlockHeader.noData = False``.
     
     ii )Call :ref:`checkChainErrorStatus` passing ``NO_DATA_BTC_RELAY`` as parameter. If the call returns ``False``, set ``BlockChain.noData = False`` (no more ``NO_DATA_BTC_RELAY`` errors in this ``BlockChain``).

   a. If ``errors`` contains ``INVALID_BTC_RELAY``:
   
     i ) Set ``BlockHeader.invalid = False``.
     
     ii ) Call :ref:`checkChainErrorStatus` passing ``INVALID_BTC_RELAY`` as parameter. If the call returns ``False``, set ``BlockChain.invalid = False`` (no more ``INVALID_BTC_RELAY`` errors in this ``BlockChain``).

4. Emit ``ClearBlockError(blockHash, chainId, errors)`` event, with the given ``blockHash``, the ``chainId`` of the flagged ``BlockChain`` entry and the given ``errors`` as parameters.

5. Return
