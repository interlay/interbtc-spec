.. _data-model:


Data Model
============

The BTC-Relay, as opposed to Bitcoin SPV clients, only stores a subset of information contained in block headers and does not store transactions. 
Specifically, only data that is absolutely necessary to perform correct verification of block headers and transaction inclusion is stored. 

Types
~~~~~

RawBlockHeader
..............

An 80 bytes long Bitcoin blockchain header.

*Substrate* ::

   pub type RawBlockHeader = [u8; 80];


Constants
~~~~~~~~~

DIFFICULTY_ADJUSTMENT_INTERVAL
..............................

The interval in number of blocks at which Bitcoin adjusts its difficulty (approx. every 2 weeks = 2016 blocks).

*Substrate* ::

  const DIFFICULTY_ADJUSTMENT_INTERVAL: u16 = 2016;

TARGET_TIMESPAN
...............

Expected duration of the different adjustment interval in seconds, ``1209600`` seconds (two weeks) in the case of Bitcoin.

*Substrate* ::

  const TARGET_TIMESPAN: U256 = 1209600;

UNROUNDED_MAX_TARGET
....................

The maximum difficulty target, :math:`2^{224}-1` in the case of Bitcoin. For more information, see the `Bitcoin Wiki <https://en.bitcoin.it/wiki/Target>`_.

*Substrate* ::

  const UNROUNDED_MAX_TARGET: U256 = 26959946667150639794667015087019630673637144422540572481103610249215;

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


BlockChain
..........

Representation of a Bitcoin blockchain. 

.. tabularcolumns:: |l|l|L|

======================  ==============  ========================================================================
Parameter               Type            Description
======================  ==============  ========================================================================
``chain``               Map<u256,H256>  Mapping of ``blockHeight`` to ``blockHash``, which points to a ``BlockHeader`` entry in ``BlockHeaders``.
``maxHeight``           U256            Max. block height in the ``chain`` mapping. Used for ordering in the ``Chains`` priority queue.
======================  ==============  ========================================================================


Data Structures
~~~~~~~~~~~~~~~

BlockHeaders
............

Mapping of ``<blockHash, BlockHeader>``, storing all verified Bitcoin block headers (fork and main chain) submitted to BTC-Relay.

*Substrate* ::

  BlockHeaders: map T::H256 => BlockHeader<T::H256>;



Chains
.........

Priority queue of ``BlockChain`` elements, **ordered by** ``maxHeight`` (**descending**).
The ``BlockChain`` entry with the most significant ``maxHeight`` value (i.e., topmost element) in this mapping is considered to be the Bitcoin *main chain*.

*Substrate* ::

  Chains: map U256 => Vec<T::H256>;


BestBlock
.........

32 byte Bitcoin block hash (double SHA256) identifying the current blockchain tip, i.e., the ``BlockHeader`` with the highest ``blockHeight`` in the ``BlockChain`` entry, which has the most significant ``height`` in the ``Chains`` priority queue (topmost position). 

*Substrate* ::

  BestBlock: T::H256;


.. note:: Bitcoin uses SHA256 (32 bytes) for its block hashes, transaction identifiers and Merkle trees. In Substrate, we hence use ``T::H256`` to represent these hashes.

BestBlockHeight
...............

Integer representing the maximum block height (``height``) in the ``Chains`` priority queue. This is also the ``blockHeight`` of the ``BlockHeader`` entry pointed to by ``BestBlock``.

*Substrate* ::

  BestBlockHeight: U256;






