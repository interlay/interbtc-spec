.. _data-model:


Data Model
============

The BTC-Relay, as opposed to Bitcoin SPV clients, only stores a subset of information contained in block headers and does not store transactions. 
Specifically, only data that is absolutely necessary to perform correct verification of block headers and transaction inclusion is stored. 

Types
~~~~~

BTCBlockHeader
..............

An 80 bytes long Bitcoin blockchain header.

*Substrate* ::

   pub type BTCBlockHeader = [u8; 80];


Constants
~~~~~~~~~

DIFFICULTY_ADJUSTMENT_INTERVAL
..............................

The interval in number of blocks at which Bitcoin adjusts its difficulty. Defaults to ``2016``.

*Substrate* ::

  const DIFFICULTY_ADJUSTMENT_INTERVAL: u16 = 2016;

TARGET_TIMESPAN
...............

Expected duration of the different adjustment interval in seconds. Defaults to ``1209600`` seconds or two weeks.

*Substrate* ::

  const TARGET_TIMESPAN: U256 = 1209600;

UNROUNDED_MAX_TARGET
....................

The maximum difficulty target. Defaults to :math:`2^{224}-1`. For more information, see the `Bitcoin Wiki <https://en.bitcoin.it/wiki/Target>`_.

*Substrate* ::

  const UNROUNDED_MAX_TARGET: U256 = 26959946667150639794667015087019630673637144422540572481103610249215;

Scalars
~~~~~~~~~

BestBlock
.........

Byte 32 block hash identifying the current blockchain tip, i.e., the most significant block in ``MainChain``. 

*Substrate* ::

  BestBlock: T::H256;

.. ..note:: In Subtrate, ``T::H256`` defauls to the 32 byte long ``T::H256``. Bitcoin uses SHA256 for its block hashes, transaction identifiers and Merkle trees. For simplicity, we use ``T::H256`` in the rest of this specification as type when storing/referring to SHA256 hashes.

BestBlockHeight
...............

Integer block height of ``BestBlock`` in ``MainChain``. 

*Substrate* ::

  BestBlockHeight: U256;


Maps
~~~~

BlockHeaders
............

Mapping of ``<blockHash,BlockHeader>``, storing all verified Bitcoin block headers (fork and main chain) submitted to BTC-Relay.

*Substrate* ::

  BlockHeaders: map T::H256 => BlockHeader<T::H256>;

MainChain
.........
Mapping of ``<blockHeight,blockHash>`` (``<u256, byte32>``). Tracks the current Bitcoin main chain (refers to stored block headers in ``BlockHeaders``).

*Substrate* ::

  MainChain: map U256 => T::H256;

Forks
.....

Mapping of ``<forkId,Fork>`` (``<u256, Fork>``), tracking ongoing forks in BTC-Relay.


*Substrate* ::

  Forks: map U256 => Fork<Vec<T::H256>>;

Structs
~~~~~~~

BlockHeader
...........

Representation of a Bitcoin block header. 

.. note:: Fields marked as [Optional] are not critical for the secure operation of BTC-Relay, but can be stored anyway, at the developers discretion. We omit these fields in the rest of this specification. 

.. tabularcolumns:: |l|l|L|

======================  =========  ========================================================================
Parameter               Type       Description
======================  =========  ========================================================================
``blockHeight``         u256       Height of this block in the Bitcoin main chain.
``merkleRoot``          byte32     Root of the Merkle tree referencing transactions included in the block.
``target``              u256       Difficulty target of this block (converted from ``nBits``, see `Bitcoin documentation <https://bitcoin.org/en/developer-reference#target-nbits>`_.).
``timestamp``           timestamp  UNIX timestamp indicating when this block was mined in Bitcoin.
``version``             u32        [Optional] Version of the submitted block.
``hashPrevBlock``       byte32     [Optional] Block hash of the predecessor of this block.
``nonce``               u32        [Optional] Nonce used to solve the PoW of this block. 
======================  =========  ========================================================================

*Substrate* 

::

  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct BlockHeader<H256, DateTime> {
        blockHeight: U256,
        merkleRoot: H256,
        target: U256,
        timestamp: DateTime,
        // Optional fields
        version: U32, 
        hashPrevBlock: H256,
        nonce: U32
  }
  

Fork
....

Representation of an ongoing Bitcoin fork, tracked in BTC-Relay. 

.. warning:: Forks tracked in BTC-Relay and observed in Bitcoin must not necessarily be the same. See :ref:`relay-poisoning` for more details.

.. tabularcolumns:: |l|l|L|

======================  =============  ===========================================================
Parameter               Types          Description
======================  =============  ===========================================================
``startHeight``         u256           Main chain block height of the block at which this fork starts (*forkpoint*).
``length``              u256           Length of the fork (in blocks).
``forkBlockHashes``     byte32[]       List  of block hashes, which references Bitcoin block headers stored in ``BlockHeaders``, contained in this fork (in insertion order).
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
