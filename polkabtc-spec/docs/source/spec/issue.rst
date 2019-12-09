.. _issue-protocol:

Issue
=====

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


Events
~~~~~~


Errors
~~~~~~


