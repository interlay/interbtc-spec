.. _security:

Security
======== 

The Security module is responsible for tracking the status of the BTC Parachain, flagging failures such as liveness and safety failures of :ref:`btc-relay` or crashes of the :ref:`exchange-rate-oracle`.
Specifically, this module provides a central interface for all other modules to check whether specific features should be disabled to prevent financial damage to users (e.g. stop :ref:`issue-protocol` if no reliable price data is available).
In addition, the Security module provides functions to handle security critical operations, such as generating secure identifiers for replay protection in :ref:`issue-protocol`, :ref:`redeem-protocol`, and :ref:`replace-protocol`. 


Overview
~~~~~~~~

Failure Modes
--------------

The BTC Parachain can enter into different failure modes, depending on the occurred error.
An overview is provided in the figure below.

.. figure:: ../figures/failureModes.png
    :alt: State machine showing BTC-Relay failure modes

    (Informal) State machine showing the operational and failure modes of BTC-Relay, and how to recover from or flag failures. Note: within the ``ERROR`` state, ``ErrorCode`` states are only exclusive within a single module (i.e., BTC-Relay ``NO_DATA_BTC_RELAY`` and ``INVALID_BTC_RELAY`` are exclusive, but there can be an ``ORACLE_OFFLINE`` or ``LIQUIDATION`` error in parallel).


More details on the exact failure states and error codes are provided in the Specification part of this module description.

Failure handling methods calls are **restricted**, i.e., can only be called by pre-determined roles.

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

*Substrate* 

::

  enum StatusCode {
        RUNNING = 0,
        ERROR = 1,
        SHUTDOWN = 2,
  }

ErrorCode
.........

Enum specifying error codes tracked in ``Errors``.


* ``NONE : 0`` - no error has occurred (used to simplify implementation). 

* ``NO_DATA_BTC_RELAY: 1`` - it was not possible to fetch transactional data for a block header submitted to :ref:`btc-relay`. 

* ``INVALID_BTC_RELAY : 2`` - an invalid transaction was detected in a block header submitted to :ref:`btc-relay`. 

* ``ORACLE_OFFLINE : 3`` - the :ref:`exchangeRateOracle` experienced a liveness failure (no up-to-date exchange rate available).

* ``LIQUIDATION : 4`` - at least one Vault is either below the ``LiquidationCollateralThreshold`` or has been reported to have stolen BTC. This status implies that any :ref:`redeem-protocol` request will be executed partially in BTC and partially in DOT, until the system is rebalanced (1:1 backing between PolkaBTC and BTC). 

*Substrate*

::
  
  enum ErrorCode {
        NONE = 0
        NO_DATA_BTC_RELAY = 1,
        INVALID_BTC_RELAY = 2,
        ORACLE_OFFLINE = 3,
        LIQUIDATION = 4
  }


Data Storage
~~~~~~~~~~~~

Scalars
--------

ParachainStatus
.................

Integer/Enum (see ``StatusCode`` below). Defines the current state of the BTC Parachain. 

*Substrate* ::

  ParachainStatus: StatusCode;


Errors
........

Set of error codes (``ErrorCode`` enums), indicating the reason for the error. The ``ErrorCode`` entries included in this set specify how to react to the failure (e.g. shutdown transaction verification in :ref:`btc-relay`).


*Substrate* ::

  Errors: BTreeSet<ErrorCode>;



Nonce
.....

Integer increment-only counter, used to prevent collisions when generating identifiers for e.g. issue, redeem or replace requests (for OP_RETURN field in Bitcoin).

*Substrate* ::

  Nonce: U256;





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

* ``account``: Parachain account identifier (links this identifier to the AccountId associated with the process where this secure id is to be used, e.g. the user calling :ref:`requestIssue`).

*Returns*

* ``hash``: a cryptographic hash generated via a secure hash function.

*Substrate* ::

  fn generateSecureId(account: AccountId) -> T::H256 {...}

Function Sequence
.................

1. Increment the ``Nonce``.
2. Concatenate ``account``, ``Nonce``, and ``random_seed()``.
3. SHA256 hash the result of step 1.
4. Return the resulting hash.

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

*Substrate* ::

  fn getStatusCounter() -> U256 {...}

Function Sequence
.................

1. ``StatusCounter++``
2. Return ``StatusCounter``


Events
~~~~~~~

No events are emitted by this module.

Error Codes
~~~~~~~~~~~

No erros are throws by this module.