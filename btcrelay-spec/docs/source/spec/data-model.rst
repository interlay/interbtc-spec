Data Model
============

The BTC Parachain, as opposed to Bitcoin SPV clients, only stores a subset of information contained in block headers and does not store transactions. 
Specifically, only data that is absolutely necessary to perform correct verification of block headers and transaction inclusion is stored. 


Variables
~~~~~~~~~~~~~~~~~

_bestBlock
..............

Current blockchain tip, i.e., most significant block in _mainChain. 


Maps
~~~~~~~~~~~~~~~~~~~

_blockHeaders
..............
Mapping of ``<blockHash,BlockHeader>``

_mainChain
..............
Mapping of ``<blockHeight,blockHash>``


_forks
..............
Mapping of ``<forkId,Fork>``

Structs
~~~~~~~~~~~~~~~~~~~

BlockHeader
..............

======================  =========  ============================================
Parameter               Type       Description
======================  =========  ============================================
``blockHeight``         u256       Height of the current block header.
``merkleRoot``          char[32]   Root of the Merkle tree storing referencing transactions included in the block.
======================  =========  ============================================

Fork
..............

======================  =============  ============================================
Parameter               Type           Description
======================  =============  ============================================
``startHeight``         u256           Height of the block at which this fork starts (forkpoint).
``length``              u256           Length of the fork (in blocks).
``forkBlockHashes``     tbd.           Linked hash set of block hashes, which references ``BlockHeaders`` in ``_blockHeaders``, contained in this fork (maintains insertion order).
======================  =============  ============================================
