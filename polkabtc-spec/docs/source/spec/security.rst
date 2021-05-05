.. _security:

Security
======== 

The Security module is responsible for tracking the status of the BTC Parachain, flagging failures such as liveness and safety failures of :ref:`btc-relay` or crashes of the :ref:`oracle`.
Specifically, this module provides a central interface for all other modules to check whether specific features should be disabled to prevent financial damage to users (e.g. stop :ref:`issue-protocol` if no reliable price data is available).
In addition, the Security module provides functions to handle security critical operations, such as generating secure identifiers for replay protection in :ref:`issue-protocol`, :ref:`redeem-protocol`, and :ref:`replace-protocol`. 
Finally, the Security module keeps track of the ``active_block_number``, which is a counter variable that increments in every block where there are no active errors. This variable is used throughout the project to keep track of durations,


Overview
~~~~~~~~

Failure Modes
-------------

The BTC Parachain can enter into different failure modes, depending on the occurred error.
An overview is provided in the figure below.

.. figure:: ../figures/failureModes.png
    :alt: State machine showing BTC-Relay failure modes

    (Informal) State machine showing the operational and failure modes of BTC-Relay, and how to recover from or flag failures. Note: within the ``ERROR`` state, ``ErrorCode`` states are only exclusive within a single module (i.e., BTC-Relay ``NO_DATA_BTC_RELAY`` and ``INVALID_BTC_RELAY`` are exclusive, but there can be an ``ORACLE_OFFLINE`` or ``LIQUIDATION`` error in parallel).


More details on the exact failure states and error codes are provided in the Specification part of this module description.

Failure handling methods calls are **restricted**, i.e., can only be called by pre-determined roles.

.. _no-data-err:

Missing Data in BTC-Relay (No Data)
-----------------------------------

It was not possible to fetch transactional data for a block header submitted to :ref:`btc-relay`. 
This can happen if a staked relayer detects a BTC header inside the BTC-Relay that the relayer does not yet have in its Bitcoin full node.

**Error code:** ``NO_DATA_BTC_RELAY``

.. _invalid-btc-relay-err:

Invalid BTC-Relay
-----------------

An invalid transaction was detected in a block header submitted to :ref:`btc-relay`. 

**Error code:** ``INVALID_BTC_RELAY``


.. _liquidation-err:

Liquidation
-----------

The entire system collateralization is below the ``LiquidationCollateralThreshold``.

**Error code:** ``LIQUIDATION``


.. _oracle-offline-err:

Oracle Offline
--------------

The :ref:`oracle` experienced a liveness failure (no up-to-date exchange rate available).

**Error code:** ``ORACLE_OFFLINE``


Data Model
~~~~~~~~~~

Enums
------

StatusCode
...........
Indicates ths status of the BTC Parachain.

* ``RUNNING: 0`` - BTC Parachain fully operational

* ``ERROR: 1``- an error was detected in the BTC Parachain. See ``Errors`` for more details, i.e., the specific error codes (these determine how to react).

* ``SHUTDOWN: 2`` - BTC Parachain operation fully suspended. This can only be achieved via manual intervention by the Governance Mechanism.

ErrorCode
.........

Enum specifying error codes tracked in ``Errors``.


* ``NONE: 0``

* ``NO_DATA_BTC_RELAY: 1``

* ``INVALID_BTC_RELAY: 2``

* ``ORACLE_OFFLINE: 3``

* ``LIQUIDATION: 4``


Data Storage
~~~~~~~~~~~~

Scalars
--------

ParachainStatus
.................

Integer/Enum (see ``StatusCode`` below). Defines the current state of the BTC Parachain. 

.. *Substrate* ::

  ParachainStatus: StatusCode;


Errors
........

Set of error codes (``ErrorCode`` enums), indicating the reason for the error. The ``ErrorCode`` entries included in this set specify how to react to the failure (e.g. shutdown transaction verification in :ref:`btc-relay`).


.. *Substrate* ::

  Errors: BTreeSet<ErrorCode>;



Nonce
.....

Integer increment-only counter, used to prevent collisions when generating identifiers for e.g. issue, redeem or replace requests (for OP_RETURN field in Bitcoin).

.. *Substrate* ::

  Nonce: U256;


.. _activeBlockCount:

ActiveBlockCount
................

A counter variable that increments every block where the parachain status is ``RUNNING:0``. This variable is used to keep track of durations, such as issue/redeem/replace expiry. This is used instead of the block number because if the parachain status is not ``RUNNING:0``, no payment proofs can be submitted, so it would not be fair towards users and vaults to continue counting down the (expiry) periods. 


Functions
~~~~~~~~~

.. _generateSecureId:

generateSecureId
----------------

Generates a unique ID using an account identifier, the ``Nonce`` and a random seed.

Specification
.............

*Function Signature*

``generateSecureId(account)``

*Parameters*

* ``account``: Parachain account identifier (links this identifier to the AccountId associated with the process where this secure id is to be used, e.g., the user calling :ref:`requestIssue`).

*Returns*

* ``hash``: a cryptographic hash generated via a secure hash function.

.. *Substrate* ::

  fn generateSecureId(account: AccountId) -> T::H256 {...}

Function Sequence
.................

1. Increment the ``Nonce``.
2. Concatenate ``account``, ``Nonce``, and ``parent_hash()``.
3. SHA256 hash the result of step 1.
4. Return the resulting hash.

.. note:: The funtion ``parent_hash()`` is assumed to return the hash of the parachain's parent block - which precedes the block this function is called in.

.. _getStatusCounter:

getStatusCounter
----------------

Increments the current ``StatusCounter`` and returns the new value.

Specification
.............

*Function Signature*

``getStatusCounter()``


*Returns*

* ``U256``: the new value of the ``StatusCounter``.

.. *Substrate* ::

  fn getStatusCounter() -> U256 {...}

Function Sequence
.................

1. ``StatusCounter++``
2. Return ``StatusCounter``


.. _hasExpired:

hasExpired
----------------

Checks if the given period has expired since the given starting point. This calculation is based on the :ref:`activeBlockCount`.

Specification
.............

*Function Signature*

``has_expired(opentime, period)``

*Parameters*

* ``opentime``: the :ref:`activeBlockCount` at the time the issue/redeem/replace was opened.

* ``period``: the number of blocks the user or vault has to complete the action.


*Returns*

* ``true`` if the period has expired

Function Sequence
.................

1. Add the ``opentime`` and ``period``.
2. Compare this against :ref:`activeBlockCount`.



Events
~~~~~~~

No events are emitted by this module.

Error Codes
~~~~~~~~~~~

No erros are throws by this module.
