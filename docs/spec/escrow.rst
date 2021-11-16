.. _escrow-protocol:

Escrow
======

Overview
~~~~~~~~

The Escrow module allows users to lockup tokens in exchange for a non-fungible voting asset. The total "power" of this asset decays linearly as the lock approaches expiry - calculated based on the block height. Historic points for the linear function are recorded each time a user's balance is adjusted which allows us to re-construct voting power at a particular point in time.

This architecture was adopted from Curve, see: `Vote-Escrowed CRV (veCRV) <https://curve.readthedocs.io/dao-vecrv.html>`_.

Step-by-step
------------

1. A user may lock any amount of some currency up to a maximum lock period.
2. Both the amount and the unlock time may be increased to improve voting power.
3. The user may unlock their fungible asset after the lock has expired.

Data Model
~~~~~~~~~~

Constants
---------

.. _span:

Span
....

Used to round heights.

.. _maxPeriod:

MaxPeriod
.........

The maximum period for lockup.

Scalars
-------

.. _escrow-scalar-epoch:

Epoch
.....

The current global epoch for ``PointHistory``.

Maps
----

.. _escrow-map-locked:

Locked
......

Stores the ``amount`` and ``end`` block for the account's lock.

.. _escrow-map-point-history:

PointHistory
............

Stores the global ``bias``, ``slope`` and ``ts`` at a particular point in history,

.. _escrow-map-user-point-history:

UserPointHistory
................

Stores the ``bias``, ``slope`` and ``ts`` for an account at a particular point in history,

.. _escrow-map-user-point-epoch:

UserPointEpoch
..............

Stores the current epoch for an account.

.. _escrow-map-slope-changes:

SlopeChanges
............

Stores scheduled changes of slopes for ending locks.

Structs
-------

LockedBalance
.............

The ``amount`` and ``end`` height for a locked balance.

.. tabularcolumns:: |l|L|

==============  ============  ========================================================	
Parameter       Type          Description                                            
==============  ============  ========================================================
``amount``      Balance       The amount deposited to receive vote-escrowed tokens.
``end``         BlockNumber   The end height after which the balance can be unlocked.
==============  ============  ========================================================

Point
.....

The ``bias``, ``slope`` and ``ts`` for our linear function.

.. tabularcolumns:: |l|L|

==============  ============  ========================================================	
Parameter       Type          Description                                            
==============  ============  ========================================================
``bias``        Balance       The bias for the linear function.
``slope``       Balance       The slope for the linear function.
``ts``          BlockNumber   The current block height when this point was stored.
==============  ============  ========================================================

Functions
~~~~~~~~~

.. _escrow-function-create-lock:

create_lock
-----------

Create a lock on the account's balance to expire in the future.

Specification
.............

*Function Signature*

``create_lock(who, amount, unlock_height)``

*Parameters*

* ``who``: The user's address.
* ``amount``: The amount to be locked.
* ``unlock_height``: The height to lock until.

*Events*

* :ref:`escrow-event-deposit`

*Preconditions*

* The function call MUST be signed by ``who``.
* The ``amount`` MUST be non-zero.
* The account ``who`` MUST NOT already have locked balance.
* The ``unlock_height`` MUST be greater than ``now``.
* The ``unlock_height`` MUST NOT be greater than ``now + MaxPeriod``.

*Postconditions*

* The account's ``LockedBalance`` MUST be set as follows:

    * ``new_locked.amount``: MUST be the ``amount``.
    * ``new_locked.end``: MUST be the ``unlock_height``.

.. _escrow-function-increase-amount:

increase_amount
---------------

Deposit additional tokens for a pre-existing lock to improve voting power.

Specification
.............

*Function Signature*

``increase_amount(who, amount)``

*Parameters*

* ``who``: The user's address.
* ``amount``: The amount to be locked.

*Events*

* :ref:`escrow-event-deposit`

*Preconditions*

* The function call MUST be signed by ``who``.
* The ``amount`` MUST be non-zero.
* The account's ``old_locked.amount`` MUST be non-zero.
* The account's ``old_locked.end`` MUST be greater than ``now``.

*Postconditions*

* The account's ``LockedBalance`` MUST be set as follows:

    * ``new_locked.amount``: MUST be ``old_locked.amount + amount``.
    * ``new_locked.end``: MUST be the ``old_locked.end``.

.. _escrow-function-increase-unlock-height:

increase_unlock_height
----------------------

Push back the expiry on a pre-existing lock to retain voting power.

Specification
.............

*Function Signature*

``increase_unlock_height(who, unlock_height)``

*Parameters*

* ``who``: The user's address.
* ``unlock_height``: The new expiry deadline.

*Events*

* :ref:`escrow-event-deposit`

*Preconditions*

* The function call MUST be signed by ``who``.
* The ``amount`` MUST be non-zero.
* The account's ``old_locked.amount`` MUST be non-zero.
* The account's ``old_locked.end`` MUST be greater than ``now``.
* The ``unlock_height`` MUST be greater than ``old_locked.end``.
* The ``unlock_height`` MUST NOT be greater than ``now + MaxPeriod``.

*Postconditions*

* The account's ``LockedBalance`` MUST be set as follows:

    * ``new_locked.amount``: MUST be ``old_locked.amount``.
    * ``new_locked.end``: MUST be the ``unlock_height``.

.. _escrow-function-withdraw:

increase_withdraw
-----------------

Remove the lock on an account.

Specification
.............

*Function Signature*

``withdraw(who)``

*Parameters*

* ``who``: The user's address.

*Events*

* :ref:`escrow-event-withdraw`

*Preconditions*

* The function call MUST be signed by ``who``.
* The account's ``old_locked.amount`` MUST be non-zero.
* The current height (``now``) MUST be greater than or equal to ``old_locked.end``.

*Postconditions*

* The account's ``LockedBalance`` MUST be removed.

Events
~~~~~~

.. _escrow-event-deposit:

Deposit
-------

Emit an event if a user successfully deposited tokens or increased the lock time.

*Event Signature*

``Deposit(who, amount, unlock_height)``

*Parameters*

* ``who``: The user's account identifier.
* ``amount``: The amount locked.
* ``unlock_height``: The height to unlock after.

*Functions*

* :ref:`escrow-function-create-lock`

.. _escrow-event-withdraw:

Withdraw
--------

Emit an event if a user withdrew previously locked tokens.

*Event Signature*

``Withdraw(who, amount,)``

*Parameters*

* ``who``: The user's account identifier.
* ``amount``: The amount unlocked.

*Functions*

* :ref:`escrow-function-withdraw`
