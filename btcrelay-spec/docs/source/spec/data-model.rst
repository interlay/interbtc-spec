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

Variables
~~~~~~~~~

BestBlock
.........

Byte 32 block hash identifying current blockchain tip, i.e., most significant block in ``MainChain``. 

*Substrate* ::

  BestBlock: T::H256;

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

  BlockHeaders: map T::Hash256 => BlockHeader<T::Hash256>;

MainChain
.........
Mapping of ``<blockHeight,blockHash>``

*Substrate* ::

  MainChain: map U256 => T::Hash256;

Forks
.....
Mapping of ``<forkId,Fork>``

.. warning:: If pruning is implemented for ``BlockHeaders`` and ``MainChain`` as performance optimization, it is critical to make sure there are no ``Forks`` entries left which reference pruned blocks. Either delay pruning, or, if the fork is inactive (hash falled behind ``MainChain`` at least *k* blocks), delete it as well. 

*Substrate* ::

  Forks: map U256 => Fork<Vec<T::Hash256>>;

Structs
~~~~~~~

BlockHeader
...........

======================  =========  ============================================
Parameter               Type       Description
======================  =========  ============================================
``blockHeight``         U256       Height of the current block header.
``merkleRoot``          Hash256       Root of the Merkle tree storing referencing transactions included in the block.
======================  =========  ============================================

*Substrate* 

::

  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct BlockHeader<Hash256> {
        blockHeight: U256,
        merkleRoot: Hash256 
  }
  

Fork
....

.. todo:: To store the block headers in the fork, can we just use an array of hashes?

======================  =============  ============================================
Parameter               Type           Description
======================  =============  ============================================
``startHeight``         U256           Height of the block at which this fork starts (forkpoint).
``length``              U256           Length of the fork (in blocks).
``forkBlockHashes``     Vec<Hash256>      Linked hash set of block hashes, which references ``BlockHeaders`` in ``BlockHeaders``, contained in this fork (maintains insertion order).
======================  =============  ============================================

*Substrate*

::

  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Fork<> {
        startHeight: U256,
        length: U256,
        forkBlockHahes: Vec<Hash256>
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

.. todo:: Define threshold for transaction verification disabling in ``PARTIAL`` state. 

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


.. todo:: Decide how to best log reasons for recovery. As error codes (rename then) or simply in the ``msg``?

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
``blockHash``           bytes[32]      Block hash of the block header in ``_blockHeaders`` which caused the status change.  
``errorCode``           ErrorCode      Error code specifying the reason for the status change.          
``msg``                 String         [Optional] message providing more details on halting reason. 
======================  =============  ============================================

*Substrate* 

::

  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct StatusUpdate<Status, Hash256, ErrorCode> {
        statusCode: Status,
        blockHash: Hash256,
        errorCode: ErrorCode,
        msg: String
  }

