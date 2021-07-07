.. _oracle:

Exchange Rate Oracle
====================

.. note:: This exchange oracle module is a bare minimum model that relies on a single trusted oracle source. Decentralized oracles are a difficult and open research problem that is outside of the scope of this specification. However, the general interface to get the exchange rate can remain the same even with different constructions.


The Exchange Rate Oracle receives a continuous data feed on the exchange rate between two currencies such as BTC and DOT.

The implementation of the oracle **is not part of this specification**. InterBTC assumes the oracle operates correctly and that the received data is reliable. 


Data Model
~~~~~~~~~~

Scalars
-------

ExchangeRate
............

The base exchange rate MUST be stored in the smallest denomination of the currency pair (e.g., Planck per Satoshi). This exchange rate is used to determine how much collateral is required to issue a specific amount of interBTC.

.. note:: If the exchange rate between BTC and DOT is 2308 (i.e. 1 BTC = 2308 DOT) then we can convert to the base rate as follows:
    ``planck_per_satoshi = dot_per_btc * (10**dot_decimals / 10**btc_decimals)``
    ``230800 = 2308 * (10**10 / 10**8)``

The exchange rate MUST be stored in a 128-bit unsigned fixed-point representation.

SatoshiPerBytes
...............

The estimated Satoshis per bytes required to get a Bitcoin transaction included - see the :ref:`btcTxFeesPerByte`.

MaxDelay
........

The maximum delay in seconds between incoming calls providing exchange rate data. If the Exchange Rate Oracle receives no data for more than this period, the BTC Parachain enters an ``Error`` state with a ``ORACLE_OFFLINE`` error cause.

LastExchangeRateTime
....................

UNIX timestamp indicating when the last exchange rate data was received. 


Structs
-------

.. _btcTxFeesPerByte:

BtcTxFeesPerByte
................

The estimated inclusion time for a Bitcoin transaction MUST be stored in Satoshis per byte.

* ``fast`` - the fee to include a BTC transaction within the next block.
* ``half``- the fee to include a BTC transaction within the next three blocks (~30 min).
* ``hour`` - the fee to include a BTC transaction within the six blocks  (~60 min).

Maps
----

AuthorizedOracles
.................

The account(s) of the oracle. Returns true if registered as an oracle.


Functions
~~~~~~~~~

.. _setExchangeRate:

setExchangeRate
---------------

This function sets the latest base exchange rate.

Specification
.............

*Function Signature*

``setExchangeRate(oracleId, rate)``

*Parameters*

* ``oracleId``: the oracle account calling this function.
* ``rate``: the fixed point exchange rate.

*Events*

* ``SetExchangeRate(oracleId, rate)``: Emits the new exchange rate when it is updated by the oracle.

*Preconditions*

* The function call MUST be signed by ``oracleId``.
* The BTC Parachain status in the :ref:`security` component MUST NOT be ``SHUTDOWN:2``.
* The oracle MUST be authorized.

*Postconditions*

* The ``ExchangeRate`` MUST be set to the provided ``rate``.
* The ``LastExchangeRateTime`` MUST be updated to the current time.
* If the status in :ref:`security` is ``ERROR:1``, the system MUST be set to ``RUNNING:0``.

.. _setBtcTxFeesPerByte:

setBtcTxFeesPerByte
-------------------

Set the Satoshi per bytes fee rates.

Specification
.............

*Function Signature*

``setBtcTxFeesPerByte(oracleId, btcTxFeesPerByte)``

*Parameters*

* ``oracleId``: the oracle account calling this function.
* ``btcTxFeesPerByte``: the estimated inclusion fees.

*Events*

* ``SetSatoshiPerByte(oracleId, btcTxFeesPerByte)``: Emits the new btc fee rates when updated by the oracle.

*Preconditions*

* The function call MUST be signed by ``oracleId``.
* The BTC Parachain status in the :ref:`security` component MUST NOT be ``SHUTDOWN:2``.
* The oracle MUST be authorized.

*Postconditions*

* The ``SatoshiPerBytes`` MUST be set to the provided ``btcTxFeesPerByte``.

.. _getExchangeRate:

getExchangeRate
---------------

Returns the latest exchange rate, as received from the external data sources.

Specification
.............

*Function Signature*

``getExchangeRate()``

*Preconditions*

* The ``LastExchangeRateTime`` MUST NOT be before the current time minus the ``MaxDelay``.

*Postconditions*

* MUST return the fixed point base exchange rate.

.. _getLastExchangeRateTime:

getLastExchangeRateTime
------------------------

Returns the UNIX timestamp of when the last exchange rate was received from the external data sources.

Specification
.............

*Function Signature*

``getLastExchangeRateTime()``

*Postconditions*

* MUST return the 32-bit UNIX timestamp.


Events
~~~~~~

setExchangeRate
---------------

Emits the new exchange rate when it is updated by the oracle.

*Event Signature*

``SetExchangeRate(oracleId, rate)`` 

*Parameters*

* ``oracleId``: the oracle account calling this function.
* ``rate``: the fixed point exchange rate.

*Function*

* :ref:`setExchangeRate`

setBtcTxFeesPerByte
-------------------

Emits the new tx fee rates when they are updated by the oracle.

*Event Signature*

``SetSatoshiPerByte(oracleId, btcTxFeesPerByte)`` 

*Parameters*

* ``oracleId``: the oracle account calling this function.
* ``btcTxFeesPerByte``: the estimated inclusion fees.

*Function*

* :ref:`setBtcTxFeesPerByte`


Error Codes
~~~~~~~~~~~

``ERR_MISSING_EXCHANGE_RATE``

* **Message**: "Exchange rate not set."
* **Function**: :ref:`getExchangeRate` 
* **Cause**: The last exchange rate information exceeded the maximum delay acceptable by the oracle. 

``ERR_INVALID_ORACLE_SOURCE``

* **Message**: "Invalid oracle account."
* **Function**: :ref:`setExchangeRate` 
* **Cause**: The caller of the function was not authorized. 
