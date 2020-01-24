.. _replace-protocol:

Replace
=======

Overview
~~~~~~~~~

The Replace module allows a Vault (*OldVault*) be replaced by transferring the BTC it is holding locked to another Vault, which provides the necessary DOT collateral. As a result, the DOT collateral of the *OldVault*, corresponding to the amount of replaced BTC, is unlocked. The *OldVault* must thereby provide some amount of collateral to protect against griefing attacks, where the *OldVault* never finalizes the Replace protocol and the *NewVault* hence temporarily locked DOT collateral for nothing.

Conceptual-wise, the Replace protocol resembles a SPV atomic cross-chain swap.

Step-by-Step
-------------

1. Precondition: a Vault (*OldVault*) has locked DOT collateral in the `Vault Registry <vault-registry>`_ and has issued PolkaBTC tokens, i.e., holds BTC on Bitcoin.

2. *OldVault* submits a replacement request, indicating how much BTC is to be migrated. 

   * *OldVault* is required to lock some amount of DOT collateral (``ReplaceGriefingCollateral``) as griefing protection, to prevent *OldVault* from holding *NewVault*'s DOT collateral locked in the BTC Parachain without ever finalizing the redeem protocol (transfer of BTC). 

3. A new candidate Vault (*NewVault*), commits to executing the replacement by locking up the necessary DOT collateral to back the to-be-transferred BTC (according to the ``SecureCollateralRate``). 

4. Within a pre-defined delay, *OldVault* must release the BTC on Bitcoin to *NewVault*'s BTC address, and submit a valid transaction inclusion proof (call to ``verifyTransactionInclusion`` in :ref:`btc-relay`).

  * Note: to prevent *OldVault* from trying to re-use old transactions (or other payments to *NewVaults* on Bitcoin) as fake proofs, we require *OldVault* to include a ``nonce`` in an OP_RETURN output of the transfer transaction on Bitcoin.

5a. If *OldVault* releases the BTC to *NewVault* correctly and submits the transaction inclusion proof to Replace module on time, *OldVault*'s DOT collateral is released - *NewVault* has now replaced *OldVault*.

5b. If *OldVault* fails to provide the correct transaction inclusion proof on time, the *NewVault*'s ``collateral`` is unlocked and *OldVault*'s ``griefingCollateral`` is sent to the *NewVault* as reimbursement for the opportunity costs of locking up DOT collateral. 


Data Model
~~~~~~~~~~~

Scalars
-------

ReplaceGriefingCollateral
.....................................

The minimum collateral (DOT) a Vault requesting a replacement needs to provide as griefing protection. 

.. note:: Requiring a Vault to add DOT collateral for executing replace may be a problem for Vaults which trigger this process due to low collateralization rates. We can potentially slash some of the Vault's existing collateral instead - this will result in reducing the collateralization rate and move the Vault closer to liquidation.

*Substrate*::

  ReplaceGriefingCollateral: Balance;



ReplacePeriod
...............

The time difference in number of blocks between a replace request is accepted by another Vault and the transfer of BTC (and submission of the transaction inclusion proof) by the to-be-replaced Vault. The replace period has an upper limit to prevent griefing of Vault collateral.

*Substrate* ::

  ReplacePeriod: T::BlockNumber;

Nonce
.....

A counter that increases with every new replace request.

*Substrate* ::

  Nonce: U256;

Maps
----

ReplaceRequests
................

Vaults create replace requests if they want to have (a part of) their DOT collateral to be replaced by other Vaults. This mapping provides access from a unique hash ``ReplaceID`` to a ``ReplaceRequest`` struct. ``<ReplaceID, Replace>``.

*Substrate* ::

  ReplaceRequests map T::H256 => Replace<T::AccountId, T::BlockNumber, T::Balance>


Structs
-------

Replace
........

Stores the status and information about a single replace request.

.. tabularcolumns:: |l|l|L|

======================  ==========  =======================================================	
Parameter               Type        Description                                            
======================  ==========  =======================================================
``oldVault``            Account     BTC Parachain account of the Vault that is to be replaced.
``opentime``            u256        Block height of opening the request.
``amount``              PolkaBTC    Amount of BTC / PolkaBTC to be replaced.
``griefingCollateral``  DOT         Griefing protection collateral locked by ``oldVault``.
``newVault``            Account     Account of the new Vault, which accepts the replace request.
``collateral``          DOT         DOT collateral locked by the new Vault.
``acceptTime``          u256        Block height at which this replace request was accepted by a new Vault. Serves as start for the countdown until when the old Vault must transfer the BTC.
``btcAddress``          bytes[20]   Base58 encoded Bitcoin public key of the new Vault.  
====================== ==========  =======================================================

.. note:: The ``btcAddress`` parameter is not to be set the the new Vault, but is extracted from the ``Vaults`` mapping in ``VaultRegistry`` for the account of the new Vault.  

*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Commit<AccountId, BlockNumber, Balance, H160>  {
        oldVault: AccountId,
        opentime: BlockNumber,
        amount: Balance,
        griefingCollateral: Balance,
        newVault: AccountId,
        collateral: Balance,
        acceptTime: BlockNumber,
        btcAddress: H160
  }

Functions
~~~~~~~~~


requestReplace
--------------

An *OldVault* (to-be-replaced Vault) submits a request to be (partially) replaced. 


Specification
.............

*Function Signature*

``requestReplace(vault, btcAmount, timeout, collateral)``

*Parameters*

* ``oldVault``: Account identifier of the Vault to be replaced (as tracked in ``Vaults`` in :ref:`vault-registry`).
* ``btcAmount``: Integer amount of BTC / PolkaBTC to be replaced.
* ``timeout``: Time in blocks after which this request expires.
* ``collateral``: collateral locked by the ``vault`` as griefing protection

.. todo:: Handle Griefing collateral (how do we check that a transaction correctly transferred DOT to the Parachain?)

*Returns*

* ``replaceID``: A unique hash identifying the replace request. 

*Events*

* ``ReplaceRequested(oldVault, btcAmount, timeout, replaceId)``:

*Errors*


* ``ERR_MIN_AMOUNT``: The remaining DOT collateral (converted from the requested BTC replacement value given the current exchange rate) would be below the ``MinimumCollateralVault`` as defined in ``VaultRegistry``.
* ``ERR_UNAUTHORIZED = Unauthorized: Caller must be associated Vault``: The caller of this function is not the associated Vault, and hence not authorized to take this action.

*Substrate* ::

  fn requestReplace(origin, amount: U256, timeout: BlockNumber) -> Result {...}


.. todo:: Check how to attach DOT value to transactions.

Preconditions
...............

* The BTC Parachain status in the :ref:`failure-handling` component must be set to ``RUNNING:0``.

Function Sequence
.................

1. Check that caller of the function is indeed the to-be-replaced Vault. Return ``ERR_UNAUTHORIZED`` error if this check fails.

2. Retrieve the ``Vault`` as per the ``oldVault`` parameter from ``Vaults`` in the ``VaultRegistry``.

3. Check that the requested ``btcAmount`` is lower than ``Vault.committedTokens``.

  a. If ``btcAmount > Vault.committedTokens`` set ``btcAmount = Vault.committedTokens`` (i.e., the request is for the entire BTC holdings of the Vault).

4. If the request is not for the entire BTC holdings, check that the remaining DOT collateral of the Vault is higher than ``MinimumCollateralVault`` as defined in ``VaultRegistry``. Return ``ERR_MIN_AMOUNT`` error if this check fails.

5. Check that the provided DOT value is at least ``ReplaceGriefingCollateral``

.. todo:: Lock ``ReplaceGriefingCollateral``

6. Generate a ``replaceId`` by hashing a random seed, a nonce, and the address of the Requester.

7. Create new ``ReplaceRequest`` entry:

   * ``Replace.oldVault = vault``,
   * ``Replace.opentime`` = current time on Parachain,
   * ``Replace.amount = amount``.
   
8. Emit ``ReplaceRequested(vault, btcAmount, timeout, replaceId)`` event.  



withdrawReplaceRequest
-----------------------

The *OldVault* withdraws an existing ReplaceRequest that is made.


Specification
.............

*Function Signature*

``withdrawReplaceRequest(oldVault, replaceId)``

*Parameters*

* ``oldVault``: Account identifier of the Vault withdrawing it's replace request (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``repalceId``: The identifier of the replace request in ``ReplaceRequests``.

*Events*

* ``WithdrawReplaceRequest(oldVault, replaceId)``: emits an event stating that a Vault (``oldVault``) has withdrawn an existing replace request (``requestId``).

*Errors*


* ``ERR_INVALID_REPLACE_ID =  No ReplaceRequest with given identifier found``: The provided ``replaceId`` was not found in ``ReplaceRequests``.
* ``ERR_UNAUTHORIZED = Unauthorized: Caller must be associated Vault``: The caller of this function is not the associated Vault, and hence not authorized to take this action.
* ``ERR_CANCEL_ACCEPTED_REQUEST = Cannot cancel the ReplaceRequest as it was already accepted by a Vault``: The ``ReplaceRequest`` was already accepted by another Vault and can hence no longer be withdrawn.

*Substrate* ::

  fn WithdrawReplaceRequest(origin, replaceId: H256) -> Result {...}

Preconditions
...............

The ReplaceRequest must have not yet been accepted by another Vault.


Function Sequence
..................

1. Retrieve the ``ReplaceRequest`` as per the ``replaceId`` parameter from ``Vaults`` in the ``VaultRegistry``. Return ``ERR_INVALID_REPLACE_ID`` error if no such ``ReplaceRequest`` was found.

2. Check that caller of the function is indeed the to-be-replaced Vault as specified in the ``ReplaceRequest``. Return ``ERR_UNAUTHORIZED`` error if this check fails.

3. Check that the ``ReplaceRequest`` was not yet accepted by another Vault. Return ``ERR_CANCEL_ACCEPTED_REQUEST`` error if this check fails.

4. Transfer the ``ReplaceGriefingCollateral`` associated with this ``ReplaceRequests`` to the ``oldVault``.

.. todo:: Unlock ``ReplaceGriefingCollateral``

5. Remove the ``ReplaceRequest`` from ``ReplaceRequests``.

6. Emit a ``WithdrawReplaceRequest(oldVault, replaceId)`` event.
 

acceptReplace
--------------

A *NewVault* accepts an existing replace request, locking the necessary DOT collateral.


Specification
.............

*Function Signature*

``acceptReplace(newVault, replaceId, collateral)``

*Parameters*

* ``newVault``: Account identifier of the Vault accepting the replace request (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``repalceId``: The identifier of the replace request in ``ReplaceRequests``.
* ``collateral``: DOT collateral provided to match the replace request. Can be more than the necessary amount.

*Events*

* ``AcceptReplace(newVault, replaceId, collateral)``: emits an event stating which Vault (``newVault``) has accepted the ``ReplaceRequest`` request (``requestId``), and how much collateral in DOT it provided (``collateral``).

*Errors*


* ``ERR_INVALID_REPLACE_ID =  No ReplaceRequest with given identifier found``: The provided ``replaceId`` was not found in ``ReplaceRequests``.
* ``ERR_INSUFFICIENT_COLLATERAL``: The provided collateral is insufficient to match the replace request. 
* ``ERR_VAULT_NOT_FOUND``: The caller of the function was not found in the existing ``Vaults`` list in ``VaultRegistry``.

*Substrate* ::

  fn acceptReplace(origin, replaceId: H256, collateral: Balance) -> Result {...}

Preconditions
...............

The BTC Parachain status in the :ref:`failure-handling` component must be set to ``RUNNING:0``.


Function Sequence
..................


1. Retrieve the ``ReplaceRequest`` as per the ``replaceId`` parameter from  ``ReplaceRequests``. Return ``ERR_INVALID_REPLACE_ID`` error if no such ``ReplaceRequest`` was found.

2. Retrieve the ``Vault`` as per the ``newVault`` parameter from ``Vaults`` in the ``VaultRegistry``. Return``ERR_VAULT_NOT_FOUND`` error if no such Vault can be found.

3. Check that the provided ``collateral`` exceeds the necessary amount, i.e., ``collateral >= SecureCollateralRate * Replace.btcAmount``. Return``ERR_INSUFFICIENT_COLLATERAL`` error if this check fails.

4. Update the ``ReplaceRequest`` entry:

  * ``Replace.newVault = newVault``,
  * ``Replace. acceptTime`` = current Parachain time, 
  * ``Replace.btcAddress = btcAddress`` (new Vault's BTC address),
  * ``Replace.collateral = collateral`` (DOT collateral locked by new Vault).

5. Emit a ``AcceptReplace(newVault, replaceId, collateral)`` event.


executeReplace
--------------

The to-be-replaced Vault finalizes the replace process by submitting a proof that it transferred the correct amount of BTC to the BTC address of the new Vault, as specified in the ``ReplaceRequest``.
This function calls *verifyTransactionInclusion* in :ref:`btc-relay`, proving a transaction inclusion proof (``txid``, ``txBlockHeight``, ``txIndex``, and ``merkleProof``) as input. 


Specification
.............

*Function Signature*

``executeReplace(newVault, replaceId, txId, txBlockHeight, txIndex, merkleProof, rawTx)``

*Parameters*

* ``newVault``: Account identifier of the Vault accepting the replace request (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``repalceId``: The identifier of the replace request in ``ReplaceRequests``.
* ``txId``: The hash of the Bitcoin transaction.
* ``txBlockHeight``: Bitcoin block height at which the transaction is supposedly included.
* ``txIndex``: Index of transaction in the Bitcoin block’s transaction Merkle tree.
* ``MerkleProof``: Merkle tree path (concatenated LE SHA256 hashes).
* ``rawTx``: Raw Bitcoin transaction including the transaction inputs and outputs.

*Events*

* ``ExecuteReplace(oldVault, newVault, replaceId)``: emits an event stating that the old Vault (``oldVault``) has executed the BTC transfer to the new Vault (``newVault``), finalizing the ``ReplaceRequest`` request (``requestId``).

*Errors*


* ``ERR_INVALID_REPLACE_ID =  No ReplaceRequest with given identifier found``: The provided ``replaceId`` was not found in ``ReplaceRequests``.
* ``ERR_VAULT_NOT_FOUND = No Vault with given Account identifier found``: The caller of the function was not found in the existing ``Vaults`` list in ``VaultRegistry``.
* ``ERR_PERIOD_EXPIRED = Replace request expired``: 
* See errors returned by *verifyTransactionInclusion* and *validateTransaction* in :ref:`btc-relay`.


*Substrate* ::

  fn executeReplace(origin, replaceId: H256, collateral: Balance) -> Result {...}

Preconditions
...............

* The BTC Parachain status in the :ref:`failure-handling` component must be set to ``RUNNING:0``.
* The to-be-replaced Vault transferred the correct amount of BTC to the BTC address of the new Vault on Bitcoin, and has generated a transaction inclusion proof. 

Function Sequence
..................

1. Retrieve the ``ReplaceRequest`` as per the ``replaceId`` parameter from ``Vaults`` in the ``VaultRegistry``. Return ``ERR_INVALID_REPLACE_ID`` error if no such ``ReplaceRequest`` request was found.

2. Check that the current Parachain block height minus the ``ReplacePeriod`` is smaller than the ``opentime`` of the ``ReplaceRequest``. 

3. Retrieve the ``Vault`` as per the ``newVault`` parameter from ``Vaults`` in the ``VaultRegistry``. Return ``ERR_VAULT_NOT_FOUND`` error if no such Vault can be found.

4. Call *verifyTransactionInclusion* in :ref:`btc-relay`, providing ``txid``, ``txBlockHeight``, ``txIndex``, and ``merkleProof`` as parameters. If this call returns an error, abort and return the received error. 

5. Call *validateTransaction* in :ref:`btc-relay`, providing ``rawTx``, the amount of to-be-replaced BTC (``Replace.amount``), the ``newVault``'s Bitcoin address (``Vault.btcAddress``), and the ``replaceId`` as parameters. If this call returns an error, abort and return the received error. 

6. Update 

TODO: update VaultRegistry, release oldVault's collateral, emit event, remove ReplaceRequest


.. note:: It can be the case that the to-be-replaced *OldVault* controls a significant numbers of Bitcoin UTXOs with user funds, making it impossible to execute the migration of funds to the *NewVault* within a single Bitcoin transaction. As a result, it may be necessary to "merge" these UTXOs using multiple "merge transactions" on Bitcoin, i.e., transactions which takes as input multiple UTXOs controlled by the *OldVault* and create a single UTXO controlled (again) by the *OldVault*. Once the UTXOs produced by "merge transactions" can be merged by a single, final transaction, the *OldVault* moves the funds to the *NewVault*. (An alternative is to allow the *OldVault* to submit multiple transaction inclusion proofs when calling ``executeReplace``, although this significantly increases the complexity of transaction parsing on the BTC Parachain side).




cancelReplace
--------------

..todo:: TODO

Specification
.............

*Function Signature*

``cancelReplace(newVault, replaceId)``

*Parameters*

* ``newVault``: Account identifier of the Vault accepting the replace request (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``repalceId``: The identifier of the replace request in ``ReplaceRequests``.


*Events*

* ``CancelReplace(newVault, replaceId)``: emits an event stating that the old Vault (``oldVault``) has executed the BTC transfer to the new Vault (``newVault``), finalizing the ``ReplaceRequest`` request (``requestId``).

*Errors*


* ``ERR_INVALID_REPLACE_ID =  No ReplaceRequest with given identifier found``: The provided ``replaceId`` was not found in ``ReplaceRequests``.
* ``ERR_VAULT_NOT_FOUND = No Vault with given Account identifier found``: The caller of the function was not found in the existing ``Vaults`` list in ``VaultRegistry``.
* ``ERR_PERIOD_EXPIRED = Replace request expired``: 
* See errors returned by *verifyTransactionInclusion* and *validateTransaction* in :ref:`btc-relay`.


*Substrate* ::

  fn cancelReplace(origin, replaceId: H256) -> Result {...}

Preconditions
...............


Function Sequence
..................


