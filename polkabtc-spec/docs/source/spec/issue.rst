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

lockCollateral
--------------

The Vault locks an amount of collateral as a security against stealing the Bitcoin locked with it. The Vault can take on issue requests depending on the collateral it provides and under consideration of the ``SecureOperationLimit``.
The maximum amount of PolkaBTC a Vault is able to support during the issue process is based on the following equation:
:math:`\text{max(PolkaBTC)} = \text{collateral} * \text{ExchangeRate} / \text{SecureOperationLimit}`.

.. note:: As an example, assume we use ``DOT`` as collateral, we issue ``PolkaBTC`` and lock ``BTC`` on the Bitcoin side. Let's assume the ``BTC``/``DOT`` exchange rate is ``80``, i.e. one has to pay 80 ``DOT`` to receive 1 ``BTC``. Further, the ``SecureOperationLimit`` is 200%, i.e. a Vault has to provide two-times the amount of collateral to back an issue request. Now let's say the Vault deposits 400 ``DOT`` as collateral. Then this Vault can back at most 2.5 PolkaBTC as: :math:`400 * (1/80) / 2 = 2.5`.

The details of the collateral limits are motivated in the `security specification <security>`_.

Specification
.............

*Function Signature*

``lockCollateral(vault, collateral)``

*Parameters*

* ``vault``: The account of the vault locking collateral.
* ``collateral``: The backing currency used for the collateral.

*Returns*

* ``True``: If the locking has completed successfully.
* ``False``: Otherwise.

*Events*

* ``LockCollateral(vault, collateral, totalCollateral)``: issue an event stating how much new and total collateral a vault has locked.

*Errors*

* ``ERR_INSUFFICIENT_FUNDS``: If a vault has insufficient funds to complete the transaction.
* ``ERR_MIN_AMOUNT``: The amount of to-be-locked collateral needs to be above a minimum amount.
  
*Substrate* ::

  fn lockCollateral(origin, amount: Balance) -> Result {...}

User Story
..........



Function Sequence
.................


Events
~~~~~~


Errors
~~~~~~


