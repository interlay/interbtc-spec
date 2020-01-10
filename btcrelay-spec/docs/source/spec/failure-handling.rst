.. _failure-handling:

Failure Handling
========================

The BTC-Relay provides additional methods for failure handling, e.g. in case an attack on the Parachain or Bitcoin itself is detected. 
**Please first see** `Failure Modes: Halting and Recovery <security_performance/security.html#security-parameter-k>`_ for an explanation of how BTC-Relay can handle and recover from failures.


Failure Modes Overview
----------------------

BTC-Relay can enter into different failure modes, depending on the occured error.
See figure below. 


.. figure:: ../figures/failureModes.png
    :alt: State machine showing BTC-Relay failure modes

    State machine showing the operational and failure modes of BTC-Relay, and how to recover from or flag failures.

Roles
-----

Failure handling methods calls are **restricted**, i.e., can only be called by pre-determined roles.
We differentiate between:

* **Staked Relayers** - collateralized Parachain participants, whose main role it is to Bitcoin full nodes and check that:
    
    1. Transactional data is available for submitted Bitcoin block headers (``NO_DATA: 0`` code)
    2. Submitted blocks are valid under Bitcoin's consensus rules  (``INVALID: 1`` code).

 If one of the above failures is detected, staked relayers can (*TODO: together or individually?*) halt BTC-Relay, providing information about the cause. 

* **Governance Mechanism** - Parachain governance mechanism, voting on critical changes to the architecture or unexpected failures, e.g. hard forks or detected 51% attacks (if a fork exceeds the specified security parameter *k*, see `Security Parameter k <security_performance/security.html#security-parameter-k>`_.). A manual intervention can be indicated via the ``UNEXPECTED: 2`` halting code. 

For an overview of the data structures used for failure handling, please see the `Failure Handling section in the Data Model specification </spec/data-model.html#failure-handling>`_. 



.. _statusUpdate:

statusUpdate
------------

The ``statusUpdate`` function updates the status of BTC-Relay, e.g. restricting operation or recovering from a failure. 


Specification
~~~~~~~~~~~~~

*Function Signature*

``statusUpdate(update)``

*Parameters*

* ``update``: StatusUpdate struct specifying the type and reason for the status change.


*Returns*

* ``True``: if the block header passes all checks.
* ``False`` (or throws exception): otherwise.

*Errors*

* (Currently not in use) ``ERR_INVALID_STATUS_UPDATE`` = "Requested status update is not allowed.": raise an exception when a status update is requested, which is not allowed. 

*Events*

* ``StatusUpdate(newStatus, block, errorCode, msg)`` - emits an event indicating the status change, with ``newStatus`` being the new ``StatusCode``, ``block`` is the block hash of the block which caused the status change, ``errorCode`` the ``ErrorCode`` specifying the reason for the status change, and ``msg`` the detailed message provided by the function caller. 

*Substrate*

::

  fn statusUpdate(origin, update: StatusUpdate) -> Result {...}


User Story
~~~~~~~~~~
This function is called by Staked Relayers and the Parachain's Governance Mechanism to indicate (possible) failures of BTC-Relay, or to recover from them. 

See the BTC-Relay `State Machine </spec/failure-handling.html#id2>`_ for more details.

Use Cases
~~~~~~~~~
**Verification of Transaction Inclusion**:
To be able to verify that a transaction is included in the Bitcoin blockchain, the corresponding block at the specified ``txBlockHeight`` must be first submitted, verified and stored in the BTC-Relay via ``verifyBlockHeader``. 



Function Sequence
~~~~~~~~~~~~~~~~~

1. Set ``Status``  to ``update.statusCode`` 
2. Emit ``StatusUpdate(update.statusCode, update.block, update.reason, update.msg)`` event 
