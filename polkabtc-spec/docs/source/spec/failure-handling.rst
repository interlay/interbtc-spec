.. _failure-handling:

Failure Handling
========================

.. todo:: Update text: no longer BTC-Relay only, but entire Parachain, incl. exchange rate oracle.  

The BTC-Relay provides additional methods for failure handling, e.g. in case an attack on the Parachain or Bitcoin itself is detected. 
**Please first see** `Failure Modes: Halting and Recovery <security_performance/security.html#security-parameter-k>`_ for an explanation of how BTC-Relay can handle and recover from failures.


Overview
----------

Failure Modes
~~~~~~~~~~~~~

BTC-Relay can enter into different failure modes, depending on the occured error.
See figure below. 


.. figure:: ../figures/failureModes.png
    :alt: State machine showing BTC-Relay failure modes

    State machine showing the operational and failure modes of BTC-Relay, and how to recover from or flag failures.

Roles
~~~~~~

Failure handling methods calls are **restricted**, i.e., can only be called by pre-determined roles.
We differentiate between:

* **Staked Relayers** - collateralized Parachain participants, whose main role it is to Bitcoin full nodes and check that:
    
    1. Transactional data is available for submitted Bitcoin block headers (``NO_DATA: 0`` code)
    2. Submitted blocks are valid under Bitcoin's consensus rules  (``INVALID: 1`` code).

 If one of the above failures is detected, staked relayers can (*TODO: together or individually?*) halt BTC-Relay, providing information about the cause. 

* **Governance Mechanism** - Parachain governance mechanism, voting on critical changes to the architecture or unexpected failures, e.g. hard forks or detected 51% attacks (if a fork exceeds the specified security parameter *k*, see `Security Parameter k <security_performance/security.html#security-parameter-k>`_.). A manual intervention can be indicated via the ``UNEXPECTED: 2`` halting code. 


Data Model
-----------


Data structures used to handle failures of the BTC-Relay. 

Status
~~~~~~~~~~~~~

Integer/Enum (see StatusCode below). Defines the curret state of BTC-Relay. 

StatusLog
~~~~~~~~~~~~~

Array of ``StatusUpdate`` structs, providing a history of status changes of BTC-Relay.

.. note:: If pruning is implemented for ``BlockHeaders`` and ``MainChain`` as performance optimization, ``StatusLog`` entries referencing pruned blocks should be deleted as well. 


*Substrate* ::

  StatusLog: Vec<StatusUpdate>;

StatusCode
~~~~~~~~~~~~~

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
~~~~~~~~~~~~~

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
~~~~~~~~~~~~~

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




Functions
---------

.. _statusUpdate:

statusUpdate
~~~~~~~~~~~~~

The ``statusUpdate`` function updates the status of BTC-Relay, e.g. restricting operation or recovering from a failure. 


Specification
..............

*Function Signature*

``statusUpdate(update)``

*Parameters*

* ``update``: StatusUpdate struct specifying the type and reason for the status change.


*Returns*

* ``True``: if the block header passes all checks.
* ``False`` (or throws exception): otherwise.

*Errors*

* (Currently not in use) ``ERR_INVALID_STATUS_UPDATE`` = "Requested status update is not allowed.": raise an exception when a status update is requested, which is not allowed. 

*Events*

* ``StatusUpdate(newStatus, block, errorCode, msg)`` - emits an event indicating the status change, with ``newStatus`` being the new ``StatusCode``, ``block`` is the block hash of the block which caused the status change, ``errorCode`` the ``ErrorCode`` specifying the reason for the status change, and ``msg`` the detailed message provided by the function caller. 

*Substrate*

::

  fn statusUpdate(origin, update: StatusUpdate) -> Result {...}


User Story
...........
This function is called by Staked Relayers and the Parachain's Governance Mechanism to indicate (possible) failures of BTC-Relay, or to recover from them. 

See the BTC-Relay `State Machine </spec/failure-handling.html#id2>`_ for more details.

Use Cases
...........
**Verification of Transaction Inclusion**:
To be able to verify that a transaction is included in the Bitcoin blockchain, the corresponding block at the specified ``txBlockHeight`` must be first submitted, verified and stored in the BTC-Relay via ``verifyBlockHeader``. 



Function Sequence
...................

1. Set ``Status``  to ``update.statusCode`` 
2. Emit ``StatusUpdate(update.statusCode, update.block, update.reason, update.msg)`` event 





Events
-------

Error Codes
------------
