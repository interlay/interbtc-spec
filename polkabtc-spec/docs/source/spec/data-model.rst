Data Model
==========

The data model covers the necessary information to handle the issue and redeem process as well as the management of tokens, i.e. accounts and balances.

Global
~~~~~~

Constants
---------

- ``NAME``: ``PolkaBTC``
- ``SYMBOL``: ``pBTC``

Scalars
-------

TotalSupply
...........

The total supply of PolkaBTC.

*Substrate*: ``TotalSupply: Balance;``

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

ExchangeRate
............

The BTC to DOT exchange rate. This exchange rate determines how much collateral is required to issue a specific amount of PolkaBTC.

.. todo:: What granularity should we set here?

*Substrate*: ``ExchangeRate: u256;``

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


Maps
----

Balances
........

Mapping from accounts to their balance. ``<Account, Balance>``.

*Substrate*: ``Balances: map T::AccountId => Balance;``

Vaults
......

Mapping from accounts of vaults to their struct. ``<Account, Vault>``.

*Substrate*: ``Vaults map T::AccountId => Vault<T::AccountId, T::Balance, T::Moment>``

Structs
-------

Vault
.....

Stores the information of a vault.

==================  =========  ========================================================
Parameter           Type       Description
==================  =========  ========================================================
``vault``           Account    Account ID of the vault.
``committedTokens`` PolkaBTC   Number of tokens committed and issued to CbA Requesters (DOT).
``collateral``      DOT        Amount of backing collateral (DOT).
``replacement``     Account    Account ID of replacement vault.
``replace``         bool       True if vault wants to be replaced.
``replaceTime``     u256       Time at which replacement needs to be completed.
==================  =========  ========================================================

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


Issue Protocol
~~~~~~~~~~~~~~

Scalars
-------

CommitPeriod
............

The time difference in seconds between a commit request is created and required completion time by a CbA-Requester. The commit period has an upper limit to prevent grieving of vault collateral.

*Substrate*: ``CommitPeriod: Moment;``

Maps
----

Commits
.......

CbA-Requesters create commits to issue PolkaBTC. This mapping provides access from a ``CommitId`` to the ``Commit``. Mapping from a unique hash CommitId to a Commit. ``<CommitId, Commit>``.

*Substrate*: ``Commits map T::Hash => Commit<T::AccountId, Balance>``


Commit
......

Stores the status and information about a single commit.

==================  ==========  =======================================================	
Parameter           Type        Description                                            
==================  ==========  =======================================================
``vault``           Account     The vault responsible for this issue request.
``opentime``        u256        Timestamp of opening the request.
``collateral``      DOT         Collateral provided by a user.
``amount``          PolkaBTC    Amount of PolkaBTC to be issued.
``receiver``        Account     CbA-Requester account receiving PolkaBTC upon successful issuing.
``sender``          Account     CbA-Requester account receiving the refund of ``collateral``.
``btcPublicKey``    bytes[20]   Base58 encoded Bitcoin public key of the CbA-Requester.  
==================  ==========  =======================================================

*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Commit<AccountId, Balance, Moment> {
        vault: AccountId,
        opentime: Moment,
        collateral: Balance,
        amount: Balance,
        receiver: AccountId,
        sender: AccountId,
        btcPublicKey: Bytes
  }



