.. _vault-registry::

Vault Registry
==============

Data Model
~~~~~~~~~~

Scalars
-------

TotalCollateral
...............

The total collateral provided in DOT by vaults.

*Substrate*: ``TotalCollateral: Balance;``

TotalCommittedCollateral
........................

The total collateral committed to CbA requests and PolkaBTC.

.. note:: The difference of ``TotalCollateral`` and ``TotalCommittedCollateral`` quantifies how much free collateral is available. This free collateral can be used by CbA-Requesters to issue new PolkaBTC.

*Substrate*: ``TotalCommittedCollateral: Balance;``

MinimumCollateralVault
......................

The minimum collateral (DOT) a vault needs to provide to participate in the issue process.

.. note:: This is a protection against spamming the protocol with very small collateral amounts.

*Substrate*: ``MinimumCollateralVault: Balance;``

MinimumCollateralUser
.....................

The minimum collateral (DOT) a user needs to provide.

.. note:: Prevent grieving attacks against vaults.

*Substrate*: ``MinimumCollateralUser: Balance;``


SecureOperationLimit
....................

Determines how much collateral rate is required for *secure operation*. Needs to be strictly greater than ``100`` and ``BufferedOperationLimit``.

.. todo:: Insert link to security model.

*Substrate*: ``SecureOperationLimit: u16;``

BufferedOperationLimit
......................

Determines how much collateral rate is required for *buffered collateral*. Needs to be strictly greater than ``100``.

.. todo:: Insert link to security model.

*Substrate*: ``BufferedOperationLimit: u16;``

ReplacePeriod
.............

The time difference in seconds between a replacement vault indicates that it will replace a vault and required completion time by that vault.

*Substrate*: ``ReplacePeriod: Moment;``

Maps
----


Vaults
......

Mapping from accounts of vaults to their struct. ``<Account, Vault>``.

*Substrate*: ``Vaults map T::AccountId => Vault<T::AccountId, T::Balance, T::Moment>``

Structs
-------

Vault
.....

Stores the information of a vault.

.. todo:: Where are we storig the vaults BTC address? We need to verify that the user send the BTC to the correct address. Potentially there is a BTC address associated with a vault. When a CbA-Requester creates a ``Commit`` the BTC address of the vault is copied there and the user can prove that he sent the BTC there. This give sus the chance that a vault can update his BTC address, but we don't have to deal with that if it happens during ongoing issue requests. These BTC will still be received on the old address (in case of an update). Also the protocol remains non-interactive for the vault in this case.



===================  =========  ========================================================
Parameter            Type       Description
===================  =========  ========================================================
``vault``            Account    Account ID of the vault.
``committedTokens``  PolkaBTC   Number of tokens committed and issued to CbA Requesters (DOT).
``collateral``       DOT        Amount of backing collateral (DOT).
``replacement``      Account    Account ID of replacement vault.
``replace``          bool       True if vault wants to be replaced.
``replaceTime``      u256       Time at which replacement needs to be completed.
===================  =========  ========================================================

*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Vault<AccountId, Balance, Moment> {
        vault: AccountId,
        committedTokens: Balance,
        collateral: Balance,
        replacement: AccountId,
        replace: bool,
        replacePeriod: Moment
  }



Functions
~~~~~~~~~


lockCollateral
--------------

The Vault locks an amount of collateral as a security against stealing the Bitcoin locked with it. The Vault can take on issue requests depending on the collateral it provides and under consideration of the ``SecureOperationLimit``.
The maximum amount of PolkaBTC a Vault is able to support during the issue process is based on the following equation:
:math:`\text{max(PolkaBTC)} = \text{collateral} * \text{ExchangeRate} / \text{SecureOperationLimit}`.

.. note:: As an example, assume we use ``DOT`` as collateral, we issue ``PolkaBTC`` and lock ``BTC`` on the Bitcoin side. Let's assume the ``BTC``/``DOT`` exchange rate is ``80``, i.e. one has to pay 80 ``DOT`` to receive 1 ``BTC``. Further, the ``SecureOperationLimit`` is 200%, i.e. a Vault has to provide two-times the amount of collateral to back an issue request. Now let's say the Vault deposits 400 ``DOT`` as collateral. Then this Vault can back at most 2.5 PolkaBTC as: :math:`400 * (1/80) / 2 = 2.5`.

The details of the collateral limits are motivated in the `security specification <security>`_.

Specification
.............

*Function Signature*

``lockCollateral(vault, collateral)``

*Parameters*

* ``vault``: The account of the vault locking collateral.
* ``collateral``: The backing currency used for the collateral.

*Returns*

* ``True``: If the locking has completed successfully.
* ``False``: Otherwise.

*Events*

* ``LockCollateral(vault, collateral, totalCollateral)``: issue an event stating how much new and total collateral a vault has locked.

*Errors*

* ``ERR_INSUFFICIENT_FUNDS``: If a vault has insufficient funds to complete the transaction.
* ``ERR_MIN_AMOUNT``: The amount of to-be-locked collateral needs to be above a minimum amount.
  
*Substrate* ::

  fn lockCollateral(origin, amount: Balance) -> Result {...}

User Story
..........



Function Sequence
.................


Events
~~~~~~

Errors
~~~~~~

