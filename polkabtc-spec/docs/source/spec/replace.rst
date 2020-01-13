.. _replace-protocol:

Replace
=======

Overview
~~~~~~~~~


Step-by-Step
-------------

1. Precondition: a Vault has locked DOT collateral in the `Vault Registry <vault-registry>`_ and has issued PolkaBTC tokens, i.e., holds BTC on Bitcoin.

2. Vault1 submits replacement request, indicating how much BTC is to be migrated. 

3. A new candidate, Vault2, commits to executing the replacement by locking up the necessary DOT collateral to back the to-be-transferred BTC (according to the ``SecureCollateralRate``). 

4. Within a pre-defined delay, Vault1 must release the BTC on Bitcoin to Vault2's BTC address, and submit a valid transaction inclusion proof (call to ``verifyTransaction`` in BTC-Relay).

  a. Note: to prevent Vault1 trying to re-use old transactions (or other payments to Vault2 on Bitcoin) as fake proofs, we can require Vault1 to include a ``nonce`` in an OP_RETURN output of the transfer transaction.

5. If Vault1 releases the BTC to Vault2 correctly and submits the proof on time, Vault1's DOT collateral is released - Vault2 has now fully replaced Vault1.

6. **Optional**: Vault1 can be required to provide some additional DOT collateral as griefing protection, to prevent Vault1 from holding Vault2's DOT collateral locked in the BTC Parachain without ever finalizing the redeem protocol (transfer of BTC). 


Data Model
~~~~~~~~~~~

Scalars
-------

ReplaceGriefingCollateral (Optional)
.....................................

The minimum collateral (DOT) a Vault requesting a replacement needs to provide as griefing protection. 

.. note:: Requiring a Vault to add DOT collateral for executing replace may be a problem for Vaults which trigger this process due to low collateralization rates. We can potentially slash some of the Vault's existing collateral instead - this will result in reducing the collateralization rate and move the Vault closer to liquidation.

*Substrate*: ``ReplaceGriefingCollateral: Balance;``



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
.............

Vaults create replace requests if they want to have (a part of) their DOT collateral to be replaced by other Vaults. This mapping provides access from a unique hash ``ReplaceID`` to a ``Replace`` struct. ``<ReplaceID, Replace>``.

*Substrate* ::

  ReplaceRequests map T::Hash => Replace<T::AccountId, T::BlockNumber, T::Balance>


Structs
-------

Replace
........

Stores the status and information about a single replace request.

==================  ==========  =======================================================	
Parameter           Type        Description                                            
==================  ==========  =======================================================
``oldVault``        Account     BTC Parachain account of the Vault that is to be replaced.
``opentime``        u256        Block height of opening the request.
``amount``          PolkaBTC    Amount of BTC / PolkaBTC to be replaced.
``newVault``        Account     Account of the new Vault, which accepts the replace request.
``collateral``      DOT         DOT collateral locked by the new Vault.
``acceptTime``      u256        Block height at which this replace request was accepted by a new Vault. Serves as start for the countdown until when the old Vault must transfer the BTC.
``btcAddress``      bytes[20]   Base58 encoded Bitcoin public key of the new Vault.  
==================  ==========  =======================================================

.. note:: The ``btcAddress`` parameter is not to be set the the new Vault, but is extracted from the ``Vaults`` mapping in ``VaultRegistry`` for the account of the new Vault.  

*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Commit<AccountId, BlockNumber, Balance, H160>  {
        oldVault: AccountId,
        opentime: BlockNumber,
        amount: Balance,
        newVault: AccountId,
        collateral: Balance,
        acceptTime: BlockNumber,
        btcAddress: H160
  }

Functions
~~~~~~~~~


requestReplace
--------------

A Vault submits a request to be (partially) replaced. 


Specification
.............

*Function Signature*

``requestReplace(vault, btcAmount, timeout)``

*Parameters*

* ``vault``: Account identifier of the Vault to be replaced (as tracked in ``Vaults`` in :ref:`vault-registry`).
* ``btcAmount``: Integer amount of BTC / PolkaBTC to be replaced.
* ``timeout``: Time in blocks after which this request expires.

*Returns*

* ``replaceID``: A unique hash identifying the replace request. 

*Events*

* ``ReplaceRequest(vault, btcAmount, timeout, replaceId)``:

*Errors*


* ``ERR_MIN_AMOUNT``: The remaining DOT collateral (converted from the requested BTC replacement value given the current exchange rate) would be below the ``MinimumCollateralVault`` as defined in ``VaultRegistry``.
* ``ERR_UNAUTHORIZED``: The caller of the replace request is not the specified Vault, and hence not authorized to take this action.

*Substrate* ::

  fn requestReplace(origin, amount: U256, timeout: BlockNumber) -> Result {...}


Preconditions
...............

* The BTC Parachain status in the :ref:`failure-handling` component must be set to ``RUNNING:0``.

Function Sequence
.................

1. Check that caller of the function is indeed the to-be-replaced Vault. Return ``ERR_UNAUTHORIZED`` error if this check fails.

2. Retrieve the ``Vault`` as per the ``vault`` parameter from ``Vaults`` in the ``VaultRegistry``.

3. Check that the requested ``btcAmount`` is lower than ``Vault.committedTokens``.

  a. If ``btcAmount > Vault.committedTokens`` set ``btcAmount = Vault.committedTokens`` (i.e., the request is for the entire BTC holdings of the Vault).

4. If the request is not for the entire BTC holdings, check that the remaining DOT collateral of the Vault is higher than ``MinimumCollateralVault`` as defined in ``VaultRegistry``. Return ``ERR_MIN_AMOUNT`` error if this check fails.

4. Generate a ``replaceId`` by hashing a random seed, a nonce, and the address of the Requester.

5. Create new ``Replace`` entry:

   * ``Replace.oldVault = vault``,
   * ``Replace.opentime`` = current time on Parachain,
   * ``Replace.amount = amount``.
   
7. Emit ``ReplaceRequest(vault, btcAmount, timeout, replaceId)`` event.  


acceptReplace
--------------

A Vault accepts an existing replace request, locking the necessary DOT collateral.


Specification
.............

*Function Signature*

``acceptReplace(newVault, replaceId, collateral)``

*Parameters*

* ``newVault``: Accound identifier of the Vault accepting the replace request (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``repalceId``: The identifier of the replace request in ``ReplaceRequests``.
* ``collateral``: DOT collateral provided to match the replace request. Can be more than the necessary amount.

*Events*

* ``ReplaceAccepted(newVault, replaceId, collateral)``: emits an event stating which Vault (``newVault``) has accepted the ``Replace`` request (``requestId``), and how much collateral in DOT it provided (``collateral``).

*Errors*


* ``ERR_INVALID_REPLACE_ID``: The provided ``replaceId`` was not found in ``ReplaceRequests``.
* ``ERR_INSUFFICIENT_COLLATERAL``: The provided collateral is insufficient to match the replace request. 
* ``ERR_VAULT_NOT_FOUND``: The caller of the function was not found in the existing ``Vaults`` list in ``VaultRegistry``.

*Substrate* ::

  fn acceptReplace(origin, replaceId: Hash, collateral: Balance) -> Result {...}

Preconditions
...............

The BTC Parachain status in the :ref:`failure-handling` component must be set to ``RUNNING:0``.


Function Sequence
..................


1. Retrieve the ``Replace`` as per the ``replaceId`` parameter from ``Vaults`` in the ``VaultRegistry``. Return ``ERR_INVALID_REPLACE_ID`` error if no such ``Replace`` request was found.

2. Retrieve the ``Vault`` as per the ``newVault`` parameter from ``Vaults`` in the ``VaultRegistry``. Return``ERR_VAULT_NOT_FOUND`` error if no such Vault can be found.

3. Check that the provided ``collateral`` exceeds the necessary amount, i.e., ``collateral >= SecureCollateralRate * Replace.btcAmount``. Return``ERR_INSUFFICIENT_COLLATERAL`` error if this check fails.

4. Update the ``Replace`` entry:

  * ``Replace.newVault = newVault``,
  * ``Replace. acceptTime`` = current Parachain time, 
  * ``Replace.btcAddress = btcAddress`` (new Vault's BTC address),
  * ``Replace.collateral = collateral`` (DOT collateral locked by new Vault).

5. Emit a ``ReplaceAccepted(newVault, replaceId, collateral)`` event.


acceptReplace
--------------

A Vault accepts an existing replace request, locking the necessary DOT collateral.


Specification
.............

*Function Signature*

``acceptReplace(newVault, replaceId, collateral)``

*Parameters*

* ``newVault``: Accound identifier of the Vault accepting the replace request (as tracked in ``Vaults`` in :ref:`vault-registry`)
* ``repalceId``: The identifier of the replace request in ``ReplaceRequests``.
* ``collateral``: DOT collateral provided to match the replace request. Can be more than the necessary amount.

*Events*

* ``ReplaceAccepted(newVault, replaceId, collateral)``: emits an event stating which Vault (``newVault``) has accepted the ``Replace`` request (``requestId``), and how much collateral in DOT it provided (``collateral``).

*Errors*


* ``ERR_INVALID_REPLACE_ID``: The provided ``replaceId`` was not found in ``ReplaceRequests``.
* ``ERR_INSUFFICIENT_COLLATERAL``: The provided collateral is insufficient to match the replace request. 
* ``ERR_VAULT_NOT_FOUND``: The caller of the function was not found in the existing ``Vaults`` list in ``VaultRegistry``.

*Substrate* ::

  fn acceptReplace(origin, replaceId: Hash, collateral: Balance) -> Result {...}

Preconditions
...............

The BTC Parachain status in the :ref:`failure-handling` component must be set to ``RUNNING:0``.


Function Sequence
..................









