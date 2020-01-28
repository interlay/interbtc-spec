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

  STAKED_RELAYER_VOTE_THRESHOLD: U8;


STAKED_RELAYER_STAKE
......................

Integer denoting the minimum DOT stake which Staked Relayers must provide when registering. 


*Substrate* ::

  STAKED_RELAYER_STAKE: Balance;


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
Indicated ths status of the BTC Parachain.

* ``RUNNING: 0`` - BTC Parachain fully operational

* ``ERROR: 1``- an error was detected in the BTC Parachain. See ``ErrorStatus`` for more details, i.e., the specific error codes (these determine how to react).

* ``SHUTDOWN: 2`` - Manual intervention (``UNEXPECTED`` error code). BTC Parachain operation fully suspended.

*Substrate* 

::

  enum StatusCode {
        RUNNING = 0,
        ERROR = 1,
        SHUTDOWN = 2,
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


ProposalStatus
...............

Indicated the state of a proposed ``StatusUpdate``.

* ``PENDING: 0`` - this ``StatusUpdate`` is current under review and is being voted upon.

* ``ACCEPTED: 1``- this ``StatusUpdate`` has been accepted.

* ``REJECTED: 2`` -this ``StatusUpdate`` has been accepted.

*Substrate* 

::

  enum StatusCode {
        RUNNING = 0,
        ERROR = 1,
        SHUTDOWN = 3,
  }


Structs
--------

StatusUpdate
.............

Struct providing information for an occurred halting of BTC-Relay. Contains the following fields.

======================  ==============  ============================================
Parameter               Type            Description
======================  ==============  ============================================
``statusCode``          Status          New status code.
``time``                U256            Parachain block number at which this status update was suggested.
``proposalStatus``      ProposalStatus  Status of the proposed status update. See ``ProposalStatus``.
``errorCode``           ErrorCode       Error code specifying the reason for the status change.          
``msg``                 String          [Optional] message providing more details on the change of status (error message or recovery). 
``votesYes``            Vec<AccountId>  List of accounts which have voted FOT this status update. This can be either Staked Relayers or the Governance Mechanism. Checks are performed depending on the type of status change. Should maintain insertion order to allow checking who proposed this update (at index ``0``).
``votesNo``             Vec<AccountId>  List of accounts which have voted AGAINST this status update. 
======================  ==============  ============================================

.. note:: ``StatusUpdates`` executed by the Governance Mechanism are not voted upon by Staked Relayers (hence ``votesNo`` will be empty).

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


.. _registerStakedRelayer:

registerStakedRelayer
----------------------

Registers a new Staked Relayer, locking the provided collateral, which must exceed ``STAKED_RELAYER_STAKE``.

Specification
.............

*Function Signature*

``registerStakedRelayer(stakedRelayer, stake)``

*Parameters*

* ``stakedRelayer``: The account of the Staked Relayer to be registered.
* ``stake``: to-be-locked collateral/stake in DOT.

*Returns*

* ``None``

*Events*

* ``RegisterStakedRelayer(StakedRelayer, collateral)``: emit an event stating that a new Staked Relayer (``stakedRelayer``) was registered and provide information on the Staked Relayer's stake (``stake``). 

*Errors*

* ``ERR_ALREADY_REGISTERED = This AccountId is already registered as a Staked Relayer.``: The given account identifier is already registered. 
* ``ERR_INSUFFICIENT_STAKE = Insufficient stake provided.``: The provided stake was insufficient - it must be above ``STAKED_RELAYER_STAKE``.
  
*Substrate* ::

  fn registerStakedRelayer(origin, amount: Balance) -> Result {...}

Preconditions
.............

Function Sequence
.................

The ``registerStakedRelayer`` function takes as input a Parachain AccountID, and DOT collateral (to be used as stake), and registers a new Staked Relayer in the system.

1) Check that the Staked Relayer has not already registered. 

2) Check that ``stake > STAKED_RELAYER_STAKE`` holds, i.e., the Staked Relayer provided sufficient collateral. Return ``ERR_INSUFFICIENT_STAKE`` error if this check fails.

3) Store the provided information (amount of ``stake``) in a new ``StakedRelayer`` and insert it into the ``StakedRelayers`` mapping using the ``stakedRelayer`` AccountId as key.

4) Emit a ``RegisterStakedRelayer(StakedRelayer, collateral)`` event. 

5) Return.


.. _suggestStatusUpdate: 

suggestStatusUpdate
----------------------

Suggest a new status update and opens it up for voting.

.. warning:: This function can only be called by Staked Relayers.


.. todo:: TODO

Specification
.............

*Function Signature*

``registerStakedRelayer(stakedRelayer, stake)``

*Parameters*

* ``stakedRelayer``: The account of the Staked Relayer to be registered.
* ``stake``: to-be-locked collateral/stake in DOT.

*Returns*

* ``None``

*Events*

*Errors*

  
*Substrate* ::

  fn registerStakedRelayer(origin, amount: Balance) -> Result {...}

Preconditions
.............

Function Sequence
.................

.. _voteOnStatusUpdate: 

voteOnStatusUpdate
----------------------

A Staked Relayer casts a vote on a suggested ``StatusUpdate``.
Checks the threshold of votes and executes / cancels a StatusUpdate depending on the threshold reached.
 
.. warning:: This function can only be called by Staked Relayers.


.. todo:: TODO

Specification
.............

*Function Signature*

``voteOnStatusUpdate(stakedRelayer, vote)``

*Parameters*

* ``stakedRelayer``: The account of the voting Staked Relayer.
* ``vote``: ``True`` or ``False``, depending on whether the Staked Relayer agrees or disagrees with the suggested suggestStatusUpdate.

*Returns*

* ``None``

*Events*

* ``RegisterStakedRelayer(StakedRelayer, collateral)``: emit an event stating that a new Staked Relayer (``stakedRelayer``) was registered and provide information on the Staked Relayer's stake (``stake``). 

*Errors*


  
*Substrate* ::

  fn registerStakedRelayer(origin, amount: Balance) -> Result {...}

Preconditions
.............

Function Sequence
.................

.. _slashStakedRelayer: 

slashStakedRelayer
----------------------

Slashes the stake/collateral of a Staked Relayer and removed them from the Staked Relayer list (mapping).

.. warning:: This function can only be called by the Governance Mechanism.


.. todo:: TODO

Specification
.............

*Function Signature*

``slashStakedRelayer(stakedRelayer)``

*Parameters*

* ``stakedRelayer``: The account of the Staked Relayer to be slashed.

*Returns*

* ``None``

*Events*

*Errors*


  
*Substrate* ::

  fn stakedRelayer(stakedRelayer: AccountId) -> Result {...}

Preconditions
.............

Function Sequence
.................



.. _executeStatusUpdate:

executeStatusUpdate
--------------------

The ``statusUpdate`` function updates the status of BTC-Relay, e.g. restricting operation or recovering from a failure. 

.. warning:: This function can only be called (a) internally if a ``StatusUpdate`` has received more votes than required by ``STAKED_RELAYER_VOTE_THRESHOLD`` (b) by the Governance Mechanism.


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


.. _rejectStatusUpdate:

rejectStatusUpdate
--------------------

Rejects a suggested ``StatusUpdate``. 

.. note:: This function DOES NOT slash Staked Relayers who have lost the vote on this ``StatusUpdate``. Slashing is executed solely by the Governance Mechanism.


..todo:: TODO

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


.. _generateSecureId:

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




