.. _Vault-registry:

Vault Registry
==============


.. note:: We recommend implementing getter functions for (i) the total collateral locked through by active PolkaBTC tokens, (ii) the total collateral reserved in pending issue requests, (iii) the total collateral reserved in pending replace requests, and (iv) the total free collateral (not locked / reserved) for compliance and transparency purposes.

Data Model
~~~~~~~~~~

Scalars
-------

MinimumCollateralVault
......................

The minimum collateral (DOT) a Vault needs to provide to participate in the issue process. 

.. note:: This is a protection against spamming the protocol with very small collateral amounts.

*Substrate* :: 

    MinimumCollateralVault: Balance;

SecureCollateralRate
....................

Determines the over-collareralization rate for DOT collateral locked by Vaults, necessary for issuing PolkaBTC. 
Must to be strictly greater than ``100`` and ``LiquidationCollateralRate``.

The Vault can take on issue requests depending on the collateral it provides and under consideration of the ``SecureCollateralRate``.
The maximum amount of PolkaBTC a Vault is able to support during the issue process is based on the following equation:
:math:`\text{max(PolkaBTC)} = \text{collateral} * \text{ExchangeRate} / \text{SecureCollateralRate}`.

.. note:: As an example, assume we use ``DOT`` as collateral, we issue ``PolkaBTC`` and lock ``BTC`` on the Bitcoin side. Let's assume the ``BTC``/``DOT`` exchange rate is ``80``, i.e. one has to pay 80 ``DOT`` to receive 1 ``BTC``. Further, the ``SecureCollateralRate`` is 200%, i.e. a Vault has to provide two-times the amount of collateral to back an issue request. Now let's say the Vault deposits 400 ``DOT`` as collateral. Then this Vault can back at most 2.5 PolkaBTC as: :math:`400 * (1/80) / 2 = 2.5`.

.. todo:: Insert link to security model.

*Substrate* :: 
    
    SecureCollateralRate: u16;

AuctionCollateralRate
......................

Determines the rate for the collateral rate of Vaults, at which the BTC backed by the Vault are opened up for auction to other Vaults. 
That is, if the Vault does not increase its collateral rate, it can be forced to execute the Replace protocol with another Vault, which bids sufficient DOT collateral to cover the issued PolkaBTC tokens.

.. todo:: Insert link to security model.

*Substrate* :: 
    
    AuctionCollateralRate: u16;


LiquidationCollateralRate
.........................

Determines the lower bound for the collateral rate in PolkaBTC. Must be strictly greater than ``100``. If a Vault's collateral rate drops below this, automatic liquidation (forced Redeem) is triggered. 

.. todo:: Insert link to security model.

*Substrate* :: 
    
    LiquidationCollateralRate: u16;


Maps
----


Vaults
......

Mapping from accounts of Vaults to their struct. ``<Account, Vault>``.

*Substrate* ::

    Vaults map T::AccountId => Vault<T::AccountId, T::Balance, T::DateTime>


RegisterRequests (Optional)
.............................

Mapping from registerIDs of RegisterRequest to their structs. ``<U256, RegisterRequest>``.

*Substrate* :: 

    RegisterRequests map T::U256 => Vault<T::AccountId, T::DateTime>




Structs
-------

Vault
.....

Stores the information of a Vault.

.. tabularcolumns:: |l|l|L|

=========================  =========  ========================================================
Parameter                  Type       Description
=========================  =========  ========================================================
``issuedTokens``           PolkaBTC   Number of PolkaBTC tokens actively issued by this Vault.
``reservedTokens``         DOT        Number of PolkaBTC tokens reserved by pending :ref:`issue` and :ref:`replace` requests. 
``collateral``             DOT        Total amount of collateral provided by this Vault (note: "free" collateral is calculated on the fly and updated each time new exchange rate data is received).
``btcAddress``             bytes[20]  Bitcoin address of this Vault, to be used for issuing of PolkaBTC tokens.
=========================  =========  ========================================================

.. note:: This specification currently assumes for simplicity that a Vault will reuse the same BTC address, even after multiple redeem requests. **[Future Extension]**: For better security, Vaults may desire to generate new BTC addresses each time they execute a redeem request. This can be handled by pre-generating multiple BTC addresses and storing these in a list for each Vault. Caution is necessary for users which execute issue requests with "old" Vault addresses - these BTC must be moved to the latest address by Vaults. 


*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Vault<AccountId, Balance> {
        vault: AccountId,
        issuedTokens: Balance,
        collateral: Balance,
        btcAddress: [u8; 20]
  }


RegisterRequest (Optional)
...........................

Optional struct storing data used in the (optional) validity check of the BTC address provided by a Vault upon registration.

===================  =========  ========================================================
Parameter            Type       Description
===================  =========  ========================================================
``registerId``            H256       Identifier used to link a Bitcoin transaction inclusion proof to this registration request (included in OP_RETURN). 
``vault``            Account    Parachain account identifier of the registered Vault
``timeout``          DateTime   Optional maximum delay before the Vault must submit a valid tranasction inclusion proof.
===================  =========  ========================================================

*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Vault<H256, AccountId, DateTime> {
        registrationID: H256,
        vault: AccountId,
        timeout: DateTime
  }

Functions
~~~~~~~~~


registerVault
-------------

Initiates the registration procedure for a new Vault. The Vault provides its BTC address and locks up DOT collateral, which is to be used to the issuing process. 

**[Optional]: check valid BTC address**: The new Vault provides its BTC address and it's DOT collateral, creating a ``RegistrationRequest``, and receives in return a ``registerID``, which it must include in the OP_RETURN field of a transaction signed by the public key corresponding to the provided BTC address. The proof is checked by the BTC-Relay component, and if successful, the Vault is registered. 
Note: Collateral can be required to prevent griefing / spamming.


Specification
.............

*Function Signature*

``requestRegistration(vault, collateral, btcAddress)``

*Parameters*

* ``vault``: The account of the Vault to be registered.
* ``collateral``: to-be-locked collateral in DOT.

*Returns*

* ``None``

*Events*

* ``RegisterVault(Vault, collateral)``: emit an event stating that a new Vault (``vault``) was registered and provide information on the Vault's collateral (``collateral``). 

*Errors*

* ``ERR_MIN_AMOUNT``: The provided collateral was insufficient - it must be above ``MinimumCollateralVault``.
  
*Substrate* ::reservedTokens

  fn registerVault(origin, amount: Balance) -> Result {...}

Preconditions
.............

* The BTC Parachain status in the :ref:`security` component must be set to ``RUNNING:0``.

Function Sequence
.................

The ``registerVault`` function takes as input a Parachain AccountID, a Bitcoin address and DOT collateral, and registers a new Vault in the system.

1. Check that ``collateral > MinimumCollateralVault`` holds, i.e., the Vault provided sufficient collateral (above the spam protection threshold).

  a. Raise ``ERR_MIN_AMOUNT`` error if this check fails.

2. Store the provided data as a new ``Vault``.

3. **[Optional]**: generate a ``registrationID`` which the vault must be include in the OP_RETURN of a new BTC transaction spending BTC from the specified ``btcAddress``. This can be stored in a ``RegisterRequest`` struct, alongside the AccoundID (``vault``) and a timelimit in seconds.

4. Return.

proveValidBTCAddress (Optional)
-------------------------------

A vault optionally may be required to prove that the BTC address is provided during registration is indeed valid, by providing a transaction inclusion proof, showing BTC can be spent from the address.

Specification
.............

*Function Signature*

``proveValidBTCAddress(registrationID, txid, txBlockHeight, txIndex, merkleProof, transactionBytes)``

*Parameters*

* ``registrationID``: identifier of the RegisterRequest
* ``txid``: Hash identifier of the to-be-verified transaction
* ``txBlockHeight``: Block height at which transaction is supposedly included.
* ``txIndex``:  Index of transaction in the block’s tx Merkle tree.
* ``merkleProof``: Merkle tree path (concatenated LE sha256 hashes).
* ``transactionBytes``: Raw Bitcoin transaction 

*Returns*

* ``None``

*Events*

* ``ProveValidBTCAddress(vault, btcAddress)``: emit an event stating that a Vault (``vault``) submitted a proof that its BTC address is valid.

*Errors*

* ``ERR_INVALID_BTC_ADDRESS``: The provided collateral was insufficient - it must be above ``MinimumCollateralVault``.
* see ``verifyTransactionInclusion`` in BTC-Relay.  

*Substrate* ::

  fn proveValidBTCAddress(registrationID: U256, txid: H256, txBlockHeight: U256, txIndex: U256, merkleProof: String, transactionBytes: String) -> Result {...}

Preconditions
.............

* The BTC Parachain status in the :ref:`security` component must be set to ``RUNNING:0``.

Function Sequence
.................

1. Retrieve the ``RegisterRequest`` with the given ``registerID`` from ``RegisterRequests``.

  a) Throw ``ERR_INVALID_REGISTER_ID`` error if no active RegisterRequest ``registerID`` can be found in ``RegisterRequests``.

2. Call ``verifyTransactionInclusion(txid, txBlockHeight, txIndex, merkleProof)``. If this call returns an error, abort and return the error.

3. Call ``validateTransactionInclusion`` providing the ``rawTx``, ``registerID`` and the vault's Bitcoin address as parameters. If this call returns an error, abort and return the error.

4. Remove the ``RegisterRequest`` with the ``registerID`` from ``RegisterRequests``.

5. Emit a ``ProveValidBTCAddress`` event, setting the ``vault`` account identifier and the vault's Bitcoin address (``Vault.btcAddress``) as parameters. 


.. BEGIN COMMENT

.. 
  lockCollateral
  --------------

  The Vault locks an amount of collateral as a security against stealing the Bitcoin locked with it. 

  Specification
  .............

  *Function Signature*

  ``lockCollateral(Vault, collateral)``

  *Parameters*

  * ``Vault``: The account of the Vault locking collateral.
  * ``collateral``: to-be-locked collateral in DOT.

  *Returns*

  * ``True``: If the locking has completed successfully.
  * ``False``: Otherwise.

* ``None``: If the locking has completed successfully.

  * ``LockCollateral(Vault, newCollateral, totalCollateral, freeCollateral)``: emit an event stating how much new (``newCollateral``), total collateral (``totalCollateral``) and freely available collateral (``freeCollateral``) the Vault calling this function has locked.

  *Errors*

  * ``ERR_UNKOWN_VAULT``: The specified Vault does not exist. 

  *Substrate* ::

    fn lockCollateral(origin, amount: Balance) -> Result {...}

  User Story
  ..........

  An existing Vault calls ``lockCollateral`` to increase its DOT collateral in the system.


  Function Sequence
  .................

  1) Retrieve the ``Vault`` from ``Vaults`` with the specified AccoundId (``vault``).

    a) Raise ``ERR_UNKOWN_VAULT`` error if no such ``vault`` entry exists in ``Vaults``.

  2) Increase the ``collateral`` of the ``Vault``. 


  withdrawCollateral
  -------------------

  A Vault can withdraw its *free* collateral at any time, as long as there remains more collateral (*free or used in backing issued PolkaBTC*) than ``MinimumCollateralVault``. Collateral that is currently being used to back issued PolkaBTC remains locked until the Vault is used for a redeem request (full release can take multiple redeem requests).



  Specification
  .............

  *Function Signature*

  ``withdrawCollateral(vault, withdrawAmount)``

  *Parameters*

  * ``vault``: The account of the Vault withdrawing collateral.
  * ``withdrawAmount``: To-be-withdrawn collateral in DOT.

  *Returns*

  * ``True``: If sufficient free collateral is available and the withdrawal was successful.
  * ``False`` (or throws exception): Otherwise.

* ``None``: If sufficient free collateral is available and the withdrawal was successful.

  * ``WithdrawCollateral(Vault, withdrawAmount, totalCollateral)``: emit an event stating how much collateral was withdrawn by the Vault and total collateral a Vault has left.

  *Errors*

  * ``ERR_UNKOWN_VAULT``: The specified Vault does not exist. 
  * ``ERR_INSUFFICIENT_FREE_COLLATERAL``: The Vault is trying to withdraw more collateral than is currently free. 
  * ``ERR_MIN_AMOUNT``: The amount of locked collateral (free + used) needs to be above ``MinimumCollateralVault``.
  * ``ERR_UNAUTHRORIZED``: The caller of the withdrawal is not the specified Vault, and hence not authorized to withdraw funds.
    
  *Substrate* ::

    fn withdrawCollateral(origin, amount: Balance) -> Result {...}

  Preconditions
  .............

  .. todo:: Check security module status

  A Vault calls ``withdrawCollateral`` to withdraw some of its ``free`` collateral, i.e., not used to back issued PolkaBTC tokens. 

  Function Sequence
  .................

  1) Retrieve the ``Vault`` from ``Vaults`` with the specified AccoundId (``vault``).

    a) Raise ``ERR_UNKOWN_VAULT`` error if no such ``vault`` entry exists in ``Vaults``.

  2) Check that the caller of this function is indeed the specified ``Vault`` (AccoundId ``vault``). 

    a) Raise ``ERR_UNAUTHRORIZED`` error is the caller of this function is not the Vault specified for withdrawal.

  3) Check that ``Vault`` has sufficient free collateral: ``withdrawAmount <= (Vault.collateral - Vault.issuedTokens * SecureCollateralRate)``

    a) Raise ``ERR_INSUFFICIENT_FREE_COLLATERAL`` error if this check fails.

  4) Check that the remaining **total** (``free` + used) collateral is greated than ``MinimumCollateralVault`` (``Vault.collateral - withdrawAmount >= MinimumCollateralVault``)

    a) Raise ``ERR_MIN_AMOUNT`` if this check fails. The Vault must close its account if it wishes to withdraw collateral below the ``MinimumCollateralVault`` threshold, or request a Replace if some of the collateral is already used for issued PolkaBTC.

  5) Release the requested ``withdrawAmount`` of DOT collateral to the specified Vault's account (``vault`` AccountId) and deduct the collateral tracked for the Vault in ``Vaults``: ``Vault.collateral - withdrawAmount``, 

5. Release the requested ``withdrawAmount`` of DOT collateral to the specified Vault's account (``vault`` AccountId) and deduct the collateral tracked for the Vault in ``Vaults``: ``Vault.collateral - withdrawAmount``, 

6. Emit ``WithdrawCollateral`` event

7. Return.

.. _lockVault:

reserveTokens
-------------

Reserves a given amount of PolkaBTC tokens, i.e., the corresponding DOT collateral amount, calculated via :ref:`getExchangeRate`, is marked as "not free".
This function is called from the :ref:`requestIssue` and :ref:`requrestReplace` protocols and is necessary to prevent race conditions (multiple requests trying to use the same amount of collateral). 

.. 
   During an issue request function (:ref:`requestIssue`), a user must be able to assign a Vault to the issue request. As a Vault can be assigned to multiple issue requests, race conditions may occur. To prevent race conditions, a Vault's collateral is *reserved* when an ``IssueRequest`` is created - ``reservedTokens`` specifies how much PolkaBTC is to be issued (and the reserved collateral is then calculated based on :ref:`getExchangeRate`).
   This function further calculates the amount of collateral that will be assigned to the issue request.

Specification
.............

*Function Signature*

``reserveTokens(vault, tokens)``

*Parameters*

* ``vault``: The BTC Parachain address of the Vault.
* ``tokens``: The amount of PolkaBTC to be locked.

*Returns*

* ``btcAddress``: The Bitcoin address of the vault.

*Events*

* ``ReserveTokens(vaultId, issuedTokens)``

*Errors*

* ``ERR_EXCEEDING_VAULT_LIMIT``: The selected vault has not provided enough collateral to issue the requested amount.

*Substrate* ::

  fn reserveTokens(vault: AccountId, tokens: U256) -> Result {...}

Preconditions
.............

* The BTC Parachain status in the :ref:`security` component must be set to ``RUNNING:0``.

Function Sequence
.................

1.  Checks if the selected vault has locked enough collateral to cover the amount of PolkaBTC ``tokens`` to be issued. Throws and error if this checks fails. Otherwise, assigns the tokens to the vault.

    - Select the ``vault`` from the registry and get the ``vault.issuedTokens`` and ``vault.collateral``. 
    - Calculate how many tokens can be issued by multiplying the ``vault.collateral`` with the ``ExchangeRate`` (from the :ref:`oracle`) considering the ``GRANULARITY`` (from the :ref:`oracle`) and subtract the ``vault.issuedTokens``. Memorize the result as ``available_tokens``. 
    - Check if the ``available_tokens`` is greater than ``tokens``. If not enough ``available_tokens`` is free, throw ``ERR_EXCEEDING_VAULT_LIMIT``. Else, add ``tokens`` to ``vault.issuedTokens``.

2. Get the Bitcoin address of the vault as ``btcAddress``.
3. Return the ``btcAddress``.

.. _releaseVault:

unreserveTokens
---------------

.. todo:: add reference to replace function.

A Vault's committed tokens are unreserved when either an issue (:ref:`cancelIssue`) or redeem (:ref:`cancelRedeem`) request is cancelled due to a timeout (failure!).

Specification
.............

*Function Signature*

``unreserveTokens(vault, tokens)``

*Parameters*

* ``vault``: The BTC Parachain address of the Vault.
* ``tokens``: The amount of PolkaBTC to be unreserved.

*Returns*

* ``None``

*Events*

* ``UnreserveTokens(vault, tokens)``

*Errors*

* ``ERR_LESS_TOKENS_COMMITTED``: Throws if the requested amount of ``tokens`` exceed the ``issuedTokens`` by this vault.

*Substrate* ::

  fn unreserveTokens(vault: AccountId, tokens: U256) -> Result {...}

Preconditions
.............

* The BTC Parachain status in the :ref:`security` component must be set to ``RUNNING:0``.

.. todo:: Exclude a crashed exchange rate oracle failure from this - this call should be allowed even if we have no exchange rate, as it is only used in failed Issue and Replace, or in successful Redeem and Replace. The check for an up-an-running exchange rate oracle is handled separately in each of these protocols, if necessary.

.. todo:: I suppose it should always be possible to exit the system?

.. comment:: [Alexei] Unfortunately, not really. We need an up-and-running BTC-Relay to prevent Vaults from getting slashed when Redeem or Replace are triggered. 


Function Sequence
.................

1. Checks if the amount of ``tokens`` to be released is less or equal to the amount of ``vault.issuedTokens``. If not, throws ``ERR_LESS_TOKENS_COMMITTED``.

2. Subtracts ``tokens`` from ``vault.issuedTokens``.

3. Returns.

slashVault
----------

If a vault does not redeem a user's PolkaBTC within the given time limit, his collateral for that specific request should be taken away and transferred to the user as reimbursement.

Specification
.............

*Function Signature*

``slashVault(vault, user, amount)``

*Parameters*

* ``vault``: 
* ``user``:

*Returns*

* ``None``:

*Events*

* ``SlashVault``:

*Errors*

* ````:

*Substrate* ::

  fn slashVault(vault: AccountId, user: AccountId, amount: Balance) -> Result {...}

Precondition
............


Function Sequence
.................



Events
~~~~~~
Summary of events emitted by this component

Error Codes
~~~~~~~~~~~

``ERR_EXCEEDING_VAULT_LIMIT``

* **Message**: "Issue request exceeds vault collateral limit."
* **Function**: :ref:`requestIssue`
* **Cause**: The collateral provided by the vault combined with the exchange rate forms an upper limit on how much PolkaBTC can be issued. The requested amount exceeds this limit.

