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

.. _extractNoUTXO:

extractNoUTXO
-------------

Returns the number of unspent transaction outputs in a given (raw) transaction. The number of inputs and outputs in a raw transaction is encoded in the `compact unsigned integer format <https://bitcoin.org/en/developer-reference#compactsize-unsigned-integers>`_.

Specification
.............

*Function Signature*

``extractNoUTXO(rawTransaction) -> u64``

*Parameters*

* ``rawTransaction``: A variable byte size encoded transaction. 

*Returns*

* ``outputsNumber``: The number of outputs in a transaction.

*Substrate* ::

  fn extractNoUTXO(rawTransaction: T::Vec<u8>) -> u64 {...}

Function Sequence
.................

1. Slice off the first 4 bytes of the raw transaction.

2. Determine the number of transaction inputs by 

.. _extractOPRETURN:

extractOPRETURN
~~~~~~~~~~~~~~~

Extracts the OP_RETURN of a given transaction. The OP_RETURN field can be used to store `40 bytes in a given Bitcoin transaction <https://bitcoin.stackexchange.com/questions/29554/explanation-of-what-an-op-return-transaction-looks-like.`_. The transaction output that includes the OP_RETURN is provably unspendable. We require specific information in the OP_RETURN field to prevent replay attacks in PolkaBTC.

*Function Signature*

``extractOPRETURN()``

*Parameters*

* ````: 

*Returns*

* ````:

*Events*

* ````:

*Errors*

* ````:

*Substrate* ::

  fn extractOpreturn(origin, ) -> Result {...}


Function Sequence
.................

