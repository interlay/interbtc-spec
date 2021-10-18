.. _governance:

Governance
==========

Overview
~~~~~~~~

On-chain governance is useful for controlling system parameters, authorizing trusted oracles and upgrading the core protocols. The architecture adopted by interBTC is modelled on Polkadot, which allows for a **Council** and **Technical Committee** to propose referenda which are voted on by holders of the native governance token.

.. figure:: ../figures/spec/governance.jpeg
    :alt: Governance Architecture


Terminology
~~~~~~~~~~~

- **Referenda** describe system updates and are actively voted on by the community.
- **Motions** are council-led proposals to launch external referenda.
- **Public Proposals** are community-supported proposals to launch referenda.

Processes
~~~~~~~~~

Council
-------

1. Council motion to trigger next external referendum
2. Council votes on motion
3. Council closes motion on success or failure
4. New referenda are started every ``LaunchPeriod``
5. Community can vote on referenda for the ``VotingPeriod``
6. Votes are tallied after ``VotingPeriod`` expires
7. System update enacted after ``EnactmentPeriod``
8. Token voters can unlock balance after ``end + EnactmentPeriod * conviction``

Technical Committee
-------------------

1. Council votes on motion as above
2. Technical Committee may fast track before ``LaunchPeriod``
3. Community can vote on referenda for the ``FastTrackVotingPeriod``

Treasury
--------

1. User makes spending proposal
2. Council votes on motion to approve or reject
3. Approved funds are transferred to recipient

Parameters
~~~~~~~~~~

.. Democracy Pallet

**EnactmentPeriod**

The period to wait before any approved change is enforced.

**LaunchPeriod**

The interval after which to start a new referenda from the queue.

**VotingPeriod**

The period to allow new votes for a referenda.

**MinimumDeposit**

The minimum deposit required for a public proposal.

**ExternalOrigin**

Used to schedule a super-majority-required external referendum.

**ExternalMajorityOrigin**

Used to schedule a majority-carries external referendum.

**ExternalDefaultOrigin**

Used to schedule a negative-turnout-bias (default-carries) external referendum.

**FastTrackOrigin**

Used to fast-track an external majority-carries referendum.

**InstantOrigin**

Used to fast-track an external majority-carries referendum.

**InstantAllowed**

Whether the ``InstantOrigin`` can be used to table referenda with a much shorter voting period.

**FastTrackVotingPeriod**

The period to allow new votes for a fast-tracked referendum.

**CancellationOrigin**

Used to cancel any active referendum. 

**BlacklistOrigin**

Used to permanently blacklist a proposal - preventing it from being proposed again.

**CancelProposalOrigin**

Used to cancel public proposals, before they are tabled.

**VetoOrigin**

Used to veto council proposals, before they are tabled.

**CooloffPeriod**

The period that a vetoed proposal may not be re-submitted.

**MaxProposals**

The maximum number of public proposals allowed in the queue.

.. Election Pallet

**CandidacyBond**

Deposit required to submit candidacy.

**DesiredMembers**

The number of representatives to elect to the **Council**.

.. Council Pallet

**MaxMembers**

The maximum number of participants allowed in the council.





