Data Model
============

The BTC Parachain, as opposed to Bitcoin SPV clients, only stores a subset of information contained in block headers and does not store transactions. 
Specifically, only data that is absolutely necessary to perform correct verification of block headers and transaction inclusion is stored. 

Constants
~~~~~~~~~

DIFFICULTY_ADJUSTMENT_INTERVAL
..............................

The interval in number of blocks in which Bitcoin adjusts its difficulty. Defaults to ``2016``.

TARGET_TIMESPAN
...............

The average time span it takes to adjust the difficulty. Defaults to ``1209600`` seconds or two weeks.

UNROUNDED_MAX_TARGET
....................

The maximum difficulty target. Defaults to ``2**224-1``.

Variables
~~~~~~~~~

_bestBlock
..........

Byte 32 block hash identifying current blockchain tip, i.e., most significant block in _mainChain. 

_bestBlockHeight
..............

Integer block height of _bestBlock in  _mainChain. 


Maps
~~~~

_blockHeaders
..............
Mapping of ``<blockHash,BlockHeader>``

_mainChain
..........
Mapping of ``<blockHeight,blockHash>``


_forks
......
Mapping of ``<forkId,Fork>``



Structs
~~~~~~~

BlockHeader
...........

======================  =========  ============================================
Parameter               Type       Description
======================  =========  ============================================
``blockHeight``         u256       Height of the current block header.
``merkleRoot``          char[32]   Root of the Merkle tree storing referencing transactions included in the block.
======================  =========  ============================================

Fork
....

======================  =============  ============================================
Parameter               Type           Description
======================  =============  ============================================
``startHeight``         u256           Height of the block at which this fork starts (forkpoint).
``length``              u256           Length of the fork (in blocks).
``forkBlockHashes``     tbd.           Linked hash set of block hashes, which references ``BlockHeaders`` in ``_blockHeaders``, contained in this fork (maintains insertion order).
======================  =============  ============================================


Failure Handling
~~~~~~~~~~~~~~~~

Data structures used to handle failures of the BTC-Relay. 
See 

_isHalted
..........

Boolean flag - if set to ``True`` indicates that the BTC-Relaty was halted by the governance mechanism. 
 

_haltReasons
.............

Array of ``HaltReason`` structs, providing details on the reason for the halting of BTC-Relay.



HaltReason
...........

Struct  providing information for an occured halting of BTC-Relay. Contains the following fields.

======================  =============  ============================================
Parameter               Type           Description
======================  =============  ============================================
``haltingCode``         HaltingCode    Error code specifying reason for halting.
``block``               char[32]       Block hash of the block header in ``_blockHeaders`` which caused the halting.  
``msg``                 String         [Optional] message providing more details on halting reason. 
======================  =============  ============================================


HaltingCode
............

Enum specifying possible reasons for halting.


* ``NO_DATA: 0`` - it was not possible to fetch transactional data for this  block. Hence, validation is not possible.

* ``INVALID : 1`` - this block is invalid. See ``msg`` for reason.

* ``UNSPECIFIED: 2`` - unexpected error occured, potentially manual intervantion from governance mechanism. See  ``msg`` for reason.