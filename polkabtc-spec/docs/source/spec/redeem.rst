.. _redeem-protocol:

Redeem
======

Overview
~~~~~~~~

The redeem module allows a user to receive BTC on the Bitcoin chain in return for destroying an equivalent amount of PolkaBTC on the BTC Parachain. The process is initiated by a user requesting a redeem with a vault. The vault then needs to send BTC to the user within a given time limit. Next, the vault has to finalize the process by providing a proof to the BTC Parachain that he has send the right amount of BTC to the user. If the vault fails to deliver a valid proof within the time limit, the user can claim an equivalent amount of DOT from the vault's locked collateral to reimburse him for his loss in BTC.

Step-by-step
------------

1. Precondition: A user owns PolkaBTC.
2. A user locks an amount of PolkaBTC by calling the :ref:`requestRedeem` function. In this function call, the user selects a vault to execute the redeem request from the list of vaults. The function creates a redeem request with a unique hash.
3. The selected vault listens for the ``RequestRedeem`` event emitted by the user. The vault then proceeds to transfer BTC to the address specified by the user in the :ref:`requestRedeem` function including a unique hash in the ``OP_RETURN`` of one output.
4. The vault executes the :ref:`executeRedeem` function by providing the Bitcoin transaction from step 3 together with the redeem request identifier within the time limit. If the function completes successfully, the locked PolkaBTC are destroyed and the user received its BTC.
5. Optional: If the user could not receive BTC within the given time (as required in step 4), the user calls :ref:`cancelRedeem` after the redeem time limit. The user is then refunded with the DOT collateral the vault provided.


VaultRegistry
-------------

The data access and state changes to the vault registry are documented in :numref:`fig-vault-registry-redeem` below.

.. _fig-vault-registry-redeem:
.. figure:: ../figures/VaultRegistry-Redeem.png
    :alt: vault-registry-redeem

    The redeem module interacts through three different functions with the vault registry.

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
...............

Users create redeem requests to receive BTC in return for PolkaBTC. This mapping provides access from a unique hash ``redeemId`` to a ``Redeem`` struct. ``<redeemId, Redeem>``.

*Substrate* ::

  RedeemRequests map T::H256 => Redeem<T::AccountId, T::BlockNumber, T::Balance>


Structs
-------

Redeem
......

Stores the status and information about a single redeem request.

.. tabularcolumns:: |l|l|L|

==================  ==========  =======================================================	
Parameter           Type        Description                                            
==================  ==========  =======================================================
``vault``           Account     The BTC Parachain address of the Vault responsible for this redeem request.
``opentime``        u256        Block height of opening the request.
``amountPolkaBTC``  PolkaBTC    Amount of PolkaBTC the user requested to be redeemed.
``amountBTC``       BTC         Amount of BTC to be released to the user.
``amountDOT``       DOT         Amount of DOT to be paid to the user from liquidated Vaults' collateral (when ``LIQUIDATION`` error indicated in :ref:`security`). 
``premiumDOT``      DOT         Amount of DOT to be paid as a premium to this user (if the Vault's collateral rate was below ``PremiumRedeemThreshold`` at the time of redeeming).
``redeemer``        Account     The BTC Parachain address of the user requesting the redeem.
``btcAddress``      bytes[20]   Base58 encoded Bitcoin public key of the User.  
==================  ==========  =======================================================

*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Redeem<AccountId, BlockNumber, Balance> {
        vault: AccountId,
        opentime: BlockNumber,
        amountPolkaBTC: Balance,
        amountBTC: Balance,
        amountDOT: Balance,
        premiumDOT: Balance,
        redeemer: AccountId,
        btcAddress: H160,
  }

Functions
~~~~~~~~~

.. _requestRedeem:

requestRedeem
--------------

A user requests to start the redeem procedure.
This function checks the BTC Parachain status in :ref:`security` and decides how the Redeem process is to be executed. 
The following modes are possible:

* **Normal Redeem** - no errors detected, full BTC value is to be Redeemed. 
* **Premium Redeem** - the selected Vault's collateral rate has fallen below ``PremiumRedeemThreshold``. Full BTC value is to be Redeemed, but the user is allocated a premium in DOT (``RedeemPremiumFee``), taken from the Vault's to-be-released collateral.
* **Liquidation Redeem** - the BTC Parachain is in ``ERROR`` state with ``LIQUIDATION`` error code. The 1:1 backing is being recovered, hence only a part of the BTC value is being redeemed in BTC, the rest is being released in DOT. The user is also allocated the ``PunishmentFee`` in DOT, taken from the Vault's to-be-released collateral as reimbursement for possible opportunity costs.

Specification
.............

*Function Signature*

``requestRedeem(redeemer, amountPolkaBTC, btcPublicKey, vault)``

*Parameters*

* ``redeemer``: address of the user triggering the redeem.
* ``amountPolkaBTC``: the amount of PolkaBTC to destroy and BTC to receive.
* ``btcAddress``: the address to receive BTC.
* ``vault``: the vault selected for the redeem request.

*Returns*

* ``redeemId``: A unique hash identifying the redeem request.

*Events*

* ``RequestRedeem(redeemId, redeemer, amount, vault, btcAddress)``

*Errors*

* ``ERR_VAULT_NOT_FOUND = "There exists no Vault with the given account id"``: The specified Vault does not exist. 
* ``ERR_AMOUNT_EXCEEDS_USER_BALANCE``: If the user is trying to redeem more BTC than his PolkaBTC balance.
* ``ERR_AMOUNT_EXCEEDS_VAULT_BALANCE``: If the user is trying to redeem from a vault that has less BTC locked than requested for redeem.
* ``ERR_VAULT_BANNED = "The selected Vault has been temporarily banned."``: Redeem requests are not possible with temporarily banned Vaults.

*Substrate* ::

  fn requestRedeem(origin, amount: Balance, btcAddress: H160, vault: AccountID) -> Result {...}


Preconditions
.............

* The BTC Parachain status in the :ref:`security` component must be set to ``RUNNING:0`` or to ``ERROR:1`` with ``Errors`` containing only ``LIQUIDATION``. All other states are disallowed.
* The selected Vault must not have been banned. 

Function Sequence
.................

1. Check if the ``amountPolkaBTC`` is less or equal to the user's balance in the treasury. Return ``ERR_AMOUNT_EXCEEDS_USER_BALANCE`` if this check fails.

2. Retrieve the ``vault`` from :ref:`vault-registry`. Return ``ERR_VAULT_NOT_FOUND`` if no Vault can be found.

3. Check that the ``vault`` is currently not banned, i.e., ``vault.bannedUntil == None`` or ``vault.bannedUntil < current parachain block height``. Return ``ERR_VAULT_BANNED`` if this check fails.

4. Check if the ``amountPolkaBTC`` is less or equal to the ``issuedTokens`` by the selected vault in the VaultRegistry. Return ``ERR_AMOUNT_EXCEEDS_VAULT_BALANCE`` if this check fails.

5. Check if ``ParachainState`` in :ref:`security` is ``ERROR`` with ``LIQUIDATION`` in ``Errors``. 

   a. If this is the case,

      i ) set ``amountDOTinBTC = amountPolkaBTC * getPartialRedeemFactor() / 100000`` (note: this is due to the representation of fractions as integers between 0 and 100000).

      ii ) Set ``amountBTC = amountPolkaBTC - amountDOTinBTC``.

      iii ) Set ``amountDOT = amountDOTinBTC *`` :ref:`getExchangeRate`.

   b. Otherwise, set ``amountBTC = amount``, ``amountDOT = 0``.

6. Call the :ref:`vault-registry` :ref:`increaseToBeRedeemedTokens` function with the ``amountBTC`` of tokens to be redeemed and the ``vault`` identified by its address.

7. If ``amountDOT > 0``, call :ref:`redeemTokensLiquidation` in :ref:`vault-registry`. This allocates the user ``amountDOT`` using the ``LiquidationVault``'s collateral and updates the ``LiquidationVault``'s polkaBTC balances. 

8. Call the :ref:`lock` function in the Treasury to lock the PolkaBTC ``amount`` of the user.

9. Generate a ``redeemId`` using :ref:`generateSecureId`, passing ``redeemer`` as parameter.

10. Check if the Vault's collateral rate is below ``PremiumRedeemThreshold``. If this is the case, set ``premiumDOT = RedeemPremiumFee`` (as per :ref:`vault-registry`). Otherwise set ``premiumDOT = 0``.

11. Store a new ``Redeem`` struct in the ``RedeemRequests`` mapping as ``RedeemRequests[redeemId] = redeem``, where:
    
    - ``redeem.vault`` is the requested ``vault``
    - ``redeem.opentime`` is the current block number
    - ``redeem.amountPolkaBTC`` is the ``amount`` provided as input
    - ``redeem.amountBTC = amountBTC``
    - ``redeem.amountDOT = amountDOT``
    - ``redeem.premiumDOT = premiumDOT``
    - ``redeem.redeemer`` is the redeemer account
    - ``redeem.btcAddress`` the Bitcoin address of the user.

12. Emit the ``RequestRedeem`` event with the ``redeemId``, ``redeemer`` account, ``amount``, ``vault``, and ``btcAddress``.

13. Return the ``redeemId``. The user stores this for future reference locally.

.. _executeRedeem:

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

* ``ERR_REDEEM_ID_NOT_FOUND``: The ``redeemId`` cannot be found.
* ``ERR_REDEEM_PERIOD_EXPIRED``: The time limit as defined by the ``RedeemPeriod`` is not met.
* ``ERR_UNAUTHORIZED = Unauthorized: Caller must be associated vault``: The caller of this function is not the associated vault, and hence not authorized to take this action.


*Substrate* ::

  fn executeRedeem(origin, redeemId: T::H256, txId: T::H256, txBlockHeight: U256, txIndex: u64, merkleProof: Bytes, rawTx: Bytes) -> Result {...}

Preconditions
.............

* The BTC Parachain status in the :ref:`security` component must be set to ``RUNNING:0``.

Function Sequence
.................

.. note:: The accepted Bitcoin transaction format for this function is specified in the BTC-Relay specification and can be found at `https://interlay.gitlab.io/polkabtc-spec/btcrelay-spec/intro/accepted-format.html <https://interlay.gitlab.io/polkabtc-spec/btcrelay-spec/intro/accepted-format.html>`_.

1. Check if the ``vault`` is the ``redeem.vault``. Return ``ERR_UNAUTHORIZED`` if called by any account other than the associated ``redeem.vault``.
2. Check if the ``redeemId`` exists. Return ``ERR_REDEEM_ID_NOT_FOUND`` if not found.
3. Check if the current block height minus the ``RedeemPeriod`` is smaller than the ``opentime`` specified in the ``Redeem`` struct. If this condition is false, throws ``ERR_REDEEM_PERIOD_EXPIRED``.
4. Verify the transaction.

    - Call *verifyTransactionInclusion* in :ref:`btc-relay`, providing ``txId``, ``txBlockHeight``, ``txIndex``, and ``merkleProof`` as parameters. If this call returns an error, abort and return the received error. 
    - Call *validateTransaction* in :ref:`btc-relay`, providing ``rawTx``, the amount of to-be-redeemed BTC (``redeem.amount``), the ``redeemer``'s Bitcoin address (``redeem.btcAddress``), and the ``redeemId`` as parameters. If this call returns an error, abort and return the received error. 

5. Call the :ref:`burn` function in the Treasury to burn the ``redeem.amount`` of PolkaBTC of the user.

6. Check ``redeem.premiumDOT > 0``:
   
   a. If ``True``, call :ref:`redeemTokensPremium` in the VaultRegistry to release the Vault's collateral with the ``redeem.vault`` and the ``redeem.amount``, and ``redeemer`` and ``premiumDOT`` to allocate the DOT premium to the redeemer using the Vault's released collateral.
   b. Else call :ref:`redeemTokens` function in the VaultRegistry to release the Vault's collateral with the ``redeem.vault`` and the ``redeem.amount``.

7. Remove ``redeem`` from ``RedeemRequests``.
8. Emit an ``ExecuteRedeem`` event with the user's address, the redeemId, the amount, and the Vault's address.
9. Return.

.. _cancelRedeem:

cancelRedeem
------------

If a redeem request is not completed on time, the redeem request can be cancelled.
The user that initially requested the redeem process calls this function to obtain the Vault's collateral as compensation for not refunding the BTC back to his address.

The failed Vault is banned from further issue, redeem and replace requests for a pre-defined time period (``PunishmentDelay`` as defined in :ref:`vault-registry`).


Specification
.............

*Function Signature*

``cancelRedeem(redeemId, reimburse)``

*Parameters*

* ``redeemId``: the unique hash of the redeem request.
* ``reimburse``: boolean flag, specifying if the user wishes to be reimbursed in DOT and slash the Vault, or wishes to keep the PolkaBTC (and retry to redeem with another Vault).

*Returns*

* ``None``

*Events*

* ``CancelRedeem(redeemer, redeemId)``: Emits an event with the ``redeemId`` that is cancelled.

*Errors*

* ``ERR_REDEEM_ID_NOT_FOUND``: The ``redeemId`` cannot be found.
* ``ERR_REDEEM_PERIOD_NOT_EXPIRED``: Raises an error if the time limit to call ``executeRedeem`` has not yet passed.

*Substrate* ::

  fn cancelRedeem(origin, redeemId: T::H256, reimburse: bool) -> Result {...}

Preconditions
.............

* None.


Function Sequence
.................

1. Check if an redeem with id ``redeemId`` exists. If not, throw ``ERR_REDEEM_ID_NOT_FOUND``. Otherwise, load the redeem request ``redeem = RedeemRequests[redeemId]``.

2. Check if the expiry time of the redeem request is up, i.e ``redeem.opentime + RedeemPeriod < now``. If the time is not up, throw ``ERR_REDEEM_PERIOD_NOT_EXPIRED``.

3. Retrieve the current BTC-DOT exchange rate (``exchangeRate``) via :ref:`getExchangeRate` from the :ref:`oracle`.

4. If ``reimburse == True`` (user requested to be reimbursed in DOT): 

   a. Call the :ref:`decreaseTokens` function in the VaultRegistry to transfer (a part) of the Vault's collateral to the user with the ``redeem.vault``, ``redeem.redeemer``, and ``redeem.amount`` parameters.

   b. Call the :ref:`burn` function in the Treasury to burn the ``redeem.amount`` of PolkaBTC of the user.
   
   c. Call :ref:`slashCollateral` in the :ref:`collateral-module` module, passing ``redeem.vault``, ``redeem.redeemer`` and the value of the reimbursed collateral, calculated as ``redeem.amountPolkaBTC *`` :ref:`getExchangeRate` ``* (1 + PunishmentFee / 100000)``

4. Else, if ``reimburse == False`` (user does not want full reimbursement and wishes to retry the redeem)
    
  a. Call :ref:`slashCollateral` in the :ref:`collateral-module` module, passing ``redeem.vault``, ``redeem.redeemer`` and value of the collateral punishment, calculated as ``redeem.amountPolkaBTC *`` :ref:`getExchangeRate` ``* (PunishmentFee / 100000)`` 

5. Temporarily Ban the Vault from issue, redeem and replace processes by setting ``redeem.vault.bannedUntil = current parachain block height + PunishmentDelay``.

6. Remove ``redeem`` from ``RedeemRequests``.

7. Emit a ``CancelRedeem`` event with the ``redeemer`` account identifier and the ``redeemId``.

8. Return.


.. _getPartialRedeemFactor:

getPartialRedeemFactor
----------------------

Calculates the fraction of BTC to be redeemed in DOT when the BTC Parachain state is in ``ERROR`` state due to a ``LIQUIDATION`` error.

Specification
.............

*Function Signature*

``getPartialRedeemFactor()``

*Returns*

* ``redeemFactor``: integer value between 0 an 10000 indicating the percentage of BTC to be redeemed in DOT. 

*Substrate* ::

  fn getPartialRedeemFactor() -> U128 {...}

Function Sequence
.................

1. Get the current exchange rate (``exchangeRate``) using :ref:`getExchangeRate`.

2. Calculate ``totalLiquidationValue =`` :math:`\sum_{v}^{LiquidationList} (\mathit{v.issuedTokens} \cdot \mathit{exchangeRate} - \mathit{v.collateral})`

3. Retrieve the ``TotalSupply`` of PolkaBTC from :ref:`treasury-module`.

4. Return ``totalLiquidationValue / TotalSupply``


Events
~~~~~~~

RequestRedeem
-------------

Emit an event when a redeem request is created. This event needs to be monitored by the vault to start the redeem request.

*Event Signature*

``RequestRedeem(redeemId, redeemer, amountPolkaBTC, vault, btcAddress)``

*Parameters*

* ``redeemId``: The unique identifier of this redeem request.
* ``redeemer``: address of the user triggering the redeem.
* ``amountPolkaBTC``: the amount of PolkaBTC to destroy and BTC to receive.
* ``btcAddress``: the address to receive BTC.
* ``vault``: the vault selected for the redeem request.

*Functions*

* ref:`requestRedeem`

*Substrate* ::

  RequestRedeem(H256, AccountId, Balance, H160, AccountId);

ExecuteRedeem
-------------

Emit an event when a redeem request is successfully executed by a vault.

*Event Signature*

``ExecuteRedeem(redeemer, redeemId, amountPolkaBTC, vault)``

*Parameters*

* ``redeemer``: address of the user triggering the redeem.
* ``redeemId``: the unique hash created during the ``requestRedeem`` function,
* ``amountPolkaBTC``: the amount of PolkaBTC to destroy and BTC to receive.
* ``vault``: the vault responsible for executing this redeem request.


*Functions*

* ref:`executeRedeem`

*Substrate* ::

  ExecuteRedeem(AccountId, H256, Balance, AccountId);

CancelRedeem
------------

Emit an event when a user cancels a redeem request that has not been fulfilled after the ``RedeemPeriod`` has passed.

*Event Signature*

``CancelRedeem(redeemer, redeemId)``

*Parameters*

* ``redeemer``: The redeemer starting the redeem process.
* ``redeemId``: the unique hash of the redeem request.

*Functions*

* ref:`cancelRedeem`

*Substrate* ::

  CancelRedeem(AccountId, H256);


Error Codes
~~~~~~~~~~~

``ERR_VAULT_NOT_FOUND``

* **Message**: "There exists no Vault with the given account id."
* **Function**: :ref:`requestRedeem`
* **Cause**: The specified Vault does not exist.

``ERR_AMOUNT_EXCEEDS_USER_BALANCE``

* **Message**: "The requested amount exceeds the user's balance."
* **Function**: :ref:`requestRedeem`
* **Cause**: If the user is trying to redeem more BTC than his PolkaBTC balance.

``ERR_VAULT_BANNED``

* **Message**: "The selected Vault has been temporarily banned."
* **Function**: :ref:`requestRedeem`
* **Cause**:  Redeem requests are not possible with temporarily banned Vaults

``ERR_AMOUNT_EXCEEDS_VAULT_BALANCE``

* **Message**: "The requested amount exceeds the vault's balance."
* **Function**: :ref:`requestRedeem`
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

* **Message**: "Unauthorized: Caller must be associated vault."
* **Function**: :ref:`executeRedeem`
* **Cause**: The caller of this function is not the associated vault, and hence not authorized to take this action.

``ERR_REDEEM_PERIOD_NOT_EXPIRED``

* **Message**: "The period to complete the redeem request is not yet expired."
* **Function**: :ref:`cancelRedeem`
* **Cause**:  Raises an error if the time limit to call ``executeRedeem`` has not yet passed.


