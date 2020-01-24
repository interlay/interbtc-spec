.. _treasury-module:

Treasury
========

The treasury serves as the central storage for all PolkaBTC.

Data Model
~~~~~~~~~~

Constants
---------

- ``NAME``: ``PolkaBTC``
- ``SYMBOL``: ``pBTC``

Scalars
-------

TotalSupply
...........

The total supply of PolkaBTC.

*Substrate*: ``TotalSupply: Balance;``

Maps
----

Balances
........

Mapping from accounts to their balance. ``<Account, Balance>``.

*Substrate*: ``Balances: map T::AccountId => Balance;``

Functions
~~~~~~~~~

.. _transfer:

transfer
--------

Transfers a specified amount of PolkaBTC from a Sender to a Receiver on the BTC Parachain.

Specification
.............

*Function Signature*

``transfer(sender, receiver, amount)``

*Parameters*

* ``sender``: An account with enough funds to send the ``amount`` of PolkaBTC to the ``receiver``.
* ``receiver``: Account receiving an amount of PolkaBTC.
* ``amount``: The number of PolkaBTC being sent in the transaction.

*Returns*

* ``None``

*Events*

* ``Transfer(sender, receiver, amount)``: Issues an event when a transfer of funds was successful.

*Errors*

* ``ERR_INSUFFICIENT_FUNDS``: The sender does not have a high enough balance to send an ``amount`` of PolkaBTC.

*Substrate*

``fn transfer(origin, receiver: AccountId, amount: Balance) -> Result {...}``

Function Sequence
.................

The ``transfer`` function takes as input the sender, the receiver, and an amount. The function executes the following steps:

1. Check that the ``sender`` is authorised to send the transaction by verifying the signature attached to the transaction.
2. Check that the ``sender``'s balance is above the ``amount``. If ``balance(sender) < amount`` (in Substrate ``free_balance``), raise ``ERR_INSUFFICIENT_FUNDS`` and return ``False``.
        
3. Subtract the Sender's balance by ``amount`` and add ``amount`` to the Receiver's balance.

4. Emit the ``Transfer(sender, receiver, amount)`` event.

5. Return.

.. _mint:

mint
----

In the BTC Parachain new PolkaBTC can be created by leveraging the :ref:`Issue Protocol <issue-protocol>`.
However. to separate concerns and access to data, the Issue module has to call the ``mint`` function to complete the issue process in the PolkaBTC component.
The function increases the ``totalSupply`` of PolkaBTC.

.. warning:: This function can *only* be called from the Issue module.

Specification
.............

*Function Signature*

``mint(requester, amount)``

*Parameters*

* ``requester``: The account of the requester of PolkaBTC.
* ``amount``: The amount of PolkaBTC to be added to an account.

*Returns*

* ``None``

*Events*

* ``Mint(requester, amount)``: Issue an event when new PolkaBTC are minted.

*Substrate*

``fn mint(requester: AccountId, amount: Balance) -> Bool {...}``


Preconditions
.............

This is an internal function and can only be called by the :ref:`Issue module <issue-protocol>`.

Function Sequence
.................

1. Increase the ``requester`` balance by ``amount``.
2. Emit the ``Mint(requester, amount)`` event.
3. Return.

burn
----

During the :ref:`Redeem protocol <redeem-protocol>`, so-called Redeemers first lock and then destroy or burn their PolkaBTC to receive BTC. This function reflects this in their balance. 

.. warning:: This function is only internally callable by the Redeem module.

Specification
.............

*Function Signature*

``burn(redeemer, amount)``

*Parameters*

* ``redeemer``: The Redeemer wishing to burn a certain amount of PolkaBTC.
* ``amount``: The amount of PolkaBTC that should be destroyed.

*Returns*

* ``True``: If the Redeemer has sufficient funds and the balance of the Redeemer is reduced by the ``amount``.
* ``False``: Otherwise.

*Events*

* ``Burn(redeemer, amount)``: Issue an event when the amount of PolkaBTC is successfully destroyed.

*Errors*

* ``ERR_INSUFFICIENT_FUNDS``: If the Redeemer has insufficient funds, i.e. her balance is lower than the amount.

*Substrate*

``fn burn(redeemer: AccountId, amount: Balance) -> Bool {...}``

Preconditions
.............

This is an internal function and can only be called by the :ref:`Redeem module <redeem-protocol>`.

Function Sequence
.................

1. Check that the ``redeemer``'s balance is above the ``amount``. If ``balance(redeemer) < amount`` (in Substrate ``free_balance``), raise ``ERR_INSUFFICIENT_FUNDS`` and return ``False``.
3. Subtract the Redeemer's balance by ``amount``. 
4. Emit the ``Burn(redeemer, amount)`` event.
5. Return ``True``.

.. _lock:

lock
----

During the redeem process, Redeemers need to be able to lock PolkaBTC.

Specification
.............

*Function Signature*

``lock(redeemer, amount)``

*Parameters*

* ``redeemer``: The Redeemer wishing to lock a certain amount of PolkaBTC.
* ``amount``: The amount of PolkaBTC that should be locked.

*Returns*

* ``None``

*Events*

* ``Lock(redeemer, amount, totalAmount)``: newly locked and totally locked amount of PolkaBTC by a redeemer.

*Errors*

* ``ERR_INSUFFICIENT_FUNDS``: Redeemer has not enough PolkaBTC to lock coins.

*Substrate* ::

  fn lock(origin, ) -> Result {...}

Precondition
............

* Can only be called by the redeem module.

Function Sequence
.................

1. 


Events
~~~~~~

* ``Transfer(sender, receiver, amount)``: Issues an event when a transfer of funds was successful.
* ``Mint(requester, amount)``: Issue an event when new PolkaBTC are minted.
* ``Burn(redeemer, amount)``: Issue an event when the amount of PolkaBTC is successfully destroyed.

Errors
~~~~~~

* ``ERR_INSUFFICIENT_FUNDS``: ``The balance of this account is insufficient to complete the transaction``. 

