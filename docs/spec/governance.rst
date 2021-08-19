.. _governance:

Governance
==========

Overview
~~~~~~~~

On-chain governance is useful for controlling system parameters, authorizing trusted oracles and upgrading the core protocols. The architecture adopted by the interBTC parachain is modelled on Polkadot, which allows for a **Council** and **Technical Committee** to propose referenda which are voted on by INTR holders.

.. figure:: ../figures/governance.jpeg
    :alt: Governance Architecture


Parameters (Council)
~~~~~~~~~~~~~~~~~~~~


MaxProposals
------------

The maximum number of proposals allowed in the queue.

.. note:: **Default Value**: 100


MaxMembers
----------

The maximum number of participants allowed in the council.

.. note:: **Default Value**: 100


Parameters (Voting)
~~~~~~~~~~~~~~~~~~~


EnactmentPeriod
---------------

The period to wait before any approved change is enforced.

.. note:: **Default Value**: 1 Day


LaunchPeriod
------------

The interval after which to process a new referenda from the queue.

.. note:: **Default Value**: 2 Days


VotingPeriod
------------

The period to allow new votes for a proposal or referenda (**Council**).

.. note:: **Default Value**: 2 Days


FastTrackVotingPeriod
---------------------

The period to allow new votes for a proposal or referenda (**Technical Committee**).

.. note:: **Default Value**: 3 Hours


CooloffPeriod
-------------

The period that a vetoed proposal may not be re-submitted.

.. note:: **Default Value**: 7 Days


MinimumDeposit
--------------

The minimum deposit required for a public proposal.

.. note:: **Default Value**: 1000 INTR



Parameters (Turnout)
~~~~~~~~~~~~~~~~~~~~


ExternalOrigin
--------------

Schedules next referendum with super-majority approval.

.. note:: **Default Value**: Half Council


ExternalMajorityOrigin
----------------------

Schedules next referendum with simple-majority approval.

.. note:: **Default Value**: Half Council


ExternalDefaultOrigin
---------------------

Schedules next referendum with super-majority against.

.. note:: **Default Value**: All Council


FastTrackOrigin
---------------

Schedules ExternalMajority / ExternalDefault vote.

.. note:: **Default Value**: Two Thirds Technical Committee


CancellationOrigin
------------------

Schedules cancellation of a referendum. 

.. note:: **Default Value**: Two Thirds Council
