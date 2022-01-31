.. _treasury-module:

Treasury
========

Overview
~~~~~~~~

The treasury serves as the central storage for all interBTC.
It exposes the :ref:`transfer` function, which allows any user to transfer interBTC.
Three additional internal functions are exposed for the :ref:`issue-protocol` and :ref:`redeem-protocol` components. 

Step-by-step
------------

* **Transfer**: A user sends an amount of interBTC to another user by calling the :ref:`transfer` function.
* **Issue**: The issue module calls into the treasury when an issue request is completed (via :ref:`executeIssue`) and the user has provided a valid proof that the required amount of BTC was sent to the correct vault. The issue module calls the :ref:`mint` function to create interBTC.
* **Redeem**: The redeem protocol requires two calls to the treasury module. First, a user requests a redeem via the :ref:`requestRedeem` function. This invokes a call to the :ref:`lock` function that locks the requested amount of tokens for this user. Second, when a redeem request is completed (via :ref:`executeRedeem`) and the vault has provided a valid proof that it transferred the required amount of BTC to the correct user, the redeem module calls the :ref:`burn` function to destroy the previously locked interBTC.

Data Model
~~~~~~~~~~

Scalars
-------

.. _totalSupply:

TotalSupply
...........

The total supply of interBTC.

Maps
----

Accounts
........

Mapping from accounts to the ``Account`` struct.

Structs
-------

Account
.......

Stores the balances of a single account.

.. tabularcolumns:: |l|l|L|

============  =======  ======================================================
Parameter     Type     Description                                           
============  =======  ======================================================
``free``      Balance  Free and may be transferred without restriction.
``reserved``  Balance  Reserved and may not be used by holder until unlocked.
============  =======  ======================================================

Functions
~~~~~~~~~

.. _transfer:

transfer
--------

Transfers a specified amount of interBTC from a sender to a receiver.

Specification
.............

*Function Signature*

``transfer(sender, receiver, amount)``

*Parameters*

* ``sender``: Account sending an amount of interBTC.
* ``receiver``: Account receiving an amount of interBTC.
* ``amount``: The number of interBTC being sent.

*Events*

* :ref:`transferEvent`

*Preconditions*

* The function call MUST be signed by the ``sender``.
* The account MUST have sufficient free balance.

*Postconditions*

* The sender's free balance MUST decrease by ``amount``.
* The receiver's free balance MUST increase by ``amount``.

.. _mint:

mint
----

In the BTC Parachain new interBTC can be created by leveraging the :ref:`issue-protocol`.
However, to separate concerns and access to data, the Issue module has to call the ``mint`` function to complete the issue process in the interBTC component.
The function increases the ``totalSupply`` of interBTC.

.. warning:: This function can *only* be called from the Issue module.

Specification
.............

*Function Signature*

``mint(account, amount)``

*Parameters*

* ``account``: The account requesting interBTC.
* ``amount``: The amount of interBTC to be minted.

*Events*

* :ref:`mintEvent`

*Preconditions*

* The function MUST ONLY be called as part of the :ref:`issue-protocol`.

*Postconditions*

* The account's free balance MUST increase by ``amount``.
* The :ref:`totalSupply` MUST increase by ``amount``.

.. _lock:

lock
----

During the :ref:`redeem-protocol`, a user needs to be able to lock interBTC. Locking transfers coins from the ``free`` balance to the ``reserved`` balance to prevent users from transferring the coins.

Specification
.............

*Function Signature*

``lock(account, amount)``

*Parameters*

* ``account``: The account locking a certain amount of interBTC.
* ``amount``: The amount of interBTC that should be locked.

*Events*

* :ref:`lockEvent`

*Preconditions*

* The account MUST have sufficient free balance.

*Postconditions*

* The account's free balance MUST decrease by ``amount``.
* The account's reserved balance MUST increase by ``amount``.

.. _burn:

burn
----

During the :ref:`redeem-protocol`, users first lock and then "burn" (i.e. destroy) their interBTC to receive BTC. Users can only burn tokens once they are locked to prevent transaction ordering dependencies. This means a user first needs to move his tokens from the ``Balances`` to the ``LockedBalances`` mapping via the :ref:`lock` function.

.. warning:: This function can *only* be called from the Redeem module.

Specification
.............

*Function Signature*

``burn(account, amount)``

*Parameters*

* ``account``: The account burning locked interBTC.
* ``amount``: The amount of interBTC that should be burned.

*Events*

* :ref:`burnEvent`

*Preconditions*

* The account MUST have sufficient reserved balance.
* The function MUST ONLY be called from the :ref:`redeem-protocol`.

*Postconditions*

* The account's reserved balance MUST decrease by ``amount``.
* The :ref:`totalSupply` MUST decrease by ``amount``.

Events
~~~~~~

.. _transferEvent:

Transfer
--------

Issues an event when a transfer of funds was successful.

*Event Signature*

``Transfer(sender, receiver, amount)``

*Parameters*

* ``sender``: Account sending an amount of interBTC.
* ``receiver``: Account receiving an amount of interBTC.
* ``amount``: The number of interBTC being sent.

*Function*

* :ref:`transfer`

.. _mintEvent:

Mint
----
  
Issue an event when new interBTC are minted.

*Event Signature*

``Mint(account, amount)``

*Parameters*

* ``account``: The account requesting interBTC.
* ``amount``: The amount of interBTC to be added to an account.

*Function*

* :ref:`mint`

.. _lockEvent:

Lock
----

Emits the newly locked amount of interBTC by a user.

*Event Signature*

``Lock(redeemer, amount)``

*Parameters*

* ``account``: The account locking interBTC.
* ``amount``: The amount of interBTC that should be locked.

*Function*

* :ref:`lock`

.. _burnEvent:

Burn
----

Issue an event when the amount of interBTC is successfully destroyed.

*Event Signature*

``Burn(account, amount)``

*Parameters*

* ``account``: The account burning interBTC.
* ``amount``: The amount of interBTC that should be burned.

*Function*

* :ref:`burn`

Errors
~~~~~~

``ERR_INSUFFICIENT_FREE_BALANCE`` 

* **Message**: "The free balance of this account is insufficient to complete the transaction." 
* **Functions**: :ref:`transfer` | :ref:`lock` 
* **Cause**: The free balance of the account is too low to complete this action.

``ERR_INSUFFICIENT_RESERVED_BALANCE`` 

* **Message**: "The reserved balance of this account is insufficient to burn the tokens."
* **Function**: :ref:`burn`
* **Cause**: The reserved balance of the account is too low to complete this action.

