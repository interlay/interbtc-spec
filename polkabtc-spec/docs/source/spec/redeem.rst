.. _redeem-protocol:

Redeem
======

Overview
~~~~~~~~

The redeem module allows a user to receive BTC on the Bitcoin chain in return for destroying an equivalent amount of PolkaBTC on the BTC Parachain. The process is initiated by a user requesting a redeem procedure by selecting a vault. The vault then needs to send BTC to the user within a given time limit. Next, the vault has to finalize the process by providing a proof to the BTC Parachain that he has send the right amount of BTC to the user. If the vault fails to deliver a valid proof, the user can claim an equivalent amount of DOT from the vault's locked collateral to reimburse him for his loss in BTC.

Step-by-step
------------

1. Precondition: A user owns PolkaBTC.
2. A user locks an amount of PolkaBTC by calling the ``lock`` function. Further, the user selects a vault to execute the redeem request from the list of vaults. The function creates a redeem request with a unique hash.
3. The selected vault listens for the ``Lock`` event redeemd by the user. The vault then proceeds to transfer BTC to the address specified by the user in the ``lock`` function including a unique hash in the ``OP_RETURN`` of one output.
4. The vault executes the ``redeem`` function by providing the Bitcoin transaction from step 3 together with the redeem request identifier within the time limit. If the function completes successfully, the locked PolkaBTC are destroyed and the user received its BTC. If the function is not successful, a user executes step 5.
5. If step 4 completed unsuccessfully, the user calls ``slash`` after the redeem time limit. The user is then refunded with the DOT collateral the vault provided.

Data Model
~~~~~~~~~~

Scalars
-------

RedeemPeriod
............

The time difference in number of blocks between a redeem request is created and required completion time by a vault. The redeem period has an upper limit to ensure the user gets his BTC in time and to potentially punish a vault for inactivity or stealing BTC.

*Substrate* ::

  RedeemPeriod: T::BlockNumber;

Maps
----

RedeemRequests
.............

Users create redeem requests to receive BTC in return for PolkaBTC. This mapping provides access from a unique hash ``redeemId`` to a ``Redeem`` struct. ``<redeemId, Redeem>``.

*Substrate* ::

  RedeemRequests map T::H256 => Redeem<T::AccountId, T::BlockNumber, T::Balance>


Structs
-------

Redeem
......

Stores the status and information about a single redeem request.

==================  ==========  =======================================================	
Parameter           Type        Description                                            
==================  ==========  =======================================================
``vault``           Account     The BTC Parachain address of the Vault responsible for this redeem request.
``opentime``        u256        Block height of opening the request.
``amount``          BTC         Amount of BTC to be redeemed.
``btcAddress``      bytes[20]   Base58 encoded Bitcoin public key of the User.  
``completed``       bool        Indicates if the redeem has been completed.
==================  ==========  =======================================================

*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Redeem<AccountId, BlockNumber, Balance> {
        vault: AccountId,
        opentime: BlockNumber,
        amount: Balance,
        btcAddress: H160,
        completed: bool
  }

.. _requestRedeem:

requestRedeem
--------------

A user requests to start the redeem procedure.

Specification
.............

*Function Signature*

``requestRedeem(redeemer, amount, btcPublicKey, vault)``

*Parameters*

* ``redeemer``: address of the user triggering the redeem.
* ``amount``: the amount of PolkaBTC to destroy and BTC to receive.
* ``btcAddress``: the address to receive BTC.
* ``vault``: the vault selected for the redeem request.

*Returns*

* ``redeemId``: A unique hash identifying the redeem request.

*Events*

* ``RequestRedeem(redeemer, amount, vault, redeemId)``

*Errors*

* ``ERR_AMOUNT_EXCEEDS_USER_BALANCE``: If the user is trying to redeem more BTC than his PolkaBTC balance.
* ``ERR_AMOUNT_EXCEEDS_VAULT_BALANCE``: If the user is trying to redeem from a vault that has less BTC locked than requested for redeem.

*Substrate* ::

  fn requestRedeem(origin, amount: Balance, btcAddress: H160, vault: AccountID) -> Result {...}


Preconditions
.............

* The BTC Parachain status in the :ref:`failure-handling` component must be set to ``RUNNING:0``.


Function Sequence
.................

1. The user call the function with the parameters described above.

2. Checks if the ``amount`` is less or equal to the user's balance in the treasury. Throws ``ERR_AMOUNT_EXCEEDS_USER_BALANCE`` if this check is false.

3. Checks if the ``amount`` is less or equal to the ``committedTokens`` by the selected vault in the VaultRegistry. Throws ``ERR_AMOUNT_EXCEEDS_VAULT_BALANCE`` if this check is false.

4. Generate an ``redeemId`` by hashing a random seed, a nonce from the security module, and the address of the user.

5. Store a new ``Redeem`` struct in the ``RedeemRequests`` mapping. The ``redeemId`` refers to the ``Redeem``. Fill the ``vault`` with the requested ``vault``, the ``opentime`` with the current block number, ``amount`` with the ``amount`` provided as input, ``redeemer`` the redeemer account, and ``btcAddress`` the Bitcoin address of the user.

6. Lock the ``amount`` of the user's PolkaBTC in the Treasury with the ``lock`` function.

7. Send the ``RequestRedeem`` event with the ``redeemer`` account, ``amount``, ``vault``, and ``redeemId``.

8. Return the ``redeemId``. The user stores this for future reference locally.


executeRedeem
-------------

A Vault calls this function after receiving an ``RequestRedeem`` event with his public key. Before calling the function, the Vault transfers the specific amount of BTC to the BTC address given in the original redeem request. The Vault completes the redeem with this function.

Specification
.............

*Function Signature*

``executeRedeem(vault, redeemId, txId, txBlockHeight, txIndex, merkleProof, rawTx)``

*Parameters*

* ``vault``: the vault responsible for executing this redeem request.
* ``redeemId``: the unique hash created during the ``requestRedeem`` function,
* ``txId``: The hash of the Bitcoin transaction.
* ``txBlockHeight``: Bitcoin block height at which the transaction is supposedly included.
* ``txIndex``: Index of transaction in the Bitcoin block’s transaction Merkle tree.
* ``MerkleProof``: Merkle tree path (concatenated LE SHA256 hashes).
* ``rawTx``: Raw Bitcoin transaction including the transaction inputs and outputs.


*Returns*

* ``None``: if the transaction can be successfully verified and the function has been called within the time limit.

*Events*

* ``ExecuteRedeem(redeemer, redeemId, amount, vault)``:

*Errors*

* ``ERR_REDEEM_ID_NOT_FOUND``: Throws if the ``redeemId`` cannot be found.
* ``ERR_COMMIT_PERIOD_EXPIRED``: Throws if the time limit as defined by the ``RedeemPeriod`` is not met.
* ``ERR_UNAUTHORIZED = Unauthorized: Caller must be associated vault``: The caller of this function is not the associated vault, and hence not authorized to take this action.


*Substrate* ::

  fn executeRedeem(origin, redeemId: T::H256, txId: T::H256, txBlockHeight: U256, txIndex: u64, merkleProof: Bytes, rawTx: Bytes) -> Result {...}

Preconditions
.............

* The BTC Parachain status in the :ref:`failure-handling` component must be set to ``RUNNING:0``.

Function Sequence
.................


1. The vault prepares the inputs and calls the ``executeRedeem`` function.
    
    a. ``vault``: The BTC Parachain address of the vault.
    b. ``redeemId``: The unique hash received in the ``requestRedeem`` function.
    c. ``txId``: the hash of the Bitcoin transaction to the user. With the ``txId`` the vault can get the remainder of the Bitcoin transaction data including ``txBlockHeight``, ``txIndex``, ``MerkleProof``, and ``rawTx``. See BTC-Relay documentation for details.

2. Checks if the ``vault`` is the ``redeem.vault``. Throws ``ERR_UNAUTHORIZED`` if called by any account other than the associated ``redeem.vault``.
3. Checks if the ``redeemId`` exists. Throws ``ERR_REDEEM_ID_NOT_FOUND`` if not found.
4. Checks if the current block height minus the ``RedeemPeriod`` is smaller than the ``opentime`` specified in the ``Redeem`` struct. If this condition is false, throws ``ERR_COMMIT_PERIOD_EXPIRED``.

5. Verify the transaction.
    - Call *verifyTransactionInclusion* in :ref:`btc-relay`, providing ``txid``, ``txBlockHeight``, ``txIndex``, and ``merkleProof`` as parameters. If this call returns an error, abort and return the received error. 
    - Call *validateTransaction* in :ref:`btc-relay`, providing ``rawTx``, the amount of to-be-redeemed BTC (``redeem.amount``), the ``redeemer``'s Bitcoin address (``redeem.btcAddress``), and the ``redeemId`` as parameters. If this call returns an error, abort and return the received error. 

6. Burn the ``redeem.amount`` of PolkaBTC for the user with the ``burn`` function in the Treasury.
7. Release the vault's collateral by calling ``releaseVault`` in the VaultRegistry with the ``redeem.vault`` and the ``redeem.amount``.
8. Set the ``redeem.completed`` field to true.
9. Send an ``ExecuteRedeem`` event with the user's address, the redeemId, the amount, and the Vault's address.
10. Return.

.. _cancelRedeem:

cancelRedeem
------------

If a redeem request is not completed on time, the redeem request can be cancelled.

Specification
.............

*Function Signature*

``cancelRedeem(sender, redeemId)``

*Parameters*

* ``redeemer``: The redeemer starting the redeem process.
* ``redeemId``: the unique hash of the redeem request.

*Returns*

* ``None``: Does not return anything.

*Events*

* ``CancelRedeem(redeemer, redeemId)``: Redeems an event with the ``redeemId`` that is cancelled.

*Errors*

* ``ERR_REDEEM_ID_NOT_FOUND``: Throws if the ``redeemId`` cannot be found.
* ``ERR_TIME_NOT_EXPIRED``: Raises an error if the time limit to call ``executeRedeem`` has not yet passed.
* ``ERR_REDEEM_COMPLETED``: Raises an error if the redeem is already completed.

*Substrate* ::

  fn cancelRedeem(origin, redeemId) -> Result {...}

Preconditions
.............

* None.


Function Sequence
.................

1. Check if an redeem with id ``redeemId`` exists. If not, throw ``ERR_REDEEM_ID_NOT_FOUND``. Otherwise, load the redeem request ``redeem = RedeemRequests[redeemId]``.

2. Check if the expiry time of the redeem request is up, i.e ``redeem.opentime + RedeemPeriod < now``. If the time is not up, throw ``ERR_TIME_NOT_EXPIRED``.

3. Check if the ``redeem.completed`` field is set to true. If yes, throw ``ERR_REDEEM_COMPLETED``.

4. Slash the vault by calling ``slashVault`` in the VaultRegistry with the ``redeem.amount`` and the ``redeem.vault`` parameters.

5. Transfer the slashed collateral of the vault to the ``redeem.redeemer``.

6. Send the ``CancelRedeem`` event with the ``redeemId``.

7. Return.

