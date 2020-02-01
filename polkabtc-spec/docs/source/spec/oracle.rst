.. _oracle:

Exchange Rate Oracle
====================

.. .. todo:: I think the oracle should be in a separate component, like BTC-Relay. And we do not implement / specify it, as this is not part of the Milestone plan. This is a whole new project. For our PoC we can just have a daemon feeding exchange rate data. 

.. note:: This exchange oracle module is a bare minimum model that relies on a single trusted oracle source. Decentralized oracles are a difficult and open research problem that is outside of the scope of this specification. However, the general interface to get the exchange rate can remain the same even with different constructions.


The Exchange Rate Oracle receives a continuous data feed on the exchange rate between BTC and DOT.

The implementation of the oracle **is not part of this specification**. PolkaBTC assumes the oracle operates correctly and that the received data is reliable. 


.. todo:: Update BTC Parachain status to ``ORACLE_OFFLINE`` if oracle stops receiving sending price data, and recover (using :ref:`recoverFromORACLEOFFLINE`) when data becomes available again.

Data Model
~~~~~~~~~~

Constants
---------

GRANULARITY
...........

The granularity of the exchange rate. The granularity is set to :math:`10^{-5}`.

*Substrate* ::

  GRANULARITY: u128 = 5;

Scalars
-------

ExchangeRate
............

The BTC to DOT exchange rate. This exchange rate is used to determine how much collateral is required to issue a specific amount of PolkaBTC. 

.. note:: If the ``ExchangeRate`` is set to 1238763, it translates to :math:`12.38763` as the last five digits are used for the floating point (as defined by the ``GRANULARITY``).



.. .. todo:: What granularity should we set here?

*Substrate* ::

    ExchangeRate: u128;


.. .. todo:: Do we maintain a log of submitted exchange rate "ticks"? Or do we just maintain the value of the current rate? For stability, probably better to maintain a (FIFO) log. 

AuthorizedOracle
................

The account of the oracle. 

*Substrate* ::

  AuthorizedOracle: AccountId;

Functions
~~~~~~~~~

.. _setExchangeRate:

setExchangeRate
----------------

Set the latest (aggregate) BTC/DOT exchange rate. This function invokes a check of Vault collateral rates in the :ref:`Vault-registry` component.

Specification
.............

*Function Signature*

``setExchangeRate(oracle, rate)``

*Parameters*

* ``oracle``: the oracle account calling this function. Must be pre-authorized and tracked in this component!
* ``rate``: the ``u128`` BTC/DOT exchange rate

*Returns*

* ``None``

*Events*

* ``SetExchangeRate(oracle, rate)``: Emits the new exchange rate when it is updated by the oracle.

*Errors*

* ``ERR_INVALID_ORACLE_SOURCE``: the caller of the function was not the authorized oracle. 

*Substrate* ::

    fn setExchangeRate(origin, rate:u128) -> Result {...}


.. .. todo:: Check how to handle caller validation in Substrate - only pre-defined oracle should be allowed to call this function.

Preconditions
.............
 
* The BTC Parachain status in the :ref:`security` component must be set to ``RUNNING:0``.

Function Sequence
.................

1. Check if the caller of the function is the ``AuthorizedOracle``. If not, throw ``ERR_INVALID_ORACLE_SOURCE``.
2. Update the ``ExchangeRate`` with the ``rate``.
3. Trigger the ``updateCollateralRates`` function in the :ref:`Vault-registry`.
4. Emit the ``SetExchangeRate`` event.
5. Return.

.. _getExchangeRate:

getExchangeRate
----------------

Returns the latest BTC/DOT exchange rate, as received from the external data sources.

Specification
.............

*Function Signature*

``getExchangeRate()``

*Returns*

* `u128` (aggregate) exchange rate value


*Substrate*

``fn getExchangeRate(origin) -> Result<u128, ERR_MISSING_EXCHANGE_RATE> {...}``

*Errors*

``ERR_MISSING_EXCHANGE_RATE``: the last exchange rate information exceeded the maximum delay acceptable by the oracle. 

Preconditions
.............
 
This function can be called by any participant to retrieve the BTC/DOT exchange rate as tracked by the BTC Parachain.

Function Sequence
.................

1. Return the ``ExchangeRate`` from storage.


Events
~~~~~~~~~~~~

SetExchangeRate
--------------

Emits the new exchange rate when it is updated by the oracle.

*Event Signature*

``SetExchangeRate(oracle, rate)`` 

*Parameters*

* ``oracle``: the oracle account calling this function. Must be pre-authorized and tracked in this component!
* ``rate``: the ``u128`` BTC/DOT exchange rate

*Function*

:ref:`setExchangeRate`

*Substrate* ::

    SetExchangeRate(AccountId, u128);

Error Codes
~~~~~~~~~~~~

``ERR_MISSING_EXCHANGE_RATE``

* **Message**: "Exchange rate not set."
* **Function**: :ref:`getExchangeRate` 
* **Cause**: The last exchange rate information exceeded the maximum delay acceptable by the oracle. 



``ERR_INVALID_ORACLE_SOURCE``

* **Message**: "Invalid oracle account."
* **Function**: :ref:`setExchangeRate` 
* **Cause**: The caller of the function was not the authorized oracle. 

.. todo:: Halt PolkaBTC if the exchange rate oracle fails: liveness failure if no more data is incoming, as well as safety failure if the Governance Mechanism flags incorrect exchange rates.
