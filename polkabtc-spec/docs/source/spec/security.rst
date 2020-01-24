.. _security:

Security
========================

.. todo:: Update text: no longer BTC-Relay only, but entire Parachain, incl. exchange rate oracle.  

The BTC-Relay provides additional methods for failure handling, e.g. in case an attack on the Parachain or Bitcoin itself is detected. 
**Please first see** `Failure Modes: Halting and Recovery <security_performance/security.html#security-parameter-k>`_ for an explanation of how BTC-Relay can handle and recover from failures.


Overview
~~~~~~~~

Failure Modes
--------------

BTC-Relay can enter into different failure modes, depending on the occurred error.
See figure below. 


.. figure:: ../figures/failureModes.png
    :alt: State machine showing BTC-Relay failure modes

    State machine showing the operational and failure modes of BTC-Relay, and how to recover from or flag failures.

Roles
-----

Failure handling methods calls are **restricted**, i.e., can only be called by pre-determined roles.
We differentiate between:

* **Staked Relayers** - collateralized Parachain participants, whose main role it is to Bitcoin full nodes and check that:
    
    1. Transactional data is available for submitted Bitcoin block headers (``NO_DATA_BTC_RELAY: 0`` code)
    2. Submitted blocks are valid under Bitcoin's consensus rules  (``INVALID_BTC_RELAY: 1`` code).

 If one of the above failures is detected, staked relayers can (*TODO: together or individually?*) halt BTC-Relay, providing information about the cause. 

* **Governance Mechanism** - Parachain governance mechanism, voting on critical changes to the architecture or unexpected failures, e.g. hard forks or detected 51% attacks (if a fork exceeds the specified security parameter *k*, see `Security Parameter k <security_performance/security.html#security-parameter-k>`_.). A manual intervention can be indicated via the ``UNEXPECTED: 2`` halting code. 


Data Model
~~~~~~~~~~


Scalars
--------

Status
.......

Integer/Enum (see StatusCode below). Defines the curret state of BTC-Relay. 

StatusLog
..........

Array of ``StatusUpdate`` structs, providing a history of status changes of BTC-Relay.

.. note:: If pruning is implemented for ``BlockHeaders`` and ``Chains`` as performance optimization, ``StatusLog`` entries referencing pruned blocks should be deleted as well. 


*Substrate* ::

  StatusLog: Vec<StatusUpdate>;



Nonce
.....

Integer increment-only counter, used to prevent collisions when generating identifiers for e.g. issue, redeem or replace requests (for OP_RETURN field in Bitcoin).

*Substrate* ::

  Nonce: U256;


Enums
------

StatusCode
...........

* ``RUNNING: 0`` - BTC-Relay fully operational

* ``PARTIAL : 1`` - ``NO_DATA_BTC_RELAY`` detected or manual intervention. Transaction verification disabled for latest blocks.

.. note:: The exact threshold (in terms of block height) for disabling the verification of transactions in the ``PARTIAL`` state must be defined upon deployment. A possible approach is to keep intact transaction inclusion verification for blocks with a height lower than the height of the first ``NO_DATA_BTC_RELAY`` block.


* ``HALTED: 2`` - ``INVALID_BTC_RELAY`` detected or manual intervention. Transaction verification fully suspended.

* ``SHUTDOWN: 3`` - Manual intervention (``UNEXPECTED``). BTC-Relay operation fully suspended.

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


* ``NO_DATA_BTC_RELAY: 0`` - it was not possible to fetch transactional data for a block header submitted to :ref:`btc-relay`. 

* ``INVALID_BTC_RELAY : 1`` - an invalid transaction was detected in a block header submitted to :ref:`btc-relay`. 

* ``NO_EXCHANGE_RATE : 2`` - the :ref:`exchangeRateOracle` experienced a liveness failure (no up-to-date exchange rate available).

* ``UNEXPECTED: 2`` - unexpected error occurred, potentially manual intervention from governance mechanism. See  ``msg`` for reason.


*Substrate*

::
  
  enum ErrorCode {
        NO_DATA_BTC_RELAY = 0,
        INVALID_BTC_RELAY = 1,
        UNEXPECTED = 2,
  }


Structs
~~~~~~~

StatusUpdate
------------

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
~~~~~~~~~

.. _statusUpdate:

statusUpdate
------------

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


Precondition
..............


Function Sequence
...................

1. Set ``Status``  to ``update.statusCode`` 
2. Emit ``StatusUpdate(update.statusCode, update.block, update.reason, update.msg)`` event 




generateSecureId
----------------

Generates a unique ID using a the account identifier, the ``Nonce`` and a random seed.

Specification
.............

*Function Signature*

``generateId(account)``

*Parameters*

* ``account``: Parachain account identifier (links this identifier to the AccountId associated with the process where this secure id is to be used, e.g. the user calling :ref:`requestIssue`).

*Returns*

* ``hash``:

*Substrate* ::

  fn generateId(account: AccountId) -> T::H256 {...}

Function Sequence
.................

1. Concatenate ``account``, ``Nonce``, and ``random_seed()``.
2. SHA256 hash the result of step 1.
3. Return the resulting hash.

.. todo:: Decide how to implement ``random_seed()``. Use Substrate module?


Events
~~~~~~~

Error Codes
~~~~~~~~~~~




