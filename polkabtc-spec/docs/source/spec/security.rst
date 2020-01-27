.. _security:

Security
========================

The Security module is responsible for failure handling in the BTC Parachain, such as liveness and safety failures of :ref:`btc-relay` or crashes of the :ref:`exchange-rate-oracle`.
Specifically, this module provides a central interface for all other modules to check whether specific features should be disabled to prevent financial damage to users (e.g. stop :ref:`issue` if no reliable price data is available).
In addition, the Security module provides functions to handle security critical operations, such as generating secure identifiers for replay protection in :ref:`issue:`, :ref:`redeem`, and :ref:`replace`. 


Overview
~~~~~~~~

Failure Modes
--------------

The BTC Parachain can enter into different failure modes, depending on the occurred error.
An overview is provided in the figure below.

.. figure:: ../figures/failureModes.png
    :alt: State machine showing BTC-Relay failure modes

    State machine showing the operational and failure modes of BTC-Relay, and how to recover from or flag failures.


More details on the exact failure states and error codes are provided in the Specification part of this module description.

Roles
-----

Failure handling methods calls are **restricted**, i.e., can only be called by pre-determined roles.
We differentiate between:

* **Staked Relayers** - collateralized Parachain participants, whose main role it is to Bitcoin full nodes and check that:
    
    1. Transactional data is available for submitted Bitcoin block headers (``NO_DATA_BTC_RELAY: 0`` code)
    2. Submitted blocks are valid under Bitcoin's consensus rules  (``INVALID_BTC_RELAY: 1`` code).

 If one of the above failures is detected, Staked Relayers can halt BTC-Relay, providing information about the cause. Thereby, the Parachain acts as bulleting board and requires a pre-defined number / percentage of signatures of Staked Relayers.

* **Governance Mechanism** - Parachain Governance Mechanism, voting on critical changes to the architecture or unexpected failures, e.g. hard forks or detected 51% attacks (if a fork exceeds the specified security parameter *k*, see `Security Parameter k <security_performance/security.html#security-parameter-k>`_.). A manual intervention can be indicated via the ``UNEXPECTED: 2`` halting code. 


Data Model
~~~~~~~~~~


Constants
---------

STAKED_RELAYER_VOTE_THRESHOLD
...............................

Integer denoting the percentage of Staked Relayer signatures/votes necessary to alter the state of the BTC Parachain (``NO_DATA_BTC_RELAY`` and ``INVALID_BTC_RELAY`` error codes).

.. note:: Must be a number between 0 and 100.


*Substrate* ::

  STAKED_RELAYER_VOTE_THRESHOLD: U256;


STAKED_RELAYER_STAKE
......................

Integer denoting the minimum DOT stake which Staked Relayers must provide when registering. 


*Substrate* ::

  STAKED_RELAYER_STAKE: U256;


Scalars
--------

ParachainStatus
.................

Integer/Enum (see ``StatusCode`` below). Defines the current state of BTC-Relay. 

*Substrate* ::

  ParachainStatus: T::StatusCode;


ErrorStatus
-----------

List of error codes (``ErrorCode`` enums), indicating the reason for the error. The ``ErrorCode`` entries included in this list specify how to react to the failure (e.g. shutdown transaction verification in :ref:`btc-relay`).


*Substrate* ::

  ErrorStatus: Vec<T::ErrorCode>;


StatusLog
..........

Array of ``StatusUpdate`` structs, providing a history of status changes of the BTC Parachain. 

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

* ``RUNNING: 0`` - BTC Parachain fully operational

* ``ERROR: 1``- an error was detected in the BTC Parachain. See ``ErrorStatus`` for more details, i.e., the specific error codes (these determine how to react).

* ``SHUTDOWN: 2`` - Manual intervention (``UNEXPECTED`` error code). BTC Parachain operation fully suspended.

*Substrate* 

::

  enum StatusCode {
        RUNNING = 0,
        ERROR = 1,
        SHUTDOWN = 3,
  }

ErrorCode
.........

Enum specifying reasons for error leading to a status update.


* ``NO_DATA_BTC_RELAY: 0`` - it was not possible to fetch transactional data for a block header submitted to :ref:`btc-relay`. 

* ``INVALID_BTC_RELAY : 1`` - an invalid transaction was detected in a block header submitted to :ref:`btc-relay`. 

* ``ORACLE_OFFLINE : 2`` - the :ref:`exchangeRateOracle` experienced a liveness failure (no up-to-date exchange rate available).


* ``MANUAL_RESET: 3`` - manual reset to a new status (by Governance Mechanism).

* ``DATA_AVAILABLE: 4`` - previously unavailable data for a Bitcoin block header in :ref:`btc-relay` has become available again.

* ``VALID_FORK: 5`` - a chain reorganization occurred, excluding the block(s) marked as ``INVALID`` from the longest chain in :ref:`btc-relay`.

*Substrate*

::
  
  enum ErrorCode {
        NO_DATA_BTC_RELAY = 0,
        INVALID_BTC_RELAY = 1,
        ORACLE_OFFLINE = 2,
        //recovery codes
        MANUAL_RESET = 3,
        DATA_AVAILABLE = 4,
        VALID_FORK = 5
  }


.. todo:: Decide how to best separate codes for errors (necessary for checks from specific functions) and information on why a status was recovered from. 


.. todo:: Remove ``UNEXPECTED`` flag. If the BTC Parachain is shutdown, it is clear what happened (or a message is given in ``msg``).

Structs
--------

StatusUpdate
.............

Struct providing information for an occurred halting of BTC-Relay. Contains the following fields.

======================  ==============  ============================================
Parameter               Type            Description
======================  ==============  ============================================
``statusCode``          Status          New status code.
``blockHash``           H256            Block hash of the block header in ``_blockHeaders`` which caused the status change.  
``errorCode``           ErrorCode       Error code specifying the reason for the status change.          
``msg``                 String          [Optional] message providing more details on the change of status (error message or recovery). 
``votes``               Vec<AccountId>  List of accounts which have voted for this status update. This can be either Staked Relayers or the Governance Mechanism. Checks are performed depending on the type of status change.
======================  ==============  ============================================

*Substrate* 

::

  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct StatusUpdate<Status, H256, ErrorCode, AccountId> {
        statusCode: Status,
        blockHash: H256,
        errorCode: ErrorCode,
        msg: String,
        votes: Vec<AccountId>
  }



StakedRelayer
..............

Stores the information of a Staked Relayer.

.. tabularcolumns:: |l|l|L|

=========================  =========  ========================================================
Parameter                  Type       Description
=========================  =========  ======================================================== 
``stake``                  DOT        Total amount of collateral/stake provided by this Staked Relayer.
=========================  =========  ========================================================

*Substrate* 

::

  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct StatusUpdate<Balance> {
        stake: Balance
  }

.. note:: Struct used here in case more information needs to be stored for Staked Relayers, e.g. SLA (votes cast vs. votes missed).

Maps
----

StakedRelayers
...............

Mapping from accounts of StakedRelayers to their struct. ``<Account, StakedRelayer>``.

*Substrate* ::

    StakedRelayers map T::AccountId => StakedRelayer<Balance>



Functions
~~~~~~~~~

.. todo:: Add functions for (i) registering, de-registering and slashing of Staked Relayers, (ii) casting votes on status updates. 

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




