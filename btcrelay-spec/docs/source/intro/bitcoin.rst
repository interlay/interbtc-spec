Bitcoin
===============================

This is a quick overview of Bitcoin, containing information necessary to understand the operation of BTC-Relay.

Overview
------------------------

Bitcoin is an electronic peer-to-peer cash system introduced in the `Bitcoin whitepaper <https://bitcoin.org/bitcoin.pdf>`_.
Bitcoin uses the Nakamoto consensus rules to decide which blocks, and thereby which transactions, to include in its ledger.
Nakamoto consensus uses the longest-chain rule to determine which chain of blocks contains the most work, i.e. proof-of-work (PoW).
The longest chain is considered to currently *valid* chain.

The longest chain can be extended by miners adding new blocks.
Miners can attach a new block to the chain of blocks by finding a hash that satisfies a target difficulty.
The target difficulty describes how many leading zeros a block hash has to have.
When miners construct a new block, the block hash consists of the previous block header hash and the data contained in the current block.
A miner then needs to add a nonce to the current block header hash to meet the difficulty criteria.
Bitcoin uses a double `sha256 <https://en.wikipedia.org/wiki/SHA-2>`_ hashing algorithm for its block construction.
The core idea behind using a nonce to find a specific target difficulty is that a miner can do not better than randomly guessing the nonce.

Bitcoin accounts for the increase of computation power.
An increase of computation power means that miners can find new blocks in ever shorter time periods as their processing power to calculate the sha256 hash.
As a consequence, Bitcoin adjust the target difficulty every 2016 blocks.
That means, every 2016 blocks, it is increasingly difficult to find a new block.

Each blocks contains at least on transaction - the coinbase transaction.
The `coinbase transaction <https://bitcoin.org/en/glossary/coinbase-transaction>`_ is included by the miner and transfers the reward for finding a block to the miner.
Other transactions are also included by a miner.
These are transactions broadcasted by users of the Bitcoin system.

Transactions in Bitcoin are included based on the `Unspent Transaction Output (UTXO) model <https://bitcoin.org/en/blockchain-guide#introduction>`_.
Each new transaction needs to specify which transaction output it is going to spend.
The new transaction then needs to comply with the spending conditions of that output.
For example, the to-be-spent transaction output could require that the transaction can only be spend from a specific public key.
The spender would then need to prove that she is the owner of that public key in the spending transaction.
The spending transaction in turn an create one or more outputs.


Data Model
------------------------

This specification includes selected Bitcoin data model references. For the full details, refer to https://bitcoin.org/en/developer-reference.

Block Headers
~~~~~~~~~~~~~~~
The `80 bytes block header hash <https://bitcoin.org/en/developer-reference#block-headers>`_ encodes the following information:

=====  ======================  =========  ============================================
Bytes  Parameter               Type       Description
=====  ======================  =========  ============================================
4      ``version``             u32        The block version to follow.
32     ``hashPrevBlock``       char[32]   The double sha256 hash of the previous block header.
32     ``merkleRoot``          char[32]   The double sha256 hash of the Merkle root of all transaction hashes in this block.
4      ``time``                u32        The block timestamp included by the miner.
4      ``nBits``               u32        The target difficulty threshold, see also the `Bitcoin documentation <https://bitcoin.org/en/developer-reference#target-nbits>`_. 
4      ``nonce``               u32        The nonce chosen by the miner to meet the target difficulty threshold.
=====  ======================  =========  ============================================


Transactions
~~~~~~~~~~~~

A transaction is broadcasted in a serialized byte format (also called raw format). It consists of a variable size of bytes and has the following `format <https://bitcoin.org/en/developer-reference#raw-transaction-format>`_.

=====  ======================  =========  ==================================
Bytes  Parameter               Type       Description
=====  ======================  =========  ==================================
4      ``version``             i32        Transaction version number.
var    ``tx_in count``         uint       Number of transaction inputs.
var    ``tx_in``               txIn       Transaction inputs.
var    ``tx_out count``        uint       The number of transaction outputs.
var    ``tx_out``              txOut      Transaction outputs.
4      ``lock_time``           u32        A Unix timestamp OR block number.
=====  ======================  =========  ==================================


Inputs
~~~~~~

Bitcoin's UTXO model requires a new transaction to spend at least one existing and unspent transaction output as a transaction input. The ``txIn`` type consists of the following bytes. See the `reference <https://bitcoin.org/en/developer-reference#txin>`_ for further details.

=====  ======================  =========  ==================================
Bytes  Parameter               Type       Description
=====  ======================  =========  ==================================
36     ``previous_output``     outpoint   The output to be spent consisting of the transaction hash (32 bytes) and the output index (4 bytes).
var    ``script bytes``        uint       Number of bytes in the signature script (max 10,000 bytes).
var    ``signature script``    char[]     The script satisfying the output's script.
4      ``sequence``            u32        Sequence number (default ``0xffffffff``).
=====  ======================  =========  ==================================



Outputs
~~~~~~~

The transaction output has the following format according to the `reference <https://bitcoin.org/en/developer-reference#txout>`_.

=====  ======================  =========  ==================================
Bytes  Parameter               Type       Description
=====  ======================  =========  ==================================
8      ``value``               i64        Number of satoshis to be spend.   
1+     ``pk_script bytes``     uint       Number of bytes in the script.
var    ``pk_script``           char[]     Spending condition as script.
=====  ======================  =========  ==================================



Merkle Tree Paths
~~~~~~~~~~~~~~~~~

The `Merkle tree path <https://bitcoin.org/en/developer-reference#merkle-trees>`_ allows to reconstruct the Merkle root of the tree from a given transaction hash. The Merkle tree is constructed given all transactions with their index, i.e. their position in the tree. Then each pair of transactions is hashed. The resulting hashes are then paired again until, eventually, only a single hash remains: the Merkle root.

Given a single transaction hash and its index in the tree, it is possible to calculate the root if we know all the pairings of that hash along the tree.
The figure below shows an example of this.
If we know the hash of transaction ``tx1`` and know that it is at position ``1`` in the tree we can calculate the Merkle root given the hashes in the red boxes.
First, we hash together ``tx0`` and ``tx1``.
Since we know that ``tx1`` is at index ``1``, the hash of ``tx0`` must be precede ``tx1``'s hash in the calculation.
We then know that we have calculated the left hand side hash ``hash(tx0 | tx1)``.
Given the hash on the right hand side, ``hash (tx2 | tx2)``, we then take the left hand and the right hand side as inputs to calculate the Merkle root as ``hash(hash(tx0 | tx1) | hash(tx2 | tx2))``.


.. figure:: ../figures/data-model.png
        :alt: Merkle tree path diagram

        A diagram showing the Merkle tree for a block with three transactions (tx0, tx1, and tx2). The Merkle root is constructed by hashing the transactions pairwise. In red, the Merkle path for tx1 is given.


Data Format Considerations
~~~~~~~~~~~~~~~~~~~~~~~~~~

+ **Endianness**:
  Bitcoin uses `little endian <https://en.wikipedia.org/wiki/Endianness>`_ to represent bytes. That means, the most significant byte is the last byte in a given byte representation.

.. todo:: What exactly would we need here?

+ Specific Bitcoin data types and structs (e.g. Merkle Block)

Cryptographic Primitives
------------------------

Bitcoin's Cryptographic Primitives

+ **ECDSA secp256k1**: Bitcoin uses the `secp256k1 <https://en.bitcoin.it/wiki/Secp256k1>`_ parameters for its elliptic curve together with the `ECDSA <https://en.bitcoin.it/wiki/Elliptic_Curve_Digital_Signature_Algorithm>`_ algorithm for its public-key cryptography.
+ **SHA-256**: Bitcoin uses a double sha256 hash function for constructing the Merkle trees, the proof of work algorithm, and the creation of Bitcoin addresses. To prevent against `"length-extension" attacks <https://en.wikipedia.org/wiki/Length_extension_attack>`_, Bitcoin uses the double sha256.
+ **RIPEMD-160**: Bitcoin uses a second hash function, `RIPEMD-160 <https://en.bitcoin.it/wiki/RIPEMD-160`_, to produce short hashes of length 160 bits. Due to possible interactions between `ECDSA and RIPEMD-160 <https://bitcoin.stackexchange.com/questions/9202/why-does-bitcoin-use-two-hash-functions-sha-256-and-ripemd-160-to-create-an-ad/9216#9216>`_, Bitcoin uses sha256 in between the two for key generation.
