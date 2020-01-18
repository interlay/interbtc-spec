.. _issue-protocol:

Issue
=====

Overview
~~~~~~~~

The issue module allows as user to create new PolkaBTC tokens. The user needs to request PolkaBTC through the :ref:`requestIssue` function, then send BTC to a Vault, and finally complete the issuing of PolkaBTC by calling the :ref:`executeIssue` function. Below is a high-level step-by-step description of the protocol and a figure explaining the steps.

Step-by-step
------------

1. Precondition: a Vault has locked collateral as described in the `Vault registry <vault-registry>`_.
2. A user executes the ``requestIssue`` function to open an issue request on the BTC Parachain. The issue request includes the amount of PolkaBTC the user wants to have, which Vault the user uses, and a small collateral to prevent `griefing <griefing>`_.
3. A user sends the equivalent amount of BTC that he wants to issue as PolkaBTC to the Vault on the Bitcoin blockchain with the ``lockBTC`` function. The user extracts a transaction inclusion proof of that locking transaction on the Bitcoin blockchain.
4. The user executes the ``executeIssue`` function on the BTC Parachain. The issue function requires a reference to the previous issue request and the transaction inclusion proof of the ``lockBTC`` transaction. If the function completes successfully, the user receives the requested amount of PolkaBTC into his account.
5. Optional: If the user is not able to complete the issue request within the predetermined time frame (``CommitPeriod``), anyone is able to call the ``abort`` function to cancel the issue request.

Data Model
~~~~~~~~~~

.. .. todo:: We need to handle replay attacks. Idea: include a short unique hash, e.g. the ``issueId`` and the ``RedeemId`` in the BTC transaction in the ``OP_RETURN`` field. That way, we can check if it is the correct transaction.

.. .. todo:: The hash creation for ``issueId`` and ``RedeemId`` must be unique. Proposal: use a combination of Substrate's ``random_seed()`` method together with a ``nonce`` and the ``AccountId`` of a CbA-user and CbA-Redeemer. 

.. .. warning:: Substrate's built in module to generate random data needs 80 blocks to actually generate random data.


Scalars
-------

.. todo:: Move this to the new collateral module?


MinimumCollateralUser
.....................

The minimum collateral (DOT) a user needs to provide as griefing protection. 

.. note:: Serves to disincentivize griefing attacks against vault, where users create issue requests, temporarily locking a Vault's collateral, but never execute the issue process.

*Substrate*: ``MinimumCollateralUser: Balance;``



IssuePeriod
............

The time difference in number of blocks between a issue request is created and required completion time by a user. The commit period has an upper limit to prevent griefing of vault collateral.

*Substrate* ::

  IssuePeriod: T::BlockNumber;

Maps
----

IssueRequests
.............

Users create issue requests to issue PolkaBTC. This mapping provides access from a unique hash ``IssueId`` to a ``Issue`` struct. ``<IssueId, Issue>``.

*Substrate* ::

  IssueRequests map T::Hash => Issue<T::AccountId, T::BlockNumber, T::Balance>


Structs
-------

Issue
.....

Stores the status and information about a single issue request.

==================  ==========  =======================================================	
Parameter           Type        Description                                            
==================  ==========  =======================================================
``vault``           Account     The BTC Parachain address of the Vault responsible for this commit request.
``opentime``        u256        Block height of opening the request.
``collateral``      DOT         Collateral provided by a user.
``amount``          PolkaBTC    Amount of PolkaBTC to be issued.
``requester``       Account     User account receiving PolkaBTC upon successful issuing.
``btcAddress``      bytes[20]   Base58 encoded Bitcoin public key of the Vault.  
``completed``       bool        Indicates if the issue has been completed.
==================  ==========  =======================================================

*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Issue<AccountId, BlockNumber, Balance> {
        vault: AccountId,
        opentime: BlockNumber,
        collateral: Balance,
        amount: Balance,
        requester: AccountId,
        btcAddress: H160,
        completed: bool
  }

Functions
~~~~~~~~~

.. _requestIssue:

requestIssue
-----------

A user opens an issue request by providing a small amount of collateral.

Specification
.............

*Function Signature*

``requestIssue(requester, amount, vault)``

*Parameters*

* ``requester``: The user's BTC Parachain account.
* ``amount``: The amount of PolkaBTC to be issued.
* ``vault``: The BTC Parachain address of the Vault involved in this issue request.
* ``collateral``: The collateral amount provided by the user.

*Returns*

* ``issueId``: A unique hash identifying the issue request. 

*Events*

* ``RequestIssue(requester, amount, vault, issueId)``

*Errors*

* ``ERR_INSUFFICIENT_COLLATERAL``: The user did not provide enough collateral.
* ``ERR_VAULT_COLLATERAL_RATIO``: The selected vault is below the collateral safety ratio.

*Substrate* ::

  fn requestIssue(origin, amount: U256, vault: AccountId) -> Result {...}


Function Sequence
.................


1. A user prepares the input parameters to the function.
  
    a. ``requester``: The address of the user to receive the PolkaBTC.
    b. ``amount``: The user decides how much PolkaBTC should be issued.
    c. ``vault``: A user picks a vault with enough collateral to open an issue request
    d. ``collateral``: The user transfers collateral against griefing.

2. The user calls the ``requestIssue`` function and provides his own address, the amount, and the vault he wants to use. Further, he provides a small collateral to prevent griefing.

3. Checks if the user provided enough collateral by checking if the collateral is equal or greater than ``MinimumCollateral``. If not, throws ``ERR_INSUFFICIENT_COLLATERAL``.

4. Call the VaultRegistry ``lockVault`` function with the ``amount`` of tokens to be issue, the ``collateral`` that should be reserved for the issue request, and the ``vault`` identified by its address.

5. Generate an ``issueId`` by hashing a random seed, a nonce from the security module, and the address of the user.

6. Store a new ``Issue`` struct in the ``IssueRequests`` mapping. The ``issueId`` refers to the ``Issue``. Fill the ``vault`` with the requested ``vault``, the ``opentime`` with the current block number, the ``collateral`` with the collateral provided by the user, ``amount`` with the ``amount`` provided as input, ``requester`` the requester account, and ``btcAddress`` the Bitcoin address of the Vault.

7. Issue the ``RequestIssue`` event with the ``requester`` account, ``amount``, ``vault``, and ``issueId``.

8. Return the ``issueId``. The user stores this for future reference and the next steps, locally.


.. lock
.. ----
.. 
.. The user sends BTC to a vault's address.
.. 
.. Specification
.. .............
.. 
.. *Function Signature*
.. 
.. ``lock(requester, amount, vault, issueId)``
.. 
.. *Parameters*
.. 
.. * ``requester``: The user's BTC Parachain account.
.. * ``amount``: The amount of PolkaBTC to be issued.
.. * ``vault``: The BTC Parachain address of the Vault involved in this issue request.
.. * ``issueId``: the unique hash created during the ``requestIssue`` function.
.. 
.. *Returns*
.. 
.. * ``txId``: A unique hash identifying the Bitcoin transaction.
.. 
.. .. todo:: Do we define the Bitcoin transactions here?
.. 
.. *Bitcoin* ::
.. 
..   OP_RETURN
.. 
.. 
.. Function Sequence
.. .................
.. 
.. 1. The user prepares a Bitcoin transaction with the following details:
.. 
..    a. The input(s) must be spendable from the user.
..    b. The transaction has at least two outputs with the following conditions:
.. 
..         1. One output is spendable by the ``btcAddress`` of the Vault selected in the ``requestIssue`` function. The output includes the ``amount`` requested in the ``requestIssue`` function in the ``value`` field. This means the number of requested PolkaBTC must be the same amount of transferred BTC (expressed as satoshis).
..         2. One output must include a ``OP_RETURN`` with the ``issueId`` received in the ``requestIssue`` function. This output will not be spendable and therefore the ``value`` field should be ``0``.
.. 
.. 2. The user sends the transaction prepared in step 1 to the Bitcoin network and locally stores the ``txId``, i.e. the unique hash of the transaction.


.. _executeIssue:

executeIssue
------------

A user completes the issue request by sending a proof of transferring the defined amount of BTC to the vault's address.

Specification
.............

*Function Signature*

``executeIssue(requester, issueId, txId, txBlockHeight, txIndex, merkleProof, rawTx)``

*Parameters*

* ``requester``: the account of the user.
* ``issueId``: the unique hash created during the ``requestIssue`` function,
* ``txId``: The hash of the Bitcoin transaction.
* ``txBlockHeight``: Bitcoin block height at which the transaction is supposedly included.
* ``txIndex``: Index of transaction in the Bitcoin block’s transaction Merkle tree.
* ``MerkleProof``: Merkle tree path (concatenated LE SHA256 hashes).
* ``rawTx``: Raw Bitcoin transaction including the transaction inputs and outputs.


*Returns*

* ``True``: if the transaction can be successfully verified and the function has been called within the time limit.
* ``False``: Otherwise.

*Events*

* ``ExecuteIssue(requester, issueId, amount, vault)``:

*Errors*

* ``ERR_ISSUE_ID_NOT_FOUND``: Throws if the ``issueId`` cannot be found.
* ``ERR_COMMIT_PERIOD_EXPIRED``: Throws if the time limit as defined by the ``CommitPeriod`` is not met.

*Substrate* ::

  fn executeIssue(origin, issueId: T::H256, txId: T::H256, txBlockHeight: U256, txIndex: u64, merkleProof: Bytes, rawTx: Bytes) -> Result {...}


Function Sequence
.................

.. todo:: Insert link to BTC-Relay to get Bitcoin data.

.. todo:: What happens if the Vault goes into buffered collateral/liquidation at this point?


1. The user prepares the inputs and calls the ``executeIssue`` function.
    
    a. ``requester``: The BTC Parachain address of the requester.
    b. ``issueId``: The unique hash received in the ``requestIssue`` function.
    c. ``txId``: the hash of the Bitcoin transaction to the Vault. With the ``txId`` the user can get the remainder of the Bitcoin transaction data including ``txBlockHeight``, ``txIndex``, ``MerkleProof``, and ``rawTx``. See BTC-Relay documentation for details.

2. Checks if the ``issueId`` exists. Throws ``ERR_ISSUE_ID_NOT_FOUND`` if not found. Else, continues.
3. Checks if the current block height minus the ``CommitPeriod`` is smaller than the ``opentime`` specified in the ``Issue`` struct. If this condition is false, throws ``ERR_COMMIT_PERIOD_EXPIRED``. Else, continues.
4. Call *verifyTransactionInclusion* in :ref:`btc-relay`, providing ``txid``, ``txBlockHeight``, ``txIndex``, and ``merkleProof`` as parameters. If this call returns an error, abort and return the received error. 
5. Call *validateTransaction* in :ref:`btc-relay`, providing ``rawTx``, the amount of to-be-issued BTC (``Issue.amount``), the ``vault``'s Bitcoin address (``Issue.btcAddress``), and the ``issueId`` as parameters. If this call returns an error, abort and return the received error. 
6. Check if the function has thrown an error.

    a. If the function has thrown an error, execute ``free`` in the VaultRegistry to release the locked collateral for this issue request for the vault. Return ``False``.
    b. Else, continue.

7. Call the ``mint`` function in the Treasury with the ``amount`` and the user's address as the ``receiver``.
8. Issue an ``Execute   Issue`` event with the user's address, the issueId, the amount, and the Vault's address.
9. Return ``True``.

.. _cancelIssue:

cancelIssue
-----------

If an issue request is not completed on time, the issue request can be cancelled.

Specification
.............

*Function Signature*

``cancelIssue(sender, issueId)``

*Parameters*

* ``sender``: The sender of the cancel transaction.
* ``issueId``: the unique hash of the issue request.

*Returns*

* ``None``: Does not return anything.

*Events*

* ``CancelIssue(sender, issueId)``: Issues an event with the ``issueId`` that is cancelled.

*Errors*

* ``ERR_ISSUE_ID_NOT_FOUND``: Throws if the ``issueId`` cannot be found.
* ``ERR_TIME_NOT_EXPIRED``: Raises an error if the time limit to call ``executeIssue`` has not yet passed.
* ``ERR_ISSUE_COMPLETED``: Raises an error if the issue is already completed.

*Substrate* ::

  fn cancelIssue(origin, issueId) -> Result {...}

Preconditions
.............

* None.


Function Sequence
.................

1. Check if an issue with id ``issueId`` exists. If not, throw ``ERR_ISSUE_ID_NOT_FOUND``. Otherwise, load the issue request ``issue = IssueRequests[issueId]``.

2. Check if the expiry time of the issue request is up, i.e ``issue.opentime + CommitPeriod < now``. If the time is not up, throw ``ERR_TIME_NOT_EXPIRED``.

3. Check if the ``issue.completed`` field is set to true. If yes, throw ``ERR_ISSUE_COMPLETED``.

4. Release the vault's collateral by calling ``releaseVault`` in the VaultRegistry with the ``issue.vault`` and the ``issue.amount``.

5. Transfer the griefing collateral of the user requesting the issue to the vault assigned to this issue request.

6. Issue the ``CancelIssue`` event with the ``issueId``.

7. Return.


Events
~~~~~~

RequestIssue
------------

Emit a ``RequestIssue`` event if a user successfully open a issue request.

*Event Signature*

``RequestIssue(requester, amount, vault, issueId)``

*Parameters*


* ``requester``: The user's BTC Parachain account.
* ``amount``: The amount of PolkaBTC to be issued.
* ``vault``: The BTC Parachain address of the Vault involved in this issue request.
* ``issueId``: A unique hash identifying the issue request. 

*Functions*

* :ref:`requestIssue`

*Substrate* ::

  RequestIssue(AccountId, U256, AccountId, H256);

ExecuteIssue
------------

*Event Signature*

``ExecuteIssue(requester, issueId, amount, vault)``

*Parameters*

* ``requester``: The user's BTC Parachain account.
* ``issueId``: A unique hash identifying the issue request. 
* ``amount``: The amount of PolkaBTC to be issued.
* ``vault``: The BTC Parachain address of the Vault involved in this issue request.

*Functions*

* :ref:`executeIssue`

*Substrate* ::

  ExecuteIssue(AccountId, H256, U256, AccountId);

CancelIssue
-----------

*Event Signature*

``CancelIssue(sender, issueId)``

*Parameters*

* ``sender``: The sender of the cancel transaction.
* ``issueId``: the unique hash of the issue request.

*Functions*

* :ref:`cancelIssue`

*Substrate* ::
  
    CancelIssue(AccountId, H256);

Error Codes
~~~~~~~~~~~

``ERR_INSUFFICIENT_COLLATERAL``

* **Message**: "Provided collateral below limit."
* **Function**: :ref:`requestIssue`
* **Cause**: User provided collateral below the ``MinimumCollateral``.

``ERR_VAULT_COLLATERAL_RATIO``

* **Message**: "The vault collateral rate is below the safety limit ."
* **Function**: :ref:`requestIssue`
* **Cause**: The vault's collateral needs to be greater than the already issued PolkaBTC under consideration of the safety limit. If the vault's collateral ratio falls below the safety rate, this vault cannot issue new tokens.

``ERR_ISSUE_ID_NOT_FOUND``

* **Message**: "Requested issue id not found."
* **Function**: :ref:`executeIssue`
* **Cause**: Issue id not found in the ``IssueRequests`` mapping.

``ERR_COMMIT_PERIOD_EXPIRED``

* **Message**: "Time to issue PolkaBTC expired."
* **Function**: :ref:`executeIssue`
* **Cause**: The user did not complete the issue request within the block time limit defined by the ``CommitPeriod``.

``ERR_TIME_NOT_EXPIRED``

* **Message**: "Time to issue PolkaBTC not yet expired."
* **Function**: :ref:`cancelIssue`
* **Cause**: Raises an error if the time limit to call ``executeIssue`` has not yet passed.


``ERR_ISSUE_COMPLETED``:

* **Message**: "Issue completed and cannot be cancelled."
* **Function**: :ref:`cancelIssue`
* **Cause**: Raises an error if the issue is already completed.



