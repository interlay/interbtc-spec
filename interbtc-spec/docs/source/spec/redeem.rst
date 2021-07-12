.. _redeem-protocol:

Redeem
======

Overview
~~~~~~~~

The redeem module allows a user to receive BTC on the Bitcoin chain in return for destroying an equivalent amount of interbtc on the BTC Parachain. The process is initiated by a user requesting a redeem with a vault. The vault then needs to send BTC to the user within a given time limit. Next, the vault has to finalize the process by providing a proof to the BTC Parachain that he has send the right amount of BTC to the user. If the vault fails to deliver a valid proof within the time limit, the user can claim an equivalent amount of DOT from the vault's locked collateral to reimburse him for his loss in BTC.

Moreover, as part of the liquidation procedure, users are able to directly exchange interbtc for DOT. To this end, a user is able to execute a special liquidation redeem if one or multiple vaults have been liquidated.

Step-by-step
------------

1. Precondition: A user owns interbtc.
2. A user locks an amount of interbtc by calling the :ref:`requestRedeem` function. In this function call, the user selects a vault to execute the redeem request from the list of vaults. The function creates a redeem request with a unique hash.
3. The selected vault listens for the ``RequestRedeem`` event emitted by the user. The vault then proceeds to transfer BTC to the address specified by the user in the :ref:`requestRedeem` function including a unique hash in the ``OP_RETURN`` of one output.
4. The vault executes the :ref:`executeRedeem` function by providing the Bitcoin transaction from step 3 together with the redeem request identifier within the time limit. If the function completes successfully, the locked interbtc are destroyed and the user received its BTC.
5. Optional: If the user could not receive BTC within the given time (as required in step 4), the user calls :ref:`cancelRedeem` after the redeem time limit. The user can choose either to reimburse, or to retry. In case of reimbursement, the user transfer ownership of the tokens to the vault, but receives collateral in exchange. In case of retry, the user gets back its tokens. In either case, the user is given some part of the vault's collateral as compensation for the inconvenience. In addition, some amount (depending on the vault's SLA) of collateral is transferred from the vault to the fee pool.

   a. Optional: If during a :ref:`cancelRedeem` the user selects reimbursement, and as a result the vault becomes undercollateralized, then vault does not receive the user's tokens - they are burned, and the vault's ``issuedTokens`` decreases. When, at some later point, it gets sufficient colalteral, it can call :ref:`mintTokensForReimbursedRedeem` to get the tokens. 

Security
--------

- Unique identification of Bitcoin payments: :ref:`op-return`

Vault Registry
--------------

The data access and state changes to the vault registry are documented in :numref:`fig-vault-registry-redeem` below.

.. _fig-vault-registry-redeem:
.. figure:: ../figures/VaultRegistry-Redeem.png
    :alt: vault-registry-redeem

    The redeem module interacts through three different functions with the vault registry. The green arrow indicate an increase, the red arrows a decrease.

Fee Model
---------

When the user makes a redeem request for a certain amount, it will actually not receive that amount of BTC. This is because there are two types of fees subtracted. First, in order to be able to pay the bitcoin transaction cost, the vault is given a budget to spend on on the bitcoin inclusion fee, based on :ref:`RedeemTransactionSize` and the inclusion fee estimates reported by the oracle. The actual amount spent on the inclusion fee is not checked. If the vault does not spend the whole budget, it can keep the surplus, although it will not be able to spend it without being liquidated for theft. It may at some point want to withdraw all of its collateral and then to move its bitcoin into a new account. The second fee that the user pays for is the parachain fee that goes to the fee pool to incentivize the various participants in the system.

The main accounting changes of a successful redeem is summarized below. See the individual functions for more details.

  - ``redeem.amountBTC`` bitcoin is transferred to the user.
  - ``redeem.amountBTC + redeem.fee + redeem.transferFeeBTC`` is burned from the user.
  - The vault's ``issuedTokens`` decreases by ``redeem.amountBTC + redeem.transferFeeBTC``.
  - The fee pool content increases by ``redeem.fee``.



Data Model
~~~~~~~~~~

Scalars
-------


.. _RedeemPeriod:

RedeemPeriod
............

The time difference between when an redeem request is created and required completion time by a vault. Concretely, this period is the amount by which :ref:`activeBlockCount` is allowed to increase before the redeem is considered to be expired. The period has an upper limit to ensure the user gets his BTC in time and to potentially punish a vault for inactivity or stealing BTC. Each redeem request records the value of this field upon creation, and when checking the expiry, the maximum of the current RedeemPeriod and the value as recorded in the RedeemRequest is used. This way, users are not negatively impacted by a change in the value.

.. _RedeemTransactionSize:

RedeemTransactionSize
.....................

The expected size in bytes of a redeem. This is used to set the bitcoin inclusion fee budget.

.. _RedeemBtcDustValue:

RedeemBtcDustValue
..................

The minimal amount in BTc a vault can be asked to transfer to the user. Note that this is not equal to the amount requests, since an inclusion fee is deducted from that amount.

Maps
----

RedeemRequests
...............

Users create redeem requests to receive BTC in return for interbtc. This mapping provides access from a unique hash ``redeemId`` to a ``Redeem`` struct. ``<redeemId, Redeem>``.


Structs
-------

Redeem
......

Stores the status and information about a single redeem request.

.. tabularcolumns:: |l|l|L|

==================  ==========  =======================================================	
Parameter           Type        Description                                            
==================  ==========  =======================================================
``vault``           Account     The BTC Parachain address of the vault responsible for this redeem request.
``opentime``        u32         The :ref:`activeBlockCount` when the redeem request was made. Serves as start for the countdown until when the vault must transfer the BTC.
``period``          u32         Value of :ref:`RedeemPeriod` when the redeem request was made, in case that value changes while this redeem is pending. 
``amountBTC``       BTC         Amount of BTC to be sent to the user.
``transferFeeBTC``  BTC         Budget for the vault to spend in bitcoin inclusion fees.
``fee``             interbtc    Parachain fee: amount to be transferred from the user to the fee pool upon completion of the redeem.
``premiumDOT``      DOT         Amount of DOT to be paid as a premium to this user (if the Vault's collateral rate was below ``PremiumRedeemThreshold`` at the time of redeeming).
``redeemer``        Account     The BTC Parachain address of the user requesting the redeem.
``btcAddress``      bytes[20]   Base58 encoded Bitcoin public key of the User.  
``btcHeight``       u32         Height of newest bitcoin block in the relay at the time the request is accepted. This is used by the clients upon startup, to determine how many blocks of the bitcoin chain they need to inspect to know if a payment has been made already.
``status``          enum        The status of the redeem: ``Pending``, ``Completed``, ``Retried`` or ``Reimbursed(bool)``, where bool=true indicates that the vault minted tokens for the amount that the redeemer burned
==================  ==========  =======================================================

Functions
~~~~~~~~~

.. _requestRedeem:

requestRedeem
--------------

A user requests to start the redeem procedure.
This function checks the BTC Parachain status in :ref:`security` and decides how the redeem process is to be executed. 
The following modes are possible:

* **Normal Redeem** - no errors detected, full BTC value is to be Redeemed. 
* **Premium Redeem** - the selected Vault's collateral rate has fallen below ``PremiumRedeemThreshold``. Full BTC value is to be redeemed, but the user is allocated a premium in DOT (``RedeemPremiumFee``), taken from the Vault's to-be-released collateral.

Specification
.............

*Function Signature*

``requestRedeem(redeemer, amountinterbtc, btcAddress, vault)``

*Parameters*

* ``redeemer``: address of the user triggering the redeem.
* ``amountinterbtc``: the amount of interbtc to destroy and BTC to receive.
* ``btcAddress``: the address to receive BTC.
* ``vault``: the vault selected for the redeem request.

*Returns*

* ``redeemId``: A unique hash identifying the redeem request.

*Events*

* ``RequestRedeem(redeemId, redeemer, amount, vault, btcAddress)``

*Preconditions*

Let ``burnedTokens`` be ``amountinterbtc`` minus the result of the multiplication of :ref:`RedeemFee` and ``amountinterbtc``. Then:

* The function call MUST be signed by *redeemer*.
* The BTC Parachain status in the :ref:`security` component MUST be set to ``RUNNING:0``.
* The selected vault MUST NOT be banned.
* The selected vault MUST NOT be liquidated.
* The redeemer MUST have at least ``amountinterbtc`` free tokens.
* ``burnedTokens`` minus the inclusion fee MUST be above the :ref:`RedeemBtcDustValue`, where the inclusion fee is the multiplication of :ref:`RedeemTransactionSize` and the fee rate estimate reported by the oracle.
* The vault's ``issuedTokens`` MUST be at least ``vault.toBeRedeemedTokens + burnedTokens``.

*Postconditions*

Let ``burnedTokens`` be ``amountinterbtc`` minus the result of the multiplication of :ref:`RedeemFee` and ``amountinterbtc``. Then:

* The vault's ``toBeRedeemedTokens`` MUST increase by ``burnedTokens``.
* ``amountinterbtc`` of the redeemer's tokens MUST be locked by this transaction.
* :ref:`decreaseToBeReplacedTokens` MUST be called, supplying ``vault`` and ``burnedTokens``. The returned ``replaceCollateral`` MUST be released by this function.
* A new ``RedeemRequest`` MUST be added to the ``RedeemRequests`` map, with the following value:
   * 
   * ``redeem.vault`` is the requested ``vault``
   * ``redeem.opentime`` is the current :ref:`activeBlockCount`
   * ``redeem.fee`` is :ref:`RedeemFee` multiplied by ``amountinterbtc``,
   * ``redeem.transferFeeBtc`` is the inclusion_fee, which is the multiplication of :ref:`RedeemTransactionSize` and the fee rate estimate reported by the oracle,
   * ``redeem.amount_btc`` is ``amountinterbtc - redeem.fee - redeem.transferFeeBtc``,
   * ``redeem.period`` is the current value of the :ref:`RedeemPeriod`,
   * ``redeem.redeemer`` is the ``redeemer`` argument,
   * ``redeem.btc_address`` is the ``btcAddress`` argument,
   * ``redeem.btc_height`` is the current height of the btc relay,
   * ``redeem.status`` is ``Pending``,
   * If the vault's collateralization rate is above the :ref:`PremiumCollateralThreshold`, then ``redeem.premium`` is ``0``,
   * If the vault's collateralization rate is below the :ref:`PremiumCollateralThreshold`, then ``redeem.premium`` is :ref:`PremiumRedeemFee` multiplied by the worth of ``redeem.amount_btc``,

.. _liquidationRedeem:

liquidationRedeem
-----------------

A user executes a liquidation redeem that exchanges interbtc for DOT from the `LiquidationVault`. The 1:1 backing is being recovered, hence this function burns interbtc without releasing any BTC. 

Specification
.............

*Function Signature*

``liquidationRedeem(redeemer, amountinterbtc)``

*Parameters*

* ``redeemer``: address of the user triggering the redeem.
* ``amountinterbtc``: the amount of interbtc to destroy.


*Events*

* ``RequestRedeem(redeemID, redeemer, redeemAmountWrapped, feeWrapped, premium, vaultID, userBtcAddress, transferFeeBtc)``


*Preconditions*

* The BTC Parachain status in the :ref:`security` component MUST NOT be set to ``SHUTDOWN:2``.
* The function call MUST be signed.
* The redeemer MUST have at least ``amountinterbtc`` free tokens.

*Postconditions*

* ``amountinterbtc`` tokens MUST be burned from the user.
* :ref:`redeemTokensLiquidation` MUST be called with ``redeemer`` and ``amountinterbtc`` as arguments.

.. _executeRedeem:

executeRedeem
-------------

A vault calls this function after receiving an ``RequestRedeem`` event with his public key. Before calling the function, the vault transfers the specific amount of BTC to the BTC address given in the original redeem request. The vault completes the redeem with this function.

Specification
.............

*Function Signature*

``executeRedeem(vault, redeemId, merkleProof, rawTx)``

*Parameters*

* ``vault``: the vault responsible for executing this redeem request.
* ``redeemId``: the unique hash created during the ``requestRedeem`` function.
* ``merkleProof``: Merkle tree path (concatenated LE SHA256 hashes).
* ``rawTx``: Raw Bitcoin transaction including the transaction inputs and outputs.


*Events*

* ``ExecuteRedeem(redeemer, redeemId, amount, vault)``:


*Preconditions*

* The function call MUST be signed be *someone*, i.e. not necessarily the *redeemer*.
* The BTC Parachain status in the :ref:`security` component MUST NOT be set to ``SHUTDOWN:2``.
* A *pending* ``RedeemRequest`` MUST exist with an id equal to ``redeemId``.
* The request MUST NOT have expired.
* * The ``rawTx`` MUST decode to a valid transaction that transfers at least the amount specified in the ``RedeemRequest`` struct. It MUST be a transaction to the correct address, and provide the expected OP_RETURN, based on the ``RedeemRequest``.
* The ``merkleProof`` MUST contain a valid proof of of ``rawTX``.
* The bitcoin payment MUST have been submitted to the relay chain, and MUST have sufficient confirmations.

*Postconditions*

* ``redeemRequest.amount_btc - redeemRequest.transferFeeBtc`` of the tokens in the redeemer's account MUST be burned.
* ``redeemRequest.fee`` MUST be unlocked and transferred from the redeemer's account to the fee pool.
* :ref:`redeemTokens` MUST be called, supplying ``redeemRequest.vault``, ``redeemRequest.amountBtc - redeemRequest.transferFeeBtc``, ``redeemRequest.premium`` and ``redeemRequest.redeemer`` as arguments.
* ``redeemRequest.status`` MUST be set to ``Completed``.


.. _cancelRedeem:

cancelRedeem
------------

If a redeem request is not completed on time, the redeem request can be cancelled.
The user that initially requested the redeem process calls this function to obtain the Vault's collateral as compensation for not refunding the BTC back to his address.

The failed vault is banned from further issue, redeem and replace requests for a pre-defined time period (``PunishmentDelay`` as defined in :ref:`vault-registry`).

The user is able to choose between reimbursement and retrying. If the user chooses the retry, it gets back the tokens, and a punishment fee is transferred from the vault to the user. If the user chooses reimbursement, then he receives the equivalent worth of the tokens in collateral, plus a punishment fee. In this case, the tokens are transferred from the user to the vault. In either case, the vault may also be slashed an additional punishment that goes to the fee pool.

With the SLA model additions, the punishment fee paid to the user stays constant (i.e., the user always receives the punishment fee of e.g. 10%). However, vaults may be slashed more than the punishment fee, as determined by the SLA. The surplus slashed collateral is routed into the Parachain Fee pool and handled like regular fee income. For example, if the vault is punished with 20%, 10% punishment fee is paid to the user and 10% is paid to the fee pool.


Specification
.............

*Function Signature*

``cancelRedeem(redeemId, reimburse)``

*Parameters*

* ``redeemId``: the unique hash of the redeem request.
* ``reimburse``: boolean flag, specifying if the user wishes to be reimbursed in DOT and slash the vault, or wishes to keep the interbtc (and retry to redeem with another Vault).


*Events*

``CancelRedeem(redeemId, redeemer, amountBtc, fee, vault)``: Emits an event with the ``redeemId`` that is cancelled.

*Preconditions*

* The BTC Parachain status in the :ref:`security` component MUST be set to ``RUNNING:0``.
* A *pending* ``RedeemRequest`` MUST exist with an id equal to ``redeemId``.
* The function call MUST be signed by ``redeemRequest.redeemer``, i.e. this function can only be called by the account who made the redeem request.
* The request MUST be expired.

*Postconditions*

Let ``amountIncludingParachainFee`` be equal to the worth in collateral of ``redeem.amount_btc + redeem.transfer_fee_btc``. Then:

* If the vault is liquidated, the redeemer MUST be transferred part of the vault's collateral: an amount of  ``vault.backingCollateral * ((amountIncludingParachainFee) / vault.to_be_redeemed_tokens)``.
* If the vault is *not* liquidated, the fellowing collateral changes are made:
   * If ``reimburse`` is true, the user SHOULD be reimbursed the worth of ``amountIncludingParachainFee`` in collateral. The transfer MUST be saturating, i.e. if the amount is not available, it should transfer whatever amount *is* available.
   * A punishment fee SHOULD be tranferred from the vault's backing collateral to the reedeemer: an amount of :ref:`PunishmentFee` times the worth of ``amountIncludingParachainFee``. The transfer MUST be saturating, i.e. if the amount is not available, it should transfer whatever amount *is* available.
   * An additional punishment fee SHOULD be transferred to the fee pool: an amount ranging from :ref:`LiquidationThreshold` to :ref:`PremiumCollateralThreshold` times the worth of ``amountIncludingParachainFee``, depending on the vault's SLA. The transfer MUST be saturating, i.e. if the amount is not available, it should transfer whatever amount *is* available.
* If ``reimburse`` is true: 
   * ``redeem.fee`` MUST be transferred from the vault to the fee pool.
   * If after the loss of collateral the vault is below the :ref:`SecureCollateralThreshold`:
      *  ``amountIncludingParachainFee`` of the user's tokens are *burned*. 
      * :ref:`decreaseTokens` MUST be called, supplying the vault, the user, and ``amountIncludingParachainFee`` as arguments. 
      *  The ``redeem.status`` is set to ``Reimbursed(false)``, where the ``false`` indicates that the vault has not yet received the tokens.
   * If after the loss of collateral the vault remains above the :ref:`SecureCollateralThreshold`:
      * ``amountIncludingParachainFee`` of the user's tokens MUST be unlocked and transferred to the vault. 
      * :ref:`decreaseToBeRedeemedTokens` MUST be called, supplying the vault and ``amountIncludingParachainFee`` as arguments. 
      * The ``redeem.status`` is set to ``Reimbursed(true)``, where the ``true`` indicates that the vault has received the tokens.
* If ``reimburse`` is false:
   * All the user's tokens that were locked in :ref:`requestRedeem` MUST be unlocked, i.e. an amount of ``redeem.amount_btc + redeem.fee + redeem.transfer_fee_btc``.
   * The vault's ``toBeRedeemedTokens`` MUST decrease by ``amountIncludingParachainFee``.
* The vault MUST be banned.



.. _mintTokensForReimbursedRedeem:

mintTokensForReimbursedRedeem
-----------------------------

If a redeemrequest has the status ``Reimbursed(false)``, the vault was unable to back the to be received tokens at the time of the ``cancelRedeem``. After gaining sufficient collateral, the vault can call this function to finally get its tokens. 

Specification
.............

*Function Signature*

``mintTokensForReimbursedRedeem(vault, redeemId)``

*Parameters*

* ``redeemId``: the unique hash of the redeem request.
* ``reimburse``: boolean flag, specifying if the user wishes to be reimbursed in DOT and slash the vault, or wishes to keep the interbtc (and retry to redeem with another Vault).

*Events*

``MintTokensForReimbursedRedeem(vaultId, redeemId, amountMinted)``

*Preconditions*

* The BTC Parachain status in the :ref:`security` component MUST be set to ``RUNNING:0``.
* A ``RedeemRequest`` MUST exist with an id equal to ``redeemId``.
* ``redeem.status`` MUST be ``Reimbursed(false)``.
* The vault MUST have sufficient collateral to remain above the :ref:`SecureCollateralThreshold` after issuing ``redeem.amount_btc + redeem.transfer_fee_btc`` tokens.
* The vault MUST NOT be banned.


*Postconditions*

* The function call MUST be signed by ``redeem.vault``, i.e. this function can only be called by the the vault.
* :ref:`tryIncreaseToBeIssuedTokens` and :ref:`issueTokens` MUST be called, both with the vault and ``redeem.amount_btc + redeem.transfer_fee_btc`` as arguments.
* ``redeem.amount_btc + redeem.transfer_fee_btc`` tokens MUST be minted to the vault.


Events
~~~~~~~

RequestRedeem
-------------

Emit an event when a redeem request is created. This event needs to be monitored by the vault to start the redeem request.

*Event Signature*

* ``RequestRedeem(redeemID, redeemer, redeemAmountWrapped, feeWrapped, premium, vaultID, userBtcAddress, transferFeeBtc)``

*Parameters*

* ``redeemID``: the unique identifier of this redeem request.
* ``redeemer``: address of the user triggering the redeem.
* ``redeemAmountWrapped``: the amount to be received by the user.
* ``feeWrapped``: the fee to be given to the foo pool.
* ``premium``: the premium to be given to the user, if any.
* ``vaultID``: the vault selected for the redeem request.
* ``userBtcAddress``: the address the vault is to transfer the funds to.
* ``transferFeeBtc``: the budget the vault has to spend on bitcoin inclusion fees, paid for by the user.

*Functions*

* ref:`requestRedeem`

LiquidationRedeem
-----------------

Emit an event when a user does a liquidation redeem.

*Event Signature*

``LiquidationRedeem(redeemer, amountinterbtc)``

*Parameters*

* ``redeemer``: address of the user triggering the redeem.
* ``amountinterbtc``: the amount of interbtc to burned.

*Functions*

* ref:`liquidationRedeem`

ExecuteRedeem
-------------

Emit an event when a redeem request is successfully executed by a vault.

*Event Signature*

``ExecuteRedeem(redeemer, redeemId, amountinterbtc, vault)``

*Parameters*

* ``redeemer``: address of the user triggering the redeem.
* ``redeemId``: the unique hash created during the ``requestRedeem`` function.
* ``amountinterbtc``: the amount of interbtc to destroy and BTC to receive.
* ``vault``: the vault responsible for executing this redeem request.


*Functions*

* ref:`executeRedeem`


CancelRedeem
------------

Emit an event when a user cancels a redeem request that has not been fulfilled after the ``RedeemPeriod`` has passed.

*Event Signature*

``CancelRedeem(redeemId, redeemer, amountBtc, fee, vault)``

*Parameters*

* ``redeemId``: the unique hash of the redeem request.
* ``redeemer``: The redeemer starting the redeem process.
* ``amountBtc``: the amount that was to be received by the user.
* ``fee``: the parachain fee that was to be added to the fee pool upon a successful redeem. 
* ``vault``: the vault who failed to execute the redeem.

*Functions*

* ref:`cancelRedeem`


MintTokensForReimbursedRedeem
-----------------------------

Emit an event when a vault minted the tokens corresponding the a cancelled redeem that was reimbursed to the user, when the vault did not have sufficient collateral at the time of the cancellation to back the tokens.

*Event Signature*

``MintTokensForReimbursedRedeem(vaultId, redeemId, amountMinted)``

*Parameters*

* ``vault``: if of the vault that now mints the tokens.
* ``redeemId``: the unique hash of the redeem request.
* ``amountMinted``: the amount that the vault just minted.


*Functions*

* ref:`mintTokensForReimbursedRedeem`

Error Codes
~~~~~~~~~~~

``ERR_VAULT_NOT_FOUND``

* **Message**: "There exists no vault with the given account id."
* **Function**: :ref:`requestRedeem`, :ref:`liquidationRedeem`
* **Cause**: The specified vault does not exist.

``ERR_AMOUNT_EXCEEDS_USER_BALANCE``

* **Message**: "The requested amount exceeds the user's balance."
* **Function**: :ref:`requestRedeem`, :ref:`liquidationRedeem`
* **Cause**: If the user is trying to redeem more BTC than his interbtc balance.

``ERR_VAULT_BANNED``

* **Message**: "The selected vault has been temporarily banned."
* **Function**: :ref:`requestRedeem`
* **Cause**:  Redeem requests are not possible with temporarily banned Vaults

``ERR_AMOUNT_EXCEEDS_VAULT_BALANCE``

* **Message**: "The requested amount exceeds the vault's balance."
* **Function**: :ref:`requestRedeem`, :ref:`liquidationRedeem`
* **Cause**: If the user is trying to redeem from a vault that has less BTC locked than requested for redeem.

``ERR_REDEEM_ID_NOT_FOUND``

* **Message**: "The ``redeemId`` cannot be found."
* **Function**: :ref:`executeRedeem`
* **Cause**: The ``redeemId`` in the ``RedeemRequests`` mapping returned ``None``.

``ERR_REDEEM_PERIOD_EXPIRED``

* **Message**: "The redeem period expired."
* **Function**: :ref:`executeRedeem`
* **Cause**: The time limit as defined by the ``RedeemPeriod`` is not met.

``ERR_UNAUTHORIZED``

* **Message**: "Caller is not authorized to call this function."
* **Function**: :ref:`cancelRedeem` | :ref:`mintTokensForReimbursedRedeem`
* **Cause**: Only the user can call :ref:`cancelRedeem`, and only the vault can call :ref:`mintTokensForReimbursedRedeem`.

``ERR_REDEEM_PERIOD_NOT_EXPIRED``

* **Message**: "The period to complete the redeem request is not yet expired."
* **Function**: :ref:`cancelRedeem`
* **Cause**:  Raises an error if the time limit to call ``executeRedeem`` has not yet passed.

``ERR_REDEEM_CANCELLED``

* **Message**: "The redeem is in an unexpected cancelled state."
* **Function**: :ref:`cancelRedeem` | :ref:`mintTokensForReimbursedRedeem` | :ref:`executeRedeem`
* **Cause**:  The status of the redeem is not as required for this call.

``ERR_REDEEM_COMPLETED``

* **Message**: "The redeem is already completed."
* **Function**: :ref:`cancelRedeem` | :ref:`executeRedeem`
* **Cause**:  The status of the redeem is not as expected for this call.

