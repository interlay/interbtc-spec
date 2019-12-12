.. _issue-protocol:

Issue
=====

Overview
~~~~~~~~

Step-by-step
------------

1. Precondition: a Vault has locked collateral as described in the `Vault registry <vault-registry>`_.
2. A Requester executes the ``commit`` function to open an issue request on the BTC Parachain. The issue request includes the amount of PolkaBTC the Requester wants to have, which Vault(s) the Requester uses, and a small collateral to prevent `griefing <griefing>`_.
3. A Requester sends the equivalent amount of BTC that he wants to issue as PolkaBTC to the Vault on the Bitcoin blockchain with the ``lockBTC`` function. The Requester extracts a transaction inclusion proof of that locking transaction on the Bitcoin blockchain.
4. The Requester executes the ``issue`` function on the BTC Parachain. The issue function requires a reference to the previous issue request and the transaction inclusion proof of the ``lockBTC`` transaction. If the function completes successfully, the Requester receives the requested amount of PolkaBTC into his account.
5. Optional: If the Requester is not able to complete the issue request within the predetermined time frame (``CommitPeriod``), anyone is able to call the ``abort`` function to cancel the issue request.

Data Model
~~~~~~~~~~

.. todo:: We need to handle replay attacks. Idea: include a short unique hash, e.g. the ``CommitId`` and the ``RedeemId`` in the BTC transaction in the ``OP_RETURN`` field. That way, we can check if it is the correct transaction.

.. todo:: The hash creation for ``CommitId`` and ``RedeemId`` must be unique. Proposal: use a combination of Substrate's ``random_seed()`` method together with a ``nonce`` and the ``AccountId`` of a CbA-Requester and CbA-Redeemer. 

.. warning:: Substrate's built in module to generate random data needs 80 blocks to actually generate random data.


Scalars
-------

CommitPeriod
............

The time difference in seconds between a commit request is created and required completion time by a CbA-Requester. The commit period has an upper limit to prevent grieving of vault collateral.

*Substrate*: ``CommitPeriod: Moment;``

Maps
----

IssueRequests
.............

CbA-Requesters create issue requests to issue PolkaBTC. This mapping provides access from a unique hash ``IssueId`` to a ``Commit`` struct. ``<CommitId, Commit>``.

*Substrate*: ``IssueRequests map T::Hash => Commit<T::AccountId, T::Balance>``

Structs
-------

Commit
......

Stores the status and information about a single commit.

==================  ==========  =======================================================	
Parameter           Type        Description                                            
==================  ==========  =======================================================
``vault``           Account     The vault responsible for this commit request.
``opentime``        u256        Timestamp of opening the request.
``collateral``      DOT         Collateral provided by a user.
``amount``          PolkaBTC    Amount of PolkaBTC to be issued.
``receiver``        Account     CbA-Requester account receiving PolkaBTC upon successful issuing.
``sender``          Account     CbA-Requester account receiving the refund of ``collateral``.
``btcPublicKey``    bytes[20]   Base58 encoded Bitcoin public key of the CbA-Requester.  
==================  ==========  =======================================================

*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Commit<AccountId, Balance, Moment> {
        vault: AccountId,
        opentime: Moment,
        collateral: Balance,
        amount: Balance,
        receiver: AccountId,
        sender: AccountId,
        btcPublicKey: Bytes
  }

Functions
~~~~~~~~~

commit
------

A Requester places a small amount of collateral to commit to an issue request.

Specification
.............

*Function Signature*

``commit(requester, amount, vaults)``

*Parameters*

* ``requester``: The Requester account.
* ``amount``: The amount of PolkaBTC to be issued.
* ``vaults``: The Vault(s) involved in this issue request.

*Returns*

* ``IssueRequestId``: A unique hash identifying the issue request. 

*Events*

* ``Commit(requester, amount, vaults)``:

*Errors*

* ````:

*Substrate* ::

  fn commit(origin, amount: U256, vaults: Vec<AccountId>) -> Result {...}

User Story
..........


Function Sequence
.................


Events
~~~~~~


Errors
~~~~~~


