.. _oracle:

Exchange Rate Oracle
======

.. todo:: I think the oracle should be in a separate component, like BTC-Relay. And we do not implement / specify it, as this is not part of the Milestone plan. This is a whole new project. For our PoC we can just have a daemon feeding exchange rate data. 


The Exchange Rate Oracle receives a continous data feed on the exchage rate between BTC and DOT.

The implementation of the oracle **is not part of this specification**. PolkaBTC assumes the oracle operates correclty and that the received data is reliable. 

Data Model
~~~~~~~~~~

Scalars
--------

ExchangeRate
............

The BTC to DOT exchange rate. This exchange rate is used to determine how much collateral is required to issue a specific amount of PolkaBTC.

.. todo:: What granularity should we set here?

*Substrate*: ``ExchangeRate: U256;``


.. todo:: Do we maintain a log of submitted exchange rate "ticks"? Or do we just maintain the value of the current rate? For stability, probably better to maintain a (FIFO) log. 



Functions
~~~~~~~~~

setExchangeRate
----------------

Set the latest (aggregate) BTC/DOT exchange rate. This function invokes a check of Vault collateral rates in the `StabilizedCollateral </spec/stabilized-collateral.html#stabilized-collateral>`_ component.

Specification
.............

*Function Signature*

``setExchangeRate(oracle, rate)``

*Parameters*

* ``oracle``: the oracle account calling this function. Must be pre-authorized and tracked in this component!
* ``rate``: the ``U256`` BTC/DOT exchange rate


*Substrate*

``fn setExchangeRate(origin, rate:U256) -> U256 {...}``

*Errors*

``ERR_INVALID_ORACLE_SOURCE``: the caller of the function was not the authorized oracle. 

.. todo:: Check how to handle caller validation in Substrate - only pre-defined oracle should be allowed to call this function.

User Story
..........
 
This function can be only called by a/the pre-defined oracle.


getExchangeRate
----------------

Returns the latest (aggregate) BTC/DOT exchange rate, as received from the external data sources.

Specification
.............

*Function Signature*

``getExchangeRate()``

*Returns*

* `U256` (aggregate) exchange rate value


*Substrate*

``fn getExchangeRate() -> U256 {...}``

*Errors*

``ERR_MISSING_EXCHANGE_RATE``: the last exchange rate information exceeded the maximum delay acceptable by the oracle. 

User Story
..........
 
This function can be called by any participant to retrieve the BTC/DOT exchange rate as tracked by the BTC Parachain.


Events
~~~~~~~~~~~~

This component emits no events.

Error Codes
~~~~~~~~~~~~

``ERR_MISSING_EXCHANGE_RATE``: the last exchange rate information exceeded the maximum delay acceptable by the oracle. 

``ERR_INVALID_ORACLE_SOURCE``: the caller of the function was not the authorized oracle. 

.. todo:: Halt PolkaBTC if the exchange rate oracle fails: liveness failure if no more data is incoming, as well as safety failure if the Governance Mechanism flags incorrect exchange rates.