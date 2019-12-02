Failure Handling Methods
========================

The BTC-Relay provides additional methods for failure handling, e.g. in case an attack on the Parachain or Bitcoin itself is detected. 
**Please first see** `Failure Modes: Halting and Recovery <security_performance/security.html#security-parameter-k>`_ for an explanation of how BTC-Relay can handle and recover from failures.

Failure handling methods calls are **restricted**, i.e., can only be called by pre-determined roles.
We differentiate between:

* **Staked Relayers** - collateralized Parachain participants, whose main role it is to Bitcoin full nodes and check that:
    
    1. Transactional data is available for submitted Bitcoin block headers (``NO_DATA: 0`` code)
    2. Submitted blocks are valid under Bitcoin's consensus rules  (``INVALID: 1`` code).

 If one of the above failures is detected, staked relayers can (*TODO: together or individually?*) halt BTC-Relay, providing information about the cause. 

* **Governance Mechanism** - Parachain governance mechanism, voting on critical changes to the architecture or unexpected failures, e.g. hard forks or detected 51% attacks (if a fork exceeds the specified security parameter *k*, see `Security Parameter k <security_performance/security.html#security-parameter-k>`_.). A manual intervention can be indicated via the ``UNEXPECTED: 2`` halting code. 

For an overview of the data structures used for failure handling, please see the `Failure Handling section in the Data Model specification </spec/data-model.html#failure-handling>`_. 
