Parser
==============


List of functions used to extract data from Bitcoin block headers and transactions.
See the Bitcoin Developer Reference for details on the `block header <https://bitcoin.org/en/developer-reference#block-chain>`_ and `transaction <https://bitcoin.org/en/developer-reference#transactions>`_ format.

Block Header 
------------

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

``fn extractHashPrevBlock(blockHeaderBytes: T::BTCBlockHeader) -> T::Hash {...}``


Function Sequence
.................

1. Return ``blockHeaderBytes[4:32]`` (``hashPrevBlock`` starts an position 4 of the 80 byte block header).



extractMerkleRoot
~~~~~~~~~~~~~~~~~

Extracts the ``merkleRoot`` from a Bitcoin block header. 

*Function Signature*

``extractMerkleRoot(blockHeaderBytes)``

*Parameters*

* ``blockHeaderBytes``: 80 byte raw Bitcoin block header

*Returns*

* ``merkleRoot``: the 32 byte Merkle Tree root of the block header

*Substrate*

``fn extractMerkleRoot(blockHeaderBytes: T::BTCBlockHeader) -> T::Hash {...}``


Function Sequence
.................

1. Return ``blockHeaderBytes[36:32]`` (``merkleRoot`` starts an position 36 of the 80 byte block header).



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

``fn extractNBits(blockHeaderBytes: T::BTCBlockHeader) -> T::Bytes {...}``

Function Sequence
.................

1. Return ``blockHeaderBytes[72:4]`` (``nBits`` starts an position 72 of the 80 byte block header).

