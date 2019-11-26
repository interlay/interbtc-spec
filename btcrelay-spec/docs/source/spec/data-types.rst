Data Model
==========

Minimum viable data model for BTC Relay. The data model includes only the bare minimum required to store inside the BTC Relay and does not store the same amount of information as e.g. a Bitcoin full-node.


Block Headers
~~~~~~~~~~~~~

The block header reference stored in BTC Relay contains the following information.

======================  =========  ============================================
Parameter               Type       Description
======================  =========  ============================================
``blockHeight``         u256       Height of the current block header.
``chainWork``           u256       Accumulated PoW at this height.
``header``              bytes[80]  Block header hash.
``lastDiffAdjustment``  u256       Difficulty adjustment for tracking of forks.
======================  =========  ============================================

The `80 bytes block header hash <https://bitcoin.org/en/developer-reference#block-headers>`_ encodes the following information:

=====  ======================  =========  ============================================
Bytes  Parameter               Type       Description
=====  ======================  =========  ============================================
4      ``version``             i32        The block version to follow.
32     ``hashPrevBlock``       char[32]   The double sha256 hash of the previous block header.
32     ``merkleRoot``          char[32]   The double sha256 hash of the Merkle root of all transaction hashes in this block.
4      ``time``                u32        The block timestamp included by the miner.
4      ``nBits``               u32        The target difficulty threshold, see also the `Bitcoin documentation <https://bitcoin.org/en/developer-reference#target-nbits>`_. 
4      ``nonce``               u32        The nonce chosen by the miner to meet the target difficulty threshold.
=====  ======================  =========  ============================================


Transactions
~~~~~~~~~~~~



Inputs
~~~~~~


Outputs
~~~~~~~


Merkle Tree Paths
~~~~~~~~~~~~~~~~~

Data Format Considerations
~~~~~~~~~~~~~~~~~~~~~~~~~~
+ Endianness
+ Specific Bitcoin data types and structs (e.g. Merkle Block)

Cryptographic Primitives
------------------------

Bitcoin's Cryptographic Primitives

+ ECDSA secp256k1
+ SHA-256 hash function
+ RIPEMID-160 hash function