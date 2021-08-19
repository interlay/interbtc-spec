.. _collateral-module:

Collateral
==========

Overview
~~~~~~~~

The Collateral module is the central storage for collateral provided by users and vaults of the system.
It allows to (i) lock, (ii) release, and (iii) slash collateral of either users or vaults.
It can only be accessed by other modules and not directly through external transactions.

Step-by-Step
------------

The protocol has three different "sub-protocols".

- **Lock**: Store a certain amount of collateral from a single entity (user or vault).
- **Release**: Transfer a certain amount of collateral back to the entity that paid it.
- **Slash**: Transfer a certain amount of collateral to a party that was damaged by the actions of another party.

Data Model
~~~~~~~~~~

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

======================  ==========  =======================================================	
Parameter               Type        Description                                            
======================  ==========  =======================================================
``free``                Balance     Free and may be transferred without restriction.
``reserved``            Balance     Reserved and may not be used by holder until unlocked.
======================  ==========  =======================================================

Functions
~~~~~~~~~

.. _lockCollateral:

lockCollateral
--------------

A user or a vault locks some amount of collateral.

Specification
.............

*Function Signature*

``lockCollateral(account, amount)``

*Parameters*

* ``account``: The account locking collateral.
* ``amount``: The amount of collateral.

*Events*

* :ref:`lockCollateralEvent`

*Preconditions*

* The account MUST have sufficient free balance.

*Postconditions*

* The account's free balance MUST decrease by ``amount``.
* The account's reserved balance MUST increase by ``amount``.

.. _releaseCollateral:

releaseCollateral
-----------------

When a protocol has completed successfully, we unlock the account's collateral.

Specification
.............

*Function Signature*

``releaseCollateral(account, amount)``

*Parameters*

* ``account``: The account unlocking collateral.
* ``amount``: The amount of collateral.

*Events*

* :ref:`releaseCollateralEvent`

*Preconditions*

* The account MUST have sufficient reserved balance.

*Postconditions*

* The account's reserved balance MUST decrease by ``amount``.
* The account's free balance MUST increase by ``amount``.

.. _slashCollateral:

slashCollateral
-----------------

When a protocol has not completed successfully, the origin account (``sender``) is slashed and the collateral is transferred to another party (``receiver``).

Specification
.............

*Function Signature*

``slashCollateral(sender, receiver, amount)``

*Parameters*

* ``sender``: The sender that to slash.
* ``receiver``: The receiver of the collateral.
* ``amount``: The amount of collateral.

*Events*

* :ref:`slashCollateralEvent`

*Preconditions*

* The sender MUST have sufficient reserved balance.

*Postconditions*

* The sender's reserved balance MUST decrease by ``amount``.
* The receiver's free balance MUST increase by ``amount``.

Events
~~~~~~

.. _lockCollateralEvent:

LockCollateral
--------------

Emit a ``LockCollateral`` event when a sender locks collateral.

*Event Signature*

``LockCollateral(sender, amount)``

*Parameters*

* ``sender``: The sender that provides the collateral.
* ``amount``: The amount of collateral.

*Function*

* :ref:`lockCollateral`

.. _releaseCollateralEvent:

ReleaseCollateral
-----------------

Emit a ``ReleaseCollateral`` event when a sender releases collateral.

*Event Signature*

``ReleaseCollateral(sender, amount)``

*Parameters*

* ``sender``: The sender that initially provided the collateral.
* ``amount``: The amount of collateral.

*Function*

* :ref:`releaseCollateral`

.. _slashCollateralEvent:

SlashCollateral
----------------

Emit a ``SlashCollateral`` event when a sender's collateral is slashed and transferred to the receiver.

*Event Signature*

``SlashCollateral(sender, receiver, amount)``

*Parameters*

* ``sender``: The sender that initially provided the collateral.
* ``receiver``: The receiver of the collateral.
* ``amount``: The amount of collateral.

*Function*

* :ref:`slashCollateral`

Errors
~~~~~~

``ERR_INSUFFICIENT_BALANCE```

* **Message**: "The sender's balance is below the requested amount."
* **Function**: :ref:`lockCollateral` | :ref:`releaseCollateral` | :ref:`slashCollateral`
* **Cause**: the ``sender`` has less collateral stored than the requested ``amount``.
