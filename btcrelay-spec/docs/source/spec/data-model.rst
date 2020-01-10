.. _data-model:


Data Model
============

The BTC Relay, as opposed to Bitcoin SPV clients, only stores a subset of information contained in block headers and does not store transactions. 
Specifically, only data that is absolutely necessary to perform correct verification of block headers and transaction inclusion is stored. 

Types
~~~~~

BTCBlockHeader
..............

An 80 bytes long Bitcoin blockchain header.

Constants
~~~~~~~~~

DIFFICULTY_ADJUSTMENT_INTERVAL
..............................

The interval in number of blocks at which Bitcoin adjusts its difficulty. Defaults to ``2016``.

*Substrate* ::

  const DIFFICULTY_ADJUSTMENT_INTERVAL: u16 = 2016;

TARGET_TIMESPAN
...............

The average time span it takes to adjust the difficulty. Defaults to ``1209600`` seconds or two weeks.

*Substrate* ::

  const TARGET_TIMESPAN: Moment = 1209600;

UNROUNDED_MAX_TARGET
....................

The maximum difficulty target. Defaults to :math:`2^{224}-1`.

*Substrate* ::

  const UNROUNDED_MAX_TARGET: U256 = 26959946667150639794667015087019630673637144422540572481103610249215;

Scalars
~~~~~~~~~

BestBlock
.........

Byte 32 block hash identifying current blockchain tip, i.e., most significant block in ``MainChain``. 

*Substrate* ::

  BestBlock: T::H256;

.. ..note:: In Subtrate, ``T::H256`` defauls to the 32 byte long ``T::H256``. Bitcoin uses SHA256 for its block hashes, transaction identifiers and Merkle Trees. For simplicity, we use ``T::H256`` in the rest of this specification as type when storing/referring to SHA256 hashes.

BestBlockHeight
...............

Integer block height of BestBlock in MainChain. 

*Substrate* ::

  BestBlockHeight: U256;

Maps
~~~~

BlockHeaders
............

Mapping of ``<blockHash,BlockHeader>``

*Substrate* ::

  BlockHeaders: map T::H256 => BlockHeader<T::H256>;

MainChain
.........
Mapping of ``<blockHeight,blockHash>``

*Substrate* ::

  MainChain: map U256 => T::H256;

Forks
.....
Mapping of ``<forkId,Fork>``

.. warning:: If pruning is implemented for ``BlockHeaders`` and ``MainChain`` as performance optimization, it is critical to make sure there are no ``Forks`` entries left which reference pruned blocks. Either delay pruning, or, if the fork is inactive (hash falled behind ``MainChain`` at least *k* blocks), delete it as well. 

*Substrate* ::

  Forks: map U256 => Fork<Vec<T::H256>>;

Structs
~~~~~~~

BlockHeader
...........

======================  =========  ============================================
Parameter               Type       Description
======================  =========  ============================================
``blockHeight``         U256       Height of the current block header.
``merkleRoot``          H256       Root of the Merkle tree storing referencing transactions included in the block.
======================  =========  ============================================

*Substrate* 

::

  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct BlockHeader<H256> {
        blockHeight: U256,
        merkleRoot: H256 
  }
  

Fork
....


======================  =============  ===========================================================
Parameter               Type           Description
======================  =============  ===========================================================
``startHeight``         U256           Height of the block at which this fork starts (forkpoint).
``length``              U256           Length of the fork (in blocks).
``forkBlockHashes``     Vec<H256>      Linked hash set of block hashes, which references Bitcoin block headers stored in ``BlockHeaders``, contained in this fork (maintains insertion order).
======================  =============  ===========================================================

*Substrate*

::

  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Fork<> {
        startHeight: U256,
        length: U256,
        forkBlockHahes: Vec<H256>
  }
