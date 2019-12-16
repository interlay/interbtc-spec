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

A Requester opens an issue request by providing a small amount of collateral.

Specification
.............

*Function Signature*

``commit(requester, amount, vaults)``

*Parameters*

* ``requester``: The Requester's BTC Parachain account.
* ``amount``: The amount of PolkaBTC to be issued.
* ``vaults``: The BTC Parachain address of the Vault(s) involved in this issue request.

*Returns*

* ``issueRequestId``: A unique hash identifying the issue request. 

*Events*

* ``Commit(requester, amount, vaults, CommitId)``:

*Errors*

* ``ERR_INSUFFICIENT_COLLATERAL``: The user did not provide enough collateral.
* ``ERR_EXCEEDING_VAULT_LIMIT``: The selected vault has not provided collateral to issue the requested ``amount``.
* ``ERR_VAULT_BUFFERED_COLLATERAL_STATE``: The selected vault is below the buffered collateral rate and cannot be used to issue new PolkaBTC.
* ``ERR_VAULT_LIQUIDATION_STATE``: The selected vault is going to be liquidated.

*Substrate* ::

  fn commit(origin, amount: U256, vaults: Vec<AccountId>) -> Result {...}

User Story
..........

.. todo:: Add



Function Sequence
.................

.. todo:: Discuss if a user actualy needs to select a vault. We could alternatively just consider all vaults as a pool. The user just issues without selecting a dedicated vault and we consider the pool of vault collateral when deciding whether or not the issue request can be fullfilled. There is anyway not necessarily a connection between issue and redeem.


1. A Requester prepares the input parameters to the function.
  
    a. ``requester``: The address of the Requester to receive the PolkaBTC.
    b. ``amount``: The Requester decides how much PolkaBTC should be issued.
    c. ``vault``: A Requester picks a vault with enough collateral to open an issue request

2. The Requester calls the ``commit`` function and provides his own address, the amount, and the vault he wants to use. Further, he provides a small collateral to prevent griefing.
3. Checks if the Requester provided enough collateral. If not, throws ``ERR_INSUFFICIENT_COLLATERAL``.
4. Checks if the selected vault has locked enough collateral to cover the ``amount`` of PolkaBTC to be issued.

    a. Query the VaultRegistry and check the ``status`` of the vault. If the vault status is in Buffered Collateral, throw ``ERR_VAULT_BUFFERED_COLLATERAL_STATE``. If the vault status is Liquidation, throw ``ERR_VAULT_LIQUIDATION_STATE``. Else, continue.
    b. Query the VaultRegistry and check the ``committedTokens`` and ``collateral``. Calculate how much free ``collateral`` is available by multiplying the collateral with the ``ExchangeRate`` (from the Oracle) and subtract the ``committedTokens``. If not enough collateral is free, throw ``ERR_EXCEEDING_VAULT_LIMIT``. Else, continue.

4. Generate a ``CommitId`` by hashing a random seed, a nonce, and the address of the Requester.

5. Store a new ``Commit`` struct in the ``IssueRequests`` mapping. The ``CommitId`` refers to the ``Commit``. Fill the ``vault`` with the requested ``vault``, the ``opentime`` with the current block number, the ``collateral`` with the collateral provided by the Requester, ``amount`` with the ``amount`` provided as input, ``requester`` the requester account, and ``btcPublicKey`` the address from which the Requester will send the Bitcoin transaction to a vault.

6. Issue the ``Commit`` event with the ``requester`` account, ``amount``, ``vault``, and ``CommitId``.

7. Return the ``CommitId``. The Requester stores this for future reference and the next steps, locally.

lock
----

The user sends BTC to a vault's address.

Specification
.............

*Function Signature*

``lock(requester, amount, vault, commitId)``

*Parameters*

* ``requester``: The Requester's BTC Parachain account.
* ``amount``: The amount of PolkaBTC to be issued.
* ``vaults``: The BTC Parachain address of the Vault(s) involved in this issue request.
* ``commitId``: the unique hash created during the ``commit`` function,

*Returns*

* ``txId``: A unique hash identifying the Bitcoin transaction.

.. todo:: Do we define the Bitcoin transactions here?

*Bitcoin* ::

  OP_RETURN

User Story
..........


Function Sequence
.................

1. The user 

issue
-----

A Requester completes the issue request by sending a proof of transferring the defined amount of BTC to the vault's address.

Specification
.............

*Function Signature*

``issue(requester, commitId, txId, txBlockHeight, txIndex, merkleProof, rawTx)``

*Parameters*

* ``requester``: the account of the Requester.
* ``commitId``: the unique hash created during the ``commit`` function,
* ``txId``: the hash of the transaction.
* ``txBlockHeight``: block height at which transaction is supposedly included.
* ``txIndex``: index of transaction in the block’s tx Merkle tree.
* ``terkleProof``: Merkle tree path (concatenated LE sha256 hashes).
* ``rawTx``: raw transaction including the transaction inputs and outputs.


*Returns*

* ``True``:

*Events*

* ``Issue(requester, ammount, vault)``:

*Errors*

* ``ERR_COMMIT_ID``:

*Substrate* ::

  fn issue(origin, ) -> Result {...}

User Story
..........


Function Sequence
.................

1. The user prepares the inputs and calls the ``issue`` function.

Events
~~~~~~


Errors
~~~~~~


