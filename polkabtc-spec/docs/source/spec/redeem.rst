.. _redeem-protocol:

Redeem
======

Overview
~~~~~~~~

Step-by-step
------------

1. Precondition: A user owns PolaBTC.
2. A user locks an amount of PolkaBTC by calling the ``lock`` function. Further, the user selects a vault to execute the redeem request from the list of vaults. The function creates a redeem request with a unique hash.
3. The selected vault listens for the ``Lock`` event issued by the user. The vault then proceeds to transfer BTC to the address specified by the user in the ``lock`` function including a unique hash in the ``OP_RETURN`` of one output.
4. The vault executes the ``redeem`` function by providing the Bitcoin transaction from step 3 together with the redeem request identifier within the time limit. If the function completes successfully, the locked PolkaBTC are destroyed and the user received its BTC. If the function is not successful, a user executes step 5.
5. If step 4 completed unsuccessfully, the user calls ``slash`` after the redeem time limit. The user is then refunded with the DOT collateral the vault provided.

lock
----

A user locks PolkaBTC to start the redeem procedure.

Specification
.............

*Function Signature*

``lock(redeemer, amount, btcPublicKey, vaults)``

*Parameters*

* ``redeemer``: 

*Returns*

* ``True``:

*Events*

* ````:

*Errors*

* ````:

*Substrate* ::

  fn lock(origin, ) -> Result {...}

User Story
..........


Function Sequence
.................

