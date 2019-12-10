Data Model
============

The BTC Parachain, as opposed to Bitcoin SPV clients, only stores a subset of information contained in block headers and does not store transactions. 
Specifically, only data that is absolutely necessary to perform correct verification of block headers and transaction inclusion is stored. 

Constants
~~~~~~~~~

DIFFICULTY_ADJUSTMENT_INTERVAL
..............................

The interval in number of blocks in which Bitcoin adjusts its difficulty. Defaults to ``2016``.

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


======================  =============  ============================================
Parameter               Type           Description
======================  =============  ============================================
``startHeight``         U256           Height of the block at which this fork starts (forkpoint).
``length``              U256           Length of the fork (in blocks).
``forkBlockHashes``     Vec<H256>      Linked hash set of block hashes, which references Bitcoin block headers stored in ``BlockHeaders``, contained in this fork (maintains insertion order).
======================  =============  ============================================

*Substrate*

::

  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Fork<> {
        startHeight: U256,
        length: U256,
        forkBlockHahes: Vec<H256>
  }



BTC Relay Status (Failure Handling)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Data structures used to handle failures of the BTC-Relay. 

Status
......

Integer/Enum (see StatusCode below). Defines the curret state of BTC-Relay. 

StatusLog
.........

Array of ``StatusUpdate`` structs, providing a history of status changes of BTC-Relay.

.. note:: If pruning is implemented for ``BlockHeaders`` and ``MainChain`` as performance optimization, ``StatusLog`` entries referencing pruned blocks should be deleted as well. 


*Substrate* ::

  StatusLog: Vec<StatusUpdate>;

StatusCode
..........

* ``RUNNING: 0`` - BTC-Relay fully operational

* ``PARTIAL : 1`` - ``NO_DATA`` detected or manual intervention. Transaction verification disabled for latest blocks.

.. note:: The exact threshold (in terms of block height) for disabling the verification of transactions in the ``PARTIAL`` state must be defined upon deployment. A possible approach is to keep intact transaction inclusion verification for blocks with a height lower than the height of the first ``NO_DATA```block. 

* ``HALTED: 2`` - ``INVALID`` detected or manual intervention. Transaction verification fully suspended.

* ``SHUTDOWN: 3`` - Manual intervantion (``UNEXPECTED``). BTC-Relay operation fully suspended.

*Substrate* 

::

  enum StatusCode {
        RUNNING = 0,
        PARTIAL = 1,
        HALTED = 2,
        SHUTDOWN = 3,
  }

ErrorCode
.........

Enum specifying reasons for error leading to a status update.


* ``NO_DATA: 0`` - it was not possible to fetch transactional data for this  block. Hence, validation is not possible.

* ``INVALID : 1`` - this block is invalid. See ``msg`` for reason.

* ``UNEXPECTED: 2`` - unexpected error occured, potentially manual intervantion from governance mechanism. See  ``msg`` for reason.


*Substrate*

::
  
  enum ErrorCode {
        NO_DATA = 0,
        INVALID = 1,
        UNEXPECTED = 2,
  }


StatusUpdate
............

Struct providing information for an occurred halting of BTC-Relay. Contains the following fields.

======================  =============  ============================================
Parameter               Type           Description
======================  =============  ============================================
``satusCode``           Status         New status code.
``blockHash``           H256           Block hash of the block header in ``_blockHeaders`` which caused the status change.  
``errorCode``           ErrorCode      Error code specifying the reason for the status change.          
``msg``                 String         [Optional] message providing more details on the change of status (error message or recovery). 
======================  =============  ============================================

*Substrate* 

::

  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct StatusUpdate<Status, H256, ErrorCode> {
        statusCode: Status,
        blockHash: H256,
        errorCode: ErrorCode,
        msg: String
  }

