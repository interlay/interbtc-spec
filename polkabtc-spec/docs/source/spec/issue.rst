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

.. .. todo:: We need to handle replay attacks. Idea: include a short unique hash, e.g. the ``issueId`` and the ``RedeemId`` in the BTC transaction in the ``OP_RETURN`` field. That way, we can check if it is the correct transaction.

.. .. todo:: The hash creation for ``issueId`` and ``RedeemId`` must be unique. Proposal: use a combination of Substrate's ``random_seed()`` method together with a ``nonce`` and the ``AccountId`` of a CbA-Requester and CbA-Redeemer. 

.. .. warning:: Substrate's built in module to generate random data needs 80 blocks to actually generate random data.


Scalars
-------

CommitPeriod
............

The time difference in number of blocks between a issue request is created and required completion time by a Requester. The commit period has an upper limit to prevent griefing of vault collateral.

*Substrate* ::

  CommitPeriod: T::BlockNumber;

Nonce
.....

A counter that increases with every use.

*Substrate* ::

  Nonce: U256;

Maps
----

IssueRequests
.............

Requesters create issue requests to issue PolkaBTC. This mapping provides access from a unique hash ``IssueId`` to a ``Issue`` struct. ``<IssueId, Issue>``.

*Substrate* ::

  IssueRequests map T::Hash => Issue<T::AccountId, T::BlockNumber, T::Balance>


Structs
-------

Issue
.....

Stores the status and information about a single commit.

==================  ==========  =======================================================	
Parameter           Type        Description                                            
==================  ==========  =======================================================
``vault``           Account     The BTC Parachain address of the Vault responsible for this commit request.
``opentime``        u256        Block height of opening the request.
``collateral``      DOT         Collateral provided by a user.
``amount``          PolkaBTC    Amount of PolkaBTC to be issued.
``requester``        Account     Requester account receiving PolkaBTC upon successful issuing.
``btcPublicKey``    bytes[20]   Base58 encoded Bitcoin public key of the Vault.  
==================  ==========  =======================================================

*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Commit<AccountId, BlockNumber, Balance> {
        vault: AccountId,
        opentime: BlockNumber,
        collateral: Balance,
        amount: Balance,
        requester: AccountId,
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

* ``issueId``: A unique hash identifying the issue request. 

*Events*

* ``Commit(requester, amount, vaults, issueId)``:

*Errors*

* ``ERR_INSUFFICIENT_COLLATERAL``: The user did not provide enough collateral.
* ``ERR_EXCEEDING_VAULT_LIMIT``: The selected vault has not provided collateral to issue the requested ``amount``.
* ``ERR_VAULT_BUFFERED_COLLATERAL_STATE``: The selected vault is below the buffered collateral rate and cannot be used to issue new PolkaBTC.
* ``ERR_VAULT_LIQUIDATION_STATE``: The selected vault is going to be liquidated.

*Substrate* ::

  fn commit(origin, amount: U256, vaults: Vec<AccountId>) -> Result {...}


Function Sequence
.................


.. todo:: Figure out how to safely use the nonce.


1. A Requester prepares the input parameters to the function.
  
    a. ``requester``: The address of the Requester to receive the PolkaBTC.
    b. ``amount``: The Requester decides how much PolkaBTC should be issued.
    c. ``vault``: A Requester picks a vault with enough collateral to open an issue request

2. The Requester calls the ``commit`` function and provides his own address, the amount, and the vault he wants to use. Further, he provides a small collateral to prevent griefing.
3. Checks if the Requester provided enough collateral. If not, throws ``ERR_INSUFFICIENT_COLLATERAL``.
4. Checks if the selected vault has locked enough collateral to cover the ``amount`` of PolkaBTC to be issued.

    a. Query the VaultRegistry and check the ``status`` of the vault. If the vault status is in Buffered Collateral, throw ``ERR_VAULT_BUFFERED_COLLATERAL_STATE``. If the vault status is Liquidation, throw ``ERR_VAULT_LIQUIDATION_STATE``. Else, continue.
    b. Query the VaultRegistry and check the ``committedTokens`` and ``collateral``. Calculate how much free ``collateral`` is available by multiplying the collateral with the ``ExchangeRate`` (from the Oracle) and subtract the ``committedTokens``. If not enough collateral is free, throw ``ERR_EXCEEDING_VAULT_LIMIT``. Else, continue.

4. Generate a ``issueId`` by hashing a random seed, a nonce, and the address of the Requester.

5. Increase the nonce.

6. Store a new ``Issue`` struct in the ``IssueRequests`` mapping. The ``IssueId`` refers to the ``Issue``. Fill the ``vault`` with the requested ``vault``, the ``opentime`` with the current block number, the ``collateral`` with the collateral provided by the Requester, ``amount`` with the ``amount`` provided as input, ``requester`` the requester account, and ``btcPublicKey`` the Bitcoin address of the Vault.

7. Call the VaultRegistry ``occupy`` function with the amount of ``collateral`` that should be reserved for the issue request for a specific ``vault`` identified by its address.

8. Issue the ``Commit`` event with the ``requester`` account, ``amount``, ``vault``, and ``issueId``.

9. Return the ``issueId``. The Requester stores this for future reference and the next steps, locally.

lock
----

The user sends BTC to a vault's address.

Specification
.............

*Function Signature*

``lock(requester, amount, vault, issueId)``

*Parameters*

* ``requester``: The Requester's BTC Parachain account.
* ``amount``: The amount of PolkaBTC to be issued.
* ``vaults``: The BTC Parachain address of the Vault(s) involved in this issue request.
* ``issueId``: the unique hash created during the ``commit`` function,

*Returns*

* ``txId``: A unique hash identifying the Bitcoin transaction.

.. todo:: Do we define the Bitcoin transactions here?

*Bitcoin* ::

  OP_RETURN


Function Sequence
.................

1. The Requester prepares a Bitcoin transaction with the following details:

   a. The input(s) must be spendable from the Requester.
   b. The transaction has at least two outputs with the following conditions:

        1. One output is spendable by the ``btcPublicKey`` of the Vault selected in the ``commit`` function. The output includes the ``amount`` requested in the ``commit`` function in the ``value`` field. This means the number of requested PolkaBTC must be the same amount of transferred BTC (expressed as satoshis).
        2. One output must include a ``OP_RETURN`` with the ``issueId`` received in the ``commit`` function. This output will not be spendable and therefore the ``value`` field should be ``0``.

2. The Requester sends the transaction prepared in step 1 to the Bitcoin network and locally stores the ``txId``, i.e. the unique hash of the transaction.

issue
-----

A Requester completes the issue request by sending a proof of transferring the defined amount of BTC to the vault's address.

Specification
.............

*Function Signature*

``issue(requester, issueId, txId, txBlockHeight, txIndex, merkleProof, rawTx)``

*Parameters*

* ``requester``: the account of the Requester.
* ``issueId``: the unique hash created during the ``commit`` function,
* ``txId``: the hash of the transaction.
* ``txBlockHeight``: block height at which transaction is supposedly included.
* ``txIndex``: index of transaction in the block’s tx Merkle tree.
* ``MerkleProof``: Merkle tree path (concatenated LE sha256 hashes).
* ``rawTx``: raw transaction including the transaction inputs and outputs.


*Returns*

* ``True``:

*Events*

* ``Issue(requester, ammount, vault)``:

*Errors*

* ``ERR_COMMIT_ID_NOT_FOUND``: Throws if the ``issueId`` cannot be found.
* ``ERR_FUNCTION_NOT_VERIFIED``: Throws a generic error if the transaction could not be verified.

*Substrate* ::

  fn issue(origin, issueId: T::Hash, txId: T::Hash, txBlockHeight: U256, txIndex: u64, merkleProof: Bytes, rawTx: Bytes) -> Result {...}


Function Sequence
.................

.. todo:: Insert link to BTC Relay to get Bitcoin data.

.. todo:: What happends if the Vault goes into buffered collateral/liquidation at this point?


1. The Requester prepares the inputs and calls the ``issue`` function.
    
    a. ``requester``: The BTC Parachain address of the requester.
    b. ``issueId``: The unique hash received in the ``commit`` function.
    c. ``txId``: the hash of the Bitcoin transaction to the Vault. With the ``txId`` the Requester can get the remainder of the Bitcoin transaction data including ``txBlockHeight``, ``txIndex``, ``MerkleProof``, and ``rawTx``. See BTC Relay documentation for details.

2. Checks if the ``issueId`` exists. Throws ``ERR_COMMIT_ID_NOT_FOUND`` if not found. Else, continues.
3. Calls the ``verifyTransaction`` function of the BTC Relay with the provided ``txId``, ``txBlockHeight``, ``txIndex``, and ``MerkleProof``. If the function does not return ``True``, the function has either thrown a specific error or the transaction could not be verified. If the function returns ``False``, throw the general ``ERR_TRANSACTION_NOT_VERIFIED`` error. If returns ``True``, continues.
4. Calls the ``parseTransaction`` function of the BTC Relay with the ``txId``, ``rawTx``, the ``amount`` and the ``issueId``. The ``parseTransaction`` function checks that the ``rawTx`` hashes to the ``txId``, includes the correct ``amount``, and hash the ``issueId`` in its ``OP_RETURN``. If the function returns ``False``, throw ``ERR_TRANSACTION_NOT_VERIFIED``. More detailed errors are thrown in the BTC Relay. Else, continues.
5. Check if the function has thrown an error.

    a. If the function has thrown an error, execute ``free`` in the VaultRegistry to release the locked collateral for this issue request for the vault. Return ``False``.
    b. Else, continue.

6. Call the ``mint`` function in the Treasury with the ``amount`` and the Requester's address as the ``receiver``.
7. Issue an ``Issue`` event with the Requester's address, the amount, and the Vault's address.
8. Return ``True``.

Events
~~~~~~



Errors
~~~~~~


