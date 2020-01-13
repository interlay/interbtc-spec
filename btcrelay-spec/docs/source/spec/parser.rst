.. _parser:

Functions: Parser
==================


List of functions used to extract data from Bitcoin block headers and transactions.
See the Bitcoin Developer Reference for details on the `block header <https://bitcoin.org/en/developer-reference#block-chain>`_ and `transaction <https://bitcoin.org/en/developer-reference#transactions>`_ format.

Block Header 
------------

.. _extractHashPrevBlock:

extractHashPrevBlock
~~~~~~~~~~~~~~~~~~~~

Extracts the ``hashPrevBlock`` (reference to previous block) from a Bitcoin block header.

*Function Signature*

``extractHashPrevBlock(blockHeaderBytes)``

*Parameters*

* ``blockHeaderBytes``: 80 byte raw Bitcoin block header.

*Returns*

* ``hashPrevBlock``: the 32 byte block hash reference to the previous block.

*Substrate*

::

  fn extractHashPrevBlock(blockHeaderBytes: T::RawBlockHeader) -> T::H256 {...}


Function Sequence
.................

1. Return 32 bytes starting at index 4 of ``blockHeaderBytes``

.. _extractMerkleRoot:

extractMerkleRoot
~~~~~~~~~~~~~~~~~

Extracts the ``merkleRoot`` from a Bitcoin block header. 

*Function Signature*

``extractMerkleRoot(blockHeaderBytes)``

*Parameters*

* ``blockHeaderBytes``: 80 byte raw Bitcoin block header

*Returns*

* ``merkleRoot``: the 32 byte Merkle tree root of the block header

*Substrate*

::

  fn extractMerkleRoot(blockHeaderBytes: T::RawBlockHeader) -> T::H256 {...}


Function Sequence
.................

1. Return 32 bytes starting at index 36 of ``blockHeaderBytes``.


.. _extractTimestamp:

extractTimestamp
~~~~~~~~~~~~~~~~~

Extracts the timestamp from the block header.

*Function Signature*

``extractTimestamp(blockHeaderBytes)``

*Parameters*

* ``blockHeaderBytes``: 80 byte raw Bitcoin block header

*Returns*

* ``timestamp``: timestamp representation of the 4 byte timestamp field of the block header

*Substrate*

::

  fn extractTimestamp(blockHeaderBytes: T::RawBlockHeader) -> T::DateTime {...}

Function Sequence
.................

1. Return 32 bytes starting at index 68 of ``blockHeaderBytes``.



.. _extractNBits:

extractNBits
~~~~~~~~~~~~

Extracts the ``nBits`` from a Bitcoin block header. This field is necessary to compute that ``target`` in ``nBitsToTarget``.

*Function Signature*

``extractNBits(blockHeaderBytes)``

*Parameters*

* ``blockHeaderBytes``: 80 byte raw Bitcoin block header

*Returns*

* ``nBits``: the 4 byte nBits field of the block header

*Substrate*

::

  fn extractNBits(blockHeaderBytes: T::RawBlockHeader) -> T::Bytes {...}

Function Sequence
.................

1. Return 4 bytes starting at index 72 of ``blockHeaderBytes``.



Transactions 
-------------

.. todo:: The parser functions used for transaction processing (called by other modules) will be added on demand. See PolkaBTC specification for more details.


