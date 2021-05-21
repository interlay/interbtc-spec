.. _replace-protocol:

Replace
=======

Overview
~~~~~~~~~

The Replace module allows a vault (*OldVault*) to be replaced by transferring the BTC it is holding locked to another vault (*NewVault*), which provides the necessary DOT collateral. As a result, the DOT collateral of the *OldVault*, corresponding to the amount of replaced BTC, is unlocked. The *OldVault* must thereby provide some amount of collateral to protect against griefing attacks, where the *OldVault* never finalizes the Replace protocol and the *NewVault* hence temporarily locked DOT collateral for nothing.

The *OldVault* is responsible for ensuring that it has sufficient BTC to pay for the transaction fees.

Conceptually, the Replace protocol resembles a SPV atomic cross-chain swap.

Step-by-Step
-------------

1. Precondition: a vault (*OldVault*) has locked DOT collateral in the `Vault Registry <vault-registry>`_ and has issued PolkaBTC tokens, i.e., holds BTC on Bitcoin.

2. *OldVault* submits a replacement request, indicating how much BTC is to be migrated by calling the :ref:`requestReplace` function. 

   * *OldVault* is required to lock some amount of DOT collateral (:ref:`ReplaceGriefingCollateral`) as griefing protection, to prevent *OldVault* from holding *NewVault*'s DOT collateral locked in the BTC Parachain without ever finalizing the redeem protocol (transfer of BTC). 

3. Optional: If an *OldVault* has changed its mind or can't find a *NewVault* to replace it, it can call the :ref:`withdrawReplaceRequest` function to withdraw the request of some amount. For example, if *OldVault* requested a replacement for 10 tokens, and 2 tokens have been accepted by some *NewVault*, then it can withdraw up to 8 tokens from being replaced. 

4. A new candidate vault (*NewVault*), commits to accepting the replacement by locking up the necessary DOT collateral to back the to-be-transferred BTC (according to the ``SecureCollateralThreshold``) by calling the :ref:`acceptReplace` function.. 

   * Note: from the *OldVault*'s perspective a redeem is very similar to an accepted replace. That is, its goal is to get rid of tokens, and it is not important if this is achieved by a user redeeming, or by a vault accepting the replace request. As such, when a user requests a redeem with a vault that has requested a replacement, the *OldVault*'s ``toBeReplacedTokens`` is decreased by the amount of tokens redeemed by the user. The reserved griefing collateral for this replace is then released.

5. Within a pre-defined delay, *OldVault* must release the BTC on Bitcoin to *NewVault*'s BTC address, and submit a valid transaction inclusion proof by calling the :ref:`executeReplace` function (call to ``verifyTransactionInclusion`` in :ref:`btc-relay`). If *OldVault* releases the BTC to *NewVault* correctly and submits the transaction inclusion proof to Replace module on time, *OldVault*'s DOT collateral is released - *NewVault* has now replaced *OldVault*.

   * Note: as with redeems, to prevent *OldVault* from trying to re-use old transactions (or other payments to *NewVaults* on Bitcoin) as fake proofs, we require *OldVault* to include a ``nonce`` in an OP_RETURN output of the transfer transaction on Bitcoin.


6. Optional: If *OldVault* fails to provide the correct transaction inclusion proof on time, the *NewVault*'s ``collateral`` is unlocked and *OldVault*'s ``griefingCollateral`` is sent to the *NewVault* as reimbursement for the opportunity costs of locking up DOT collateral via the :ref:`cancelReplace`. 

Security
--------

- Unique identification of Bitcoin payments: :ref:`op-return`


Vault Registry
--------------

The data access and state changes to the vault registry are documented in :numref:`fig-vault-registry-replace` below.

.. _fig-vault-registry-replace:
.. figure:: ../figures/VaultRegistry-Replace.png
    :alt: vault-registry-replace
    
    The replace module interacts with functions in the vault registry to handle updating token balances of vaults. The green lines indicate an increase, the red lines a decrease.

Fee Model
---------

Following additions are added if the fee model is integrated.

- If a replace request is canceled, the griefing collateral is transferred to the new_vault.
- If a replace request is executed, the griefing collateral is transferred to the old_vault.

Data Model
~~~~~~~~~~

Scalars
-------

ReplaceBtcDustValue
...................

The minimum amount a *newVault* can accept - this is to ensure the *oldVault* is able to make the bitcoin transfer. Furthermore, it puts a limit on the transaction fees that the *oldVault* needs to pay.

ReplacePeriod
.............

The time difference between a replace request is accepted by another vault and the transfer of BTC (and submission of the transaction inclusion proof) by the to-be-replaced Vault. Concretely, this period is the amount by which :ref:`activeBlockCount` is allowed to increase before the redeem is considered to be expired. The replace period has an upper limit to prevent griefing of vault collateral.


Maps
----

ReplaceRequests
...............

Vaults create replace requests if they want to have (a part of) their DOT collateral to be replaced by other Vaults. This mapping provides access from a unique hash ``ReplaceId`` to a ``ReplaceRequest`` struct. ``<ReplaceId, Replace>``.


Structs
-------

Replace
.......

Stores the status and information about a single replace request.

.. tabularcolumns:: |l|l|L|

======================  ==========  =======================================================	
Parameter               Type        Description                                            
======================  ==========  =======================================================
``oldVault``            Account     Account of the vault that is to be replaced.
``newVault``            Account     Account of the new vault, which accepts the replace request.
``amount``              PolkaBTC    Amount of BTC / PolkaBTC to be replaced.
``griefingCollateral``  DOT         Griefing protection collateral locked by *oldVault*.
``collateral``          DOT         DOT collateral locked by the new Vault.
``acceptTime``          u256        Block height at which this replace request was accepted by a new Vault. Serves as start for the countdown until when the old vault must transfer the BTC.
``btcAddress``          bytes[20]   Base58 encoded Bitcoin public key of the new Vault.  
``btcHeight``           bytes[20]   Height of newest bitcoin block in the relay at the time the request is accepted. This is used by the clients upon startup, to determine how many blocks of the bitcoin chain they need to inspect to know if a payment has been made already.
``status``              Enum        Status of the request: Pending, Completed or Cancelled
======================  ==========  =======================================================

.. note:: The ``btcAddress`` parameter is not to be set by the new vault, but is extracted from the ``Vaults`` mapping in ``VaultRegistry`` for the account of the new Vault.  

.. *Substrate*::
  
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

.. _requestReplace:

requestReplace
--------------

An *OldVault* (to-be-replaced Vault) submits a request to be (partially) replaced. If it requests more than it can fulfil (i.e. the sum of ``toBeReplacedTokens`` and ``toBeRedeemedTokens`` exceeds its ``issuedTokens``, then the request amount is reduced such that the sum of ``toBeReplacedTokens`` and ``toBeRedeemedTokens`` is exactly equal to ``issuedTokens``.


Specification
.............

*Function Signature*

``requestReplace(oldVault, btcAmount, griefingCollateral)``

*Parameters*

* ``oldVault``: Account identifier of the vault to be replaced (as tracked in ``Vaults`` in :ref:`vault-registry`).
* ``btcAmount``: Integer amount of BTC / PolkaBTC to be replaced.
* ``griefingCollateral``: collateral locked by the *oldVault* as griefing protection

*Events*

* ``RequestReplace(oldVault, btcAmount, replaceId)``

*Preconditions*

* The function call MUST be signed by *oldVault*.
* The vault MUST be registered
* The vault MUST NOT be banned
* The BTC Parachain status in the :ref:`security` component must be set to ``RUNNING:0``.
* The vault MUST provide sufficient ``griefingCollateral`` such that the ratio of all of its ``toBeReplacedTokens`` and ``replaceCollateral`` is above :ref:`ReplaceGriefingCollateral`.
* The vault MUST request sufficient tokens to be replaced such that its total is above ``ReplaceBtcDustValue``.


*Postconditions*

* The vault's ``toBeReplaceedTokens`` is increased by ``tokenIncrease = min(btcAmount, vault.toBeIssuedTokens - vault.toBeRedeemedTokens)``. 
* An amount of ``griefingCollateral * (tokenIncrease / btcAmount)`` is locked by this transaction.
* The vault's ``replaceCollateral`` is increased by the amount of collateral locked in this transaction.


.. _withdrawReplaceRequest:

withdrawReplaceRequest
-----------------------

The *OldVault* decreases its ``toBeReplacedTokens``.


Specification
.............

*Function Signature*

``withdrawReplaceRequest(oldVault, tokens)``

*Parameters*

* ``oldVault``: Account identifier of the vault withdrawing it's replace request (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``tokens``: The amount of ``to_be_replaced_tokens`` to withdraw.

*Events*

``WithdrawReplaceRequest(oldVault, withdrawnTokens, withdrawnGriefingCollateral)``: emits an event stating that a vault (*oldVault*) has withdrawn some amount of ``toBeReplacedTokens``.

*Preconditions*

* The function call MUST be signed by *oldVault*.
* The vault MUST be registered
* The BTC Parachain status in the :ref:`security` component MUST NOT be set to ``SHUTDOWN: 2``.
* The vault MUST have a non-zero amount of ``toBeReplaceedTokens``.

*Postconditions*

* The vault's ``toBeReplacedTokens`` is decrease by an amount of ``tokenDecrease = min(toBeReplacedTokens, tokens)``
* The vault's ``replaceCollateral`` is decreased by the amount ``releasedCollateral = replaceCollateral * (tokenDecrease / toBeReplacedTokens)``.
* The ``releasedCollateral`` is unlocked.



.. _acceptReplace:

acceptReplace
--------------

A *NewVault* accepts an existing replace request. It can optionally lock additional DOT collateral specifically for this replace. If the replace is cancelled, this amount will be unlocked again.


Specification
.............

*Function Signature*

``acceptReplace(newVault, oldVault, btcAmount, collateral, btcAddress)``

*Parameters*

* ``newVault``: Account identifier of the vault accepting the replace request (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``replaceId``: The identifier of the replace request in ``ReplaceRequests``.
* ``collateral``: DOT collateral provided to match the replace request (i.e., for backing the locked BTC). Can be more than the necessary amount.

*Events*

``AcceptReplace(replaceId, oldVault, newVault, btcAmount, collateral, btcAddress)``: emits an event with data that the *oldVault* needs to execute the replace.

*Preconditions*

* The function call MUST be signed by *newVault*.
* *oldVault* and *newVault* MUST be registered
* *oldVault* MUST NOT be equal to *newVault*
* The BTC Parachain status in the :ref:`security` component MUST NOT be set to ``SHUTDOWN: 2``.
* *newVault*'s free balance MUST be enough to lock ``collateral``
* *newVault* MUST have lock sufficient collateral to remain above the :ref:`SecureCollateralThreshold` after accepting ``btcAmount``.
* The replaced tokens MUST be at least``ReplaceBtcDustValue``.

*Postconditions*

The actual amount of replaced tokens is calculated to be ``consumedTokens = min(oldVault.toBeReplacedTokens, btcAmount)``. The amount of griefingCollateral used is ``consumedGriefingCollateral = oldVault.replaceCollateral * (consumedTokens / oldVault.toBeReplacedTokens)``.


* The *oldVault*'s ``replaceCollateral`` is decreased by ``consumedGriefingCollateral``. 
* The *oldVault*'s ``toBeReplacedTokens`` is decreased by ``consumedTokens``. 
* The *oldVault*'s ``toBeRedeemedTokens`` is increased by ``consumedTokens``. 
* The *newVault*'s ``toBeIssuedTokens`` is increased by ``consumedTokens``. 
* The *newVault* locks additional collateral; its ``backingCollateral`` is increased by ``collateral * (consumedTokens / oldVault.toBeReplacedTokens)``. 
* A new ``ReplaceRequest`` is added to storage. The amount is set to ``consumedTokens``, ``griefingCollateral`` to ``consumedGriefingCollateral``, ``collateral`` to the ``collateral`` argument, ``accept_time`` to the current active block number, ``period`` to the current ``ReplacePeriod``, ``btcAddress`` to the ``btcAddress`` argument, ``btc_height`` to the current height of the btc-relay, and ``status`` to ``pending``.


.. _executeReplace: 

executeReplace
--------------

The to-be-replaced vault finalizes the replace process by submitting a proof that it transferred the correct amount of BTC to the BTC address of the new vault, as specified in the ``ReplaceRequest``. This function calls *verifyAndValidateTransaction* in :ref:`btc-relay`.


Specification
.............

*Function Signature*

``executeReplace(oldVault, replaceId, merkleProof, rawTx)``

*Parameters*

* ``oldVault``: Account identifier of the vault making this call.
* ``replaceId``: The identifier of the replace request in ``ReplaceRequests``.
* ``merkleProof``: Merkle tree path (concatenated LE SHA256 hashes).
* ``rawTx``: Raw Bitcoin transaction including the transaction inputs and outputs.

*Events*

* ``ExecuteReplace(oldVault, newVault, replaceId)``: emits an event stating that the old vault (*oldVault*) has executed the BTC transfer to the new vault (*newVault*), finalizing the ``ReplaceRequest`` request (``requestId``).

*Preconditions*

* The BTC Parachain status in the :ref:`security` component MUST NOT be set to ``SHUTDOWN:2``.
* *oldVault* MUST be registered as a vault
* A pending ``ReplaceRequest`` MUST exist with an id equal to ``replaceId``.
* The request MUST NOT have expired.
* The ``rawTx`` MUST decode to a valid transaction that transfers at least the amount specified in the ``ReplaceRequest`` struct. It MUST be a transaction to the correct address, and provide the expected OP_RETURN, based on the ``ReplaceRequest``.
* The ``merkleProof`` MUST match the ``rawTX``.
* The bitcoin payment MUST have been submitted to the relay chain, and MUST have sufficient confirmations.

*Postconditions*

* :ref:`replaceTokens` has been called, providing the ``oldVault``, ``newVault``, ``replaceRequest.amount``, and ``replaceRequest.collateral`` as arguments. 
* The griefing collateral as specifified in the ``ReplaceRequest`` is unlocked to *oldVault*.
* ``replaceRequest.status`` is set to ``Completed``.

.. _cancelReplace:

cancelReplace
-------------

If a replace request is not executed on time, the replace can be cancelled by the new vault. Since the new vault provided additional collateral in vain, it can claim the old vault's griefing collateral.

Specification
.............

*Function Signature*

``cancelReplace(newVault, replaceId)``

*Parameters*

* ``newVault``: Account identifier of the vault accepting the replace request (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``replaceId``: The identifier of the replace request in ``ReplaceRequests``.


*Events*

* ``CancelReplace(replaceId, newVault, oldVault, slashedCollateral)``: emits an event stating that the old vault (*oldVault*) has not completed the replace request, that the new vault (*newVault*) cancelled the ``ReplaceRequest`` request (``requestId``), and that ``slashedCollateral`` has been slashed from *oldVault* to *newVault*.



*Preconditions*

* The BTC Parachain status in the :ref:`security` component MUST NOT be set to ``SHUTDOWN:2``.
* *oldVault* MUST be registered as a vault
* A pending ``ReplaceRequest`` MUST exist with an id equal to ``replaceId``.
* ``newVault`` MUST be equal to the *newVault* specified in the ``ReplaceRequest``. That is, this function can only be can only be called by the *newVault*.
* The request MUST have expired.

*Postconditions*

* :ref:`cancelReplaceTokens` has been called, providing the ``oldVault``, ``newVault``, ``replaceRequest.amount``, and ``replaceRequest.amount``. 
* If *newVault* is *not* liquidated:
   * the griefing collateral is slashed from the *oldVault* to the new vault's ``backingCollateral``.
   * If unlocking ``replaceRequest.collateral`` does not put the collaterlization rate of the *newVault* below ``SecureCollateralThreshold``, the collateral is unlocked and its ``backingCollateral`` decreases by the same amount.
* If *newVault* *is* liquidated, the griefing collateral is slashed from the *oldVault* to the new vault's free balance.
* ``replaceRequest.status`` is set to ``Cancelled``.


Events
~~~~~~~

RequestReplace
--------------

Emit an event when a replace request is made by an *oldVault*.

*Event Signature*
* ``RequestReplace(oldVault, btcAmount, replaceId)``

*Parameters*

* ``oldVault``: Account identifier of the vault to be replaced (as tracked in ``Vaults`` in :ref:`vault-registry`).
* ``btcAmount``: Integer amount of BTC / PolkaBTC to be replaced.
* ``replaceId``: The unique identified of a replace request.

*Functions*

* :ref:`requestReplace`

WithdrawReplaceRequest
----------------------

Emits an event stating that a vault (*oldVault*) has withdrawn some amount of ``toBeReplacedTokens``.

*Event Signature*

``WithdrawReplaceRequest(oldVault, withdrawnTokens, withdrawnGriefingCollateral)``

*Parameters*

* ``oldVault``: Account identifier of the vault requesting the replace (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``withdrawnTokens``: The amount by which ``toBeReplacedTokens`` has decreased.
* ``withdrawnGriefingCollateral``: The amount of griefing collateral unlocked.

*Functions*

* ref:`withdrawReplaceRequest`


AcceptReplace
-------------

Emits an event stating which vault (*newVault*) has accepted the ``ReplaceRequest`` request (``requestId``), and how much collateral in DOT it provided (``collateral``).

*Event Signature*

``AcceptReplace(replaceId, oldVault, newVault, btcAmount, collateral, btcAddress)``

*Parameters*

* ``replaceId``: The identifier of the replace request in ``ReplaceRequests``.
* ``oldVault``: Account identifier of the vault being replaced (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``newVault``: Account identifier of the vault that accepted the replace request (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``btcAmount``: Amount of tokens the *newVault* just accepted.
* ``collateral``: Amount of collateral the *newVault* locked for this replace.
* ``btcAddress``: The address that *oldVault* should transfer the btc to.

*Functions*

* ref:`acceptReplace`


ExecuteReplace
--------------

Emits an event stating that the old vault (*oldVault*) has executed the BTC transfer to the new vault (*newVault*), finalizing the ``ReplaceRequest`` request (``requestId``).

*Event Signature*

``ExecuteReplace(oldVault, newVault, replaceId)``

*Parameters*

* ``oldVault``: Account identifier of the vault being replaced (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``newVault``: Account identifier of the vault that accepted the replace request (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``replaceId``: The identifier of the replace request in ``ReplaceRequests``.

*Functions*

* ref:`executeReplace`


CancelReplace
-------------

Emits an event stating that the old vault (*oldVault*) has not completed the replace request, that the new vault (*newVault*) cancelled the ``ReplaceRequest`` request (``requestId``), and that ``slashedCollateral`` has been slashed from *oldVault* to *newVault*.

*Event Signature*

``CancelReplace(replaceId, newVault, oldVault, slashedCollateral)``

*Parameters*

* ``replaceId``: The identifier of the replace request in ``ReplaceRequests``.
* ``oldVault``: Account identifier of the vault being replaced (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``newVault``: Account identifier of the vault that accepted the replace request (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``slashedCollateral``: Amount of griefingCollateral slashed to *newVault*.

*Functions*

* ref:`cancelReplace`

Error Codes
~~~~~~~~~~~

``ERR_UNAUTHORIZED``

* **Message**: "Unauthorized: Caller must be *newVault*."
* **Function**: :ref:`cancelReplace`
* **Cause**: The caller of this function is not the associated *newVault*, and hence not authorized to take this action.

``ERR_INSUFFICIENT_COLLATERAL``

* **Message**: "The provided collateral is too low."
* **Function**: :ref:`requestReplace`
* **Cause**: The provided collateral is insufficient to match the amount of tokens requested for replacement. 

``ERR_REPLACE_PERIOD_EXPIRED``

* **Message**: "The replace period expired."
* **Function**: :ref:`executeReplace`
* **Cause**: The time limit as defined by the ``ReplacePeriod`` is not met.

``ERR_REPLACE_PERIOD_NOT_EXPIRED``

* **Message**: "The period to complete the replace request is not yet expired."
* **Function**: :ref:`cancelReplace`
* **Cause**:  A vault tried to cancel a replace before it expired.

``ERR_AMOUNT_BELOW_BTC_DUST_VALUE``

* **Message**: "To be replaced amount is too small."
* **Function**: :ref:`requestReplace`, :ref:`acceptReplace`
* **Cause**:  The vault requests or accepts an insufficient number of tokens.

``ERR_NO_PENDING_REQUEST``

* **Message**: "Could not withdraw to-be-replaced tokens because it was already zero."
* **Function**: :ref:`requestReplace` | :ref:`acceptReplace`
* **Cause**:  The vault requests or accepts an insufficient number of tokens.

``ERR_REPLACE_SELF_NOT_ALLOWED``

* **Message**: "Vaults can not accept replace request created by themselves."
* **Function**: :ref:`acceptReplace`
* **Cause**:  A vault tried to accept a replace that it itself had created.

``ERR_REPLACE_COMPLETED``

* **Message**: "Request is already completed."
* **Function**: :ref:`executeReplace` | :ref:`cancelReplace`
* **Cause**:  A vault tried to operate on a request that already completed.

``ERR_REPLACE_CANCELLED``

* **Message**: "Request is already cancelled."
* **Function**: :ref:`executeReplace` | :ref:`cancelReplace`
* **Cause**:  A vault tried to operate on a request that already cancelled.

``ERR_REPLACE_ID_NOT_FOUND``

* **Message**: "Invalid replace ID"
* **Function**: :ref:`executeReplace` | :ref:`cancelReplace`
* **Cause**:  An invalid replaceID was given - it is not found in the ``ReplaceRequests`` map.

``ERR_VAULT_NOT_FOUND``

* **Message**: "The ``vault`` cannot be found."
* **Function**: :ref:`requestReplace` | :ref:`acceptReplace` | :ref:`cancelReplace`
* **Cause**: The vault was not found in the existing ``Vaults`` list in ``VaultRegistry``.

.. note:: It is possible that functions in this pallet return errors defined in other pallets.
