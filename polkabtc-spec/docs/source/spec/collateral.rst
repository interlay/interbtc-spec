.. collateral-module:

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

.. todo:: Do we want to move all the collateral requirements into this module?




