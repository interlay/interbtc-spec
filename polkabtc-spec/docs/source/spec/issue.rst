.. _issue-protocol:

Issue
=====

Overview
~~~~~~~~

Step-by-step
------------

1. Precondition: a Vault has locked collateral as described in the `Vault registry <vault-registry>`_.
2. A user executes the ``commit`` function to open an issue request on the BTC Parachain. The issue request includes the amount of PolkaBTC the user wants to have, which Vault(s) the user uses, and a small collateral to prevent `griefing <griefing>`_.
3. A user sends the equivalent amount of BTC that he wants to issue as PolkaBTC to the Vault on the Bitcoin blockchain with the ``lockBTC`` function. The user extracts a transaction inclusion proof of that locking transaction on the Bitcoin blockchain.
4. The user executes the ``issue`` function on the BTC Parachain. The issue function requires a reference to the previous issue request and the transaction inclusion proof of the ``lockBTC`` transaction. If the function completes successfully, the user receives the requested amount of PolkaBTC into his account.
5. Optional: If the user is not able to complete the issue request within the predetermined time frame (``CommitPeriod``), anyone is able to call the ``abort`` function to cancel the issue request.

Data Model
~~~~~~~~~~

.. .. todo:: We need to handle replay attacks. Idea: include a short unique hash, e.g. the ``issueId`` and the ``RedeemId`` in the BTC transaction in the ``OP_RETURN`` field. That way, we can check if it is the correct transaction.

.. .. todo:: The hash creation for ``issueId`` and ``RedeemId`` must be unique. Proposal: use a combination of Substrate's ``random_seed()`` method together with a ``nonce`` and the ``AccountId`` of a CbA-user and CbA-Redeemer. 

.. .. warning:: Substrate's built in module to generate random data needs 80 blocks to actually generate random data.


Scalars
-------

MinimumCollateralUser
.....................

The minimum collateral (DOT) a user needs to provide as griefing protection. 

.. note:: Serves to disincentivize griefing attacks against vaults, where users create issue requests, temporarily locking a Vault's collateral, but never execute the issue process.

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
``requester``        Account     user account receiving PolkaBTC upon successful issuing.
``btcPublicKey``    bytes[20]   Base58 encoded Bitcoin public key of the Vault.  
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
        btcPublicKey: Bytes,
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

``requestIssue(requester, amount, vaults)``

*Parameters*

* ``requester``: The user's BTC Parachain account.
* ``amount``: The amount of PolkaBTC to be issued.
* ``vaults``: The BTC Parachain address of the Vault involved in this issue request.

*Returns*

* ``issueId``: A unique hash identifying the issue request. 

*Events*

* ``CommitIssue(requester, amount, vaults, issueId)``:

*Errors*

* ``ERR_INSUFFICIENT_COLLATERAL``: The user did not provide enough collateral.
* ``ERR_EXCEEDING_VAULT_LIMIT``: The selected vault has not provided collateral to issue the requested ``amount``.
* ``ERR_VAULT_COLLATERAL_RATIO``: The selected vault is below the collateral safety ratio.

*Substrate* ::

  fn requestIssue(origin, amount: U256, vaults: Vec<AccountId>) -> Result {...}


Function Sequence
.................


1. A user prepares the input parameters to the function.
  
    a. ``requester``: The address of the user to receive the PolkaBTC.
    b. ``amount``: The user decides how much PolkaBTC should be issued.
    c. ``vault``: A user picks a vault with enough collateral to open an issue request

2. The user calls the ``requestIssue`` function and provides his own address, the amount, and the vault he wants to use. Further, he provides a small collateral to prevent griefing.
3. Checks if the user provided enough collateral by checking if the collateral is equal or greater than ``MinimumCollateral``. If not, throws ``ERR_INSUFFICIENT_COLLATERAL``.
4. Checks if the selected vault has locked enough collateral to cover the ``amount`` of PolkaBTC to be issued.

    a. Query the VaultRegistry and check the ``status`` of the vault. If the vault's collateral state is below the safety limit, throw ``ERR_VAULT_COLLATERAL_RATIO``. Else, continue.
    b. Query the VaultRegistry and check the ``committedTokens`` and ``collateral``. Calculate how much free ``collateral`` is available by multiplying the collateral with the ``ExchangeRate`` (from the Oracle) and subtract the ``committedTokens``. If not enough collateral is free, throw ``ERR_EXCEEDING_VAULT_LIMIT``. Else, continue.

4. Generate a ``issueId`` by hashing a random seed, a nonce from the security module, and the address of the user.

5. Store a new ``Issue`` struct in the ``IssueRequests`` mapping. The ``IssueId`` refers to the ``Issue``. Fill the ``vault`` with the requested ``vault``, the ``opentime`` with the current block number, the ``collateral`` with the collateral provided by the user, ``amount`` with the ``amount`` provided as input, ``requester`` the requester account, and ``btcPublicKey`` the Bitcoin address of the Vault.

7. Call the VaultRegistry ``occupyCollateral`` function with the amount of ``collateral`` that should be reserved for the issue request for a specific ``vault`` identified by its address.

8. Issue the ``CommitIssue`` event with the ``requester`` account, ``amount``, ``vault``, and ``issueId``.

9. Return the ``issueId``. The user stores this for future reference and the next steps, locally.


.. todo:: Remove this and make a note at the end. 
   
   
lock
----

The user sends BTC to a vault's address.

Specification
.............

*Function Signature*

``lock(requester, amount, vault, issueId)``

*Parameters*

* ``requester``: The user's BTC Parachain account.
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

1. The user prepares a Bitcoin transaction with the following details:

   a. The input(s) must be spendable from the user.
   b. The transaction has at least two outputs with the following conditions:

        1. One output is spendable by the ``btcPublicKey`` of the Vault selected in the ``commit`` function. The output includes the ``amount`` requested in the ``commit`` function in the ``value`` field. This means the number of requested PolkaBTC must be the same amount of transferred BTC (expressed as satoshis).
        2. One output must include a ``OP_RETURN`` with the ``issueId`` received in the ``commit`` function. This output will not be spendable and therefore the ``value`` field should be ``0``.

2. The user sends the transaction prepared in step 1 to the Bitcoin network and locally stores the ``txId``, i.e. the unique hash of the transaction.


.. _executeIssue:

executeIssue
------------

A user completes the issue request by sending a proof of transferring the defined amount of BTC to the vault's address.

Specification
.............

*Function Signature*

``issue(requester, issueId, txId, txBlockHeight, txIndex, merkleProof, rawTx)``

*Parameters*

* ``requester``: the account of the user.
* ``issueId``: the unique hash created during the ``commit`` function,
* ``txId``: The hash of the Bitcoin transaction.
* ``txBlockHeight``: Bitcoin block height at which the transaction is supposedly included.
* ``txIndex``: Index of transaction in the Bitcoin block’s transaction Merkle tree.
* ``MerkleProof``: Merkle tree path (concatenated LE SHA256 hashes).
* ``rawTx``: Raw Bitcoin transaction including the transaction inputs and outputs.


*Returns*

* ``True``: if the transaction can be successfully verified and the function has been called within the time limit.
* ``False``: Otherwise.

*Events*

* ``Issue(requester, ammount, vault)``:

*Errors*

* ``ERR_ISSUE_ID_NOT_FOUND``: Throws if the ``issueId`` cannot be found.
* ``ERR_COMMIT_PERIOD_EXPIRED``: Throws if the time limit as defined by the ``CommitPeriod`` is not met.
* ``ERR_TRANSACTION_NOT_VERIFIED``: Throws a generic error if the transaction could not be verified.

*Substrate* ::

  fn issue(origin, issueId: T::Hash, txId: T::Hash, txBlockHeight: U256, txIndex: u64, merkleProof: Bytes, rawTx: Bytes) -> Result {...}


Function Sequence
.................

.. todo:: Insert link to BTC-Relay to get Bitcoin data.

.. todo:: What happens if the Vault goes into buffered collateral/liquidation at this point?


1. The user prepares the inputs and calls the ``issue`` function.
    
    a. ``requester``: The BTC Parachain address of the requester.
    b. ``issueId``: The unique hash received in the ``commit`` function.
    c. ``txId``: the hash of the Bitcoin transaction to the Vault. With the ``txId`` the user can get the remainder of the Bitcoin transaction data including ``txBlockHeight``, ``txIndex``, ``MerkleProof``, and ``rawTx``. See BTC-Relay documentation for details.

2. Checks if the ``issueId`` exists. Throws ``ERR_ISSUE_ID_NOT_FOUND`` if not found. Else, continues.
3. Checks if the current block height minus the ``CommitPeriod`` is smaller than the ``opentime`` specified in the ``Issue`` struct. If this condition is false, throws ``ERR_COMMIT_PERIOD_EXPIRED``. Else, continues.
4. Calls the ``verifyTransactionInclusion`` function of the BTC-Relay with the provided ``txId``, ``txBlockHeight``, ``txIndex``, and ``MerkleProof``. If the function does not return ``True``, the function has either thrown a specific error or the transaction could not be verified. If the function returns ``False``, throw the general ``ERR_TRANSACTION_NOT_VERIFIED`` error. If returns ``True``, continues.
5. Calls the ``parseTransaction`` function of the BTC-Relay with the ``txId``, ``rawTx``, the ``amount`` and the ``issueId``. The ``parseTransaction`` function checks that the ``rawTx`` hashes to the ``txId``, includes the correct ``amount``, and hash the ``issueId`` in its ``OP_RETURN``. If the function returns ``False``, throw ``ERR_TRANSACTION_NOT_VERIFIED``. More detailed errors are thrown in the BTC-Relay. Else, continues.
6. Check if the function has thrown an error.

    a. If the function has thrown an error, execute ``free`` in the VaultRegistry to release the locked collateral for this issue request for the vault. Return ``False``.
    b. Else, continue.

7. Call the ``mint`` function in the Treasury with the ``amount`` and the user's address as the ``receiver``.
8. Issue an ``Issue`` event with the user's address, the amount, and the Vault's address.
9. Return ``True``.

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

* ``CancelIssue``: Issues an event with the ``issueId`` that is cancelled.

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

4. Release the vault's collateral through the collateral module.

5. Transfer the griefing collateral of the user requesting the issue to the vault assigned to this issue request.

6. Return.


Events
~~~~~~

RequestIssue
------------

Emit a ``RequestIssue`` event if a user successfully open a issue request.

*Event Signature*

``RequestIssue(requester, amount, vault, issueId)``:

*Parameters*


* ``requester``: The user's BTC Parachain account.
* ``amount``: The amount of PolkaBTC to be issued.
* ``vault``: The BTC Parachain address of the Vault involved in this issue request.
* ``issueId``: A unique hash identifying the issue request. 

*Functions*

* :ref:`fun_commit`

*Substrate* ::

  RequestIssue(AccountId, U256, AccountId, H256);

ExecuteIssue
------------

*Event Signature*

``ExecuteIssue(requester, ammount, vault)``:

*Parameters*

* ``requester``: The user's BTC Parachain account.
* ``amount``: The amount of PolkaBTC to be issued.
* ``vault``: The BTC Parachain address of the Vault involved in this issue request.

*Functions*

* :ref:`fun_issue`

*Substrate* ::

  ExecuteIssue(AccountId, U256, AccountId);

Error Codes
~~~~~~~~~~~

``ERR_INSUFFICIENT_COLLATERAL``

* **Message**: "Provided collateral below limit."
* **Function**: :ref:`fun_commit`
* **Cause**: User provided collateral below the ``MinimumCollateral``.



``ERR_EXCEEDING_VAULT_LIMIT``

* **Message**: "Issue request exceeds vault collateral limit."
* **Function**: :ref:`fun_commit`
* **Cause**: The collateral provided by the vault combined with the exchange rate forms an upper limit on how much PolkaBTC can be issued. The requested amount exceeds this limit.




``ERR_VAULT_COLLATERAL_RATIO``

* **Message**: "The vault collateral rate is below the safety limit ."
* **Function**: :ref:`fun_commit`
* **Cause**: The vault's collateral needs to be greater than the already issued PolkaBTC under consideration of the safety limit. If the vault's collateral ratio falls below the safety rate, this vault cannot issue new tokens.

``ERR_ISSUE_ID_NOT_FOUND``

* **Message**: "Requested issue id not found."
* **Function**: :ref:`fun_issue`
* **Cause**: Issue id not found in the ``IssueRequests`` mapping.

``ERR_COMMIT_PERIOD_EXPIRED``

* **Message**: "Time to issue PolkaBTC expired."
* **Function**: :ref:`fun_issue`
* **Cause**: The user did not complete the issue request within the block time limit defined by the ``CommitPeriod``.

``ERR_TRANSACTION_NOT_VERIFIED``

* **Message**: "Transaction could not be verified. More information in the stack trace."
* **Function**: :ref:`fun_issue` 
* **Cause**: The Bitcoin transaction could not be verified in the BTC-Relay module.







