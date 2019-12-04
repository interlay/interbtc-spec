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

.. warning:: If pruning is implemented for ``_blockHeades`` and ``_mainChain`` as performance optimization, it is critical to make sure there are no ``_forks`` entries left which reference pruned blocks. Either delay pruning, or, if the fork is inactive (hash falled behind ``_mainChain`` at least *k* blocks), delete it as well. 


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

_status
..........

Integer/Enum (see Status below). Defines the curret state of BTC-Relay. 
 

_statusLog
.............

Array of ``StatusUpdate`` structs, providing a history of status changes of BTC-Relay.

.. note:: If pruning is implemented for ``_blockHeades`` and ``_mainChain`` as performance optimization, ``_statusLog`` entries referencing pruned blocks should be deleted as well. 


StatusCode
...........

* ``RUNNING: 0`` - BTC-Relay fully operational

* ``PARTIAL : 1`` - ``NO_DATA`` detected or manual intervention. Transaction verification disabled for latest blocks.

.. todo:: Define threshold for transaction verification disabling in ``PARTIAL`` state. 

* ``HALTED: 2`` - ``INVALID`` detected or manual intervention. Transaction verification fully suspended.

* ``SHUTDOWN: 3`` - Manual intervantion (``UNEXPECTED``). BTC-Relay operation fully suspended.

ErrorCode
............

Enum specifying reasons for erros leading to a status update.


* ``NO_DATA: 0`` - it was not possible to fetch transactional data for this  block. Hence, validation is not possible.

* ``INVALID : 1`` - this block is invalid. See ``msg`` for reason.

* ``UNEXPECTED: 2`` - unexpected error occured, potentially manual intervantion from governance mechanism. See  ``msg`` for reason.


.. todo:: Decide how to best log reasons for recovery. As error codes (rename then) or simply in the ``msg``?


StatusUpdate
...........

Struct  providing information for an occured halting of BTC-Relay. Contains the following fields.

======================  =============  ============================================
Parameter               Type           Description
======================  =============  ============================================
``satusCode``           Status         New status code.
``block``               char[32]       Block hash of the block header in ``_blockHeaders`` which caused the status change.  
``reason``              ErrorCode      Error code specifying the reason for the status change.          
``msg``                 String         [Optional] message providing more details on halting reason. 
======================  =============  ============================================


