Bitcoin
===============================

Quick overview of Bitcoin.

Overview
------------------------

- Nakamoto consensus
  - PoW using sha256
- Longest chain rule
- Difficulty is adjusted very 2016 blocks
- UTXO model


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

A transaction is broadcasted in a serialized bute format (also called raw format). It consists of a variable size of bytes and has the following `format <https://bitcoin.org/en/developer-reference#raw-transaction-format>`_.

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