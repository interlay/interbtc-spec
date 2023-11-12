.. _escrow-protocol:

Escrow
======

Overview
~~~~~~~~

The Escrow module allows users to lockup tokens in exchange for a non-fungible voting asset. The total "power" of this asset decays linearly as the lock approaches expiry - calculated based on the block height. Historic points for the linear function are recorded each time a user's balance is adjusted which allows us to re-construct voting power at a particular point in time.

This architecture was adopted from Curve, see: `Vote-Escrowed CRV (veCRV) <https://curve.readthedocs.io/dao-vecrv.html>`_.

.. note::
    This specification is still a Work-in-Progress (WIP), some information may be outdated or incomplete.

Step-by-step
------------

1. A user may lock any amount of defined governance currency (KINT on Kintsugi, INTR on Interlay) up to a maximum lock period.
2. Both the amount and the unlock time may be increased to improve voting power.
3. The user may unlock their fungible asset after the lock has expired.

Data Model
~~~~~~~~~~

Constants
---------

.. _escrow_constant_span:

Span
....

The locktime is rounded to weeks to limit checkpoint iteration.

.. _escrow_constant_max_period:

MaxPeriod
.........

The maximum period for lockup.

Scalars
-------

.. _escrow_scalar_epoch:

Epoch
.....

The current global epoch for ``PointHistory``.

Maps
----

.. _escrow_map_locked:

Locked
......

Stores the ``amount`` and ``end`` block for an account's lock.

.. _escrow_map_point_history:

PointHistory
............

Stores the global ``bias``, ``slope`` and ``height`` at a particular point in history.

.. _escrow_map_user_point_history:

UserPointHistory
................

Stores the ``bias``, ``slope`` and ``height`` for an account at a particular point in history.

.. _escrow_map_user_point_epoch:

UserPointEpoch
..............

Stores the current epoch for an account.

.. _escrow_map_slope_changes:

SlopeChanges
............

Stores scheduled changes of slopes for ending locks.

Structs
-------

LockedBalance
.............

The ``amount`` and ``end`` height for a locked balance.

.. tabularcolumns:: |l|l|L|

==========  ===========  =======================================================	
Parameter   Type         Description                                            
==========  ===========  =======================================================
``amount``  Balance      The amount deposited to receive vote-escrowed tokens.
``end``     BlockNumber  The end height after which the balance can be unlocked.
==========  ===========  =======================================================

Point
.....

The ``bias``, ``slope`` and ``height`` for our linear function.

.. tabularcolumns:: |l|l|L|

==========  ===========  ====================================================	
Parameter   Type         Description                                         
==========  ===========  ====================================================
``bias``    Balance      The bias for the linear function.
``slope``   Balance      The slope for the linear function.
``height``  BlockNumber  The current block height when this point was stored.
==========  ===========  ====================================================

External Functions
~~~~~~~~~~~~~~~~~~

.. _escrow_function_create_lock:

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

* :ref:`escrow_event_deposit`

*Preconditions*

* The function call MUST be signed by ``who``.
* The ``amount`` MUST be non-zero.
* The account's ``old_locked.amount`` MUST be non-zero.
* The ``unlock_height`` MUST be greater than ``now``.
* The ``unlock_height`` MUST NOT be greater than ``now + MaxPeriod``.

*Postconditions*

* The account's ``LockedBalance`` MUST be set as follows:

    * ``new_locked.amount``: MUST be the ``amount``.
    * ``new_locked.end``: MUST be the ``unlock_height``.

* The ``UserPointEpoch`` MUST increase by one.
* A new ``Point`` MUST be recorded at this epoch:

    * ``slope = amount / max_period``
    * ``bias = slope * (unlock_height - now)``
    * ``height = now``

* Function :ref:`reward_function_withdraw_stake` MUST complete successfully using the account's total stake.
* Function :ref:`reward_function_deposit_stake` MUST complete successfully using the current balance (:ref:`escrow_function_balance_at`).

.. _escrow_function_increase_amount:

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

* :ref:`escrow_event_deposit`

*Preconditions*

* The function call MUST be signed by ``who``.
* The ``amount`` MUST be non-zero.
* The account's ``old_locked.amount`` MUST be non-zero.
* The account's ``old_locked.end`` MUST be greater than ``now``.

*Postconditions*

* The account's ``LockedBalance`` MUST be set as follows:

    * ``new_locked.amount``: MUST be ``old_locked.amount + amount``.
    * ``new_locked.end``: MUST be the ``old_locked.end``.

* The ``UserPointEpoch`` MUST increase by one.
* A new ``Point`` MUST be recorded at this epoch:

    * ``slope = new_locked.amount / max_period``
    * ``bias = slope * (new_locked.end - now)``
    * ``height = now``

.. _escrow-function-extend-unlock-height:

extend_unlock_height
--------------------

Push back the expiry on a pre-existing lock to retain voting power.

Specification
.............

*Function Signature*

``extend_unlock_height(who, unlock_height)``

*Parameters*

* ``who``: The user's address.
* ``unlock_height``: The new expiry deadline.

*Events*

* :ref:`escrow_event_deposit`

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

* The ``UserPointEpoch`` MUST increase by one.
* A new ``Point`` MUST be recorded at this epoch:

    * ``slope = new_locked.amount / max_period``
    * ``bias = slope * (new_locked.end - now)``
    * ``height = now``

.. _escrow_function_withdraw:

withdraw
--------

Remove the lock on an account to allow access to the account's funds.

Specification
.............

*Function Signature*

``withdraw(who)``

*Parameters*

* ``who``: The user's address.

*Events*

* :ref:`escrow_event_withdraw`

*Preconditions*

* The function call MUST be signed by ``who``.
* The account's ``old_locked.amount`` MUST be non-zero.
* The current height (``now``) MUST be greater than or equal to ``old_locked.end``.

*Postconditions*

* The account's ``LockedBalance`` MUST be removed.
* Function :ref:`reward_function_withdraw_stake` MUST complete successfully using the account's total stake.


Internal Functions
~~~~~~~~~~~~~~~~~~

.. _escrow_function_balance_at:

balance_at
----------

Using the ``Point``, we can calculate the current voting power (``balance``) as follows:

    ``balance = point.bias - (point.slope * (height - point.height))``

Specification
.............

*Function Signature*

``balance_at(who, height)``

*Parameters*

* ``who``: The user's address.
* ``height``: The future height.

*Preconditions*

* The ``height`` MUST be ``>= point.height``.


Events
~~~~~~

.. _escrow_event_deposit:

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

* :ref:`escrow_function_create_lock`

.. _escrow_event_withdraw:

Withdraw
--------

Emit an event if a user withdrew previously locked tokens.

*Event Signature*

``Withdraw(who, amount)``

*Parameters*

* ``who``: The user's account identifier.
* ``amount``: The amount unlocked.

*Functions*

* :ref:`escrow_function_withdraw`
