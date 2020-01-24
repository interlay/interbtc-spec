Data Model
==========

.. todo:: This is duplicate. Remove as soon as all component data model are complete.

The data model covers the necessary information to handle the issue and redeem process as well as the management of tokens, i.e. accounts and balances.

Treasury
~~~~~~~~

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

Maps
----

Balances
........

Mapping from accounts to their balance. ``<Account, Balance>``.

*Substrate*: ``Balances: map T::AccountId => Balance;``

Oracle
~~~~~~

Scalars
-------

ExchangeRate
............

The BTC to DOT exchange rate. This exchange rate determines how much collateral is required to issue a specific amount of PolkaBTC.

.. todo:: What granularity should we set here?

*Substrate*: ``ExchangeRate: U256;``

Vaults
~~~~~~

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

IssueGriefingCollateral
.....................

The minimum collateral (DOT) a user needs to provide.

.. note:: Prevent grieving attacks against vaults.

*Substrate*: ``IssueGriefingCollateral: Balance;``


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

*Substrate*: ``ReplacePeriod: DateTime;``

Maps
----


Vaults
......

Mapping from accounts of vaults to their struct. ``<Account, Vault>``.

*Substrate*: ``Vaults map T::AccountId => Vault<T::AccountId, T::Balance, T::DateTime>``

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
  pub struct Vault<AccountId, Balance, DateTime> {
        vault: AccountId,
        committedTokens: Balance,
        collateral: Balance,
        replacement: AccountId,
        replace: bool,
        replacePeriod: DateTime
  }


Issue Protocol
~~~~~~~~~~~~~~


.. todo:: We need to handle replay attacks. Idea: include a short unique hash, e.g. the ``CommitId`` and the ``RedeemId`` in the BTC transaction in the ``OP_RETURN`` field. That way, we can check if it is the correct transaction.

.. todo:: The hash creation for ``CommitId`` and ``RedeemId`` must be unique. Proposal: use a combination of Substrate's ``random_seed()`` method together with a ``nonce`` and the ``AccountId`` of a CbA-Requester and CbA-Redeemer. 

.. warning:: Substrate's built in module to generate random data needs 80 blocks to actually generate random data.


Scalars
-------

CommitPeriod
............

The time difference in seconds between a commit request is created and required completion time by a CbA-Requester. The commit period has an upper limit to prevent grieving of vault collateral.

*Substrate*: ``CommitPeriod: DateTime;``

Maps
----

IssueRequests
.............

CbA-Requesters create issue requests to issue PolkaBTC. This mapping provides access from a unique hash ``IssueId`` to a ``Commit`` struct. ``<CommitId, Commit>``.

*Substrate*: ``IssueRequests map T::H256 => Commit<T::AccountId, T::Balance>``

Structs
-------

Commit
......

Stores the status and information about a single commit.

==================  ==========  =======================================================	
Parameter           Type        Description                                            
==================  ==========  =======================================================
``vault``           Account     The vault responsible for this commit request.
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
  pub struct Commit<AccountId, Balance, DateTime> {
        vault: AccountId,
        opentime: DateTime,
        collateral: Balance,
        amount: Balance,
        receiver: AccountId,
        sender: AccountId,
        btcPublicKey: Bytes
  }

Redeem Protocol
~~~~~~~~~~~~~~~

Scalars
-------

RedeemPeriod
............

The time difference in seconds between a redeem request is created and required completion time by a vault. The redeem period has an upper limit to enforce the vault to release the CbA-Redeemer's Bitcoin.

*Substrate*: ``RedeemPeriod: DateTime;``

Maps
----

RedeemRequests
..............

CbA-Redeemers create redeem requests to burn their PolkaBTC and receive BTC in return. This mapping provides access from a unique hash ``RedeemId`` to the ``Redeem`` struct. ``<RedeemId, Redeem>``.

*Substrate*: ``RedeemRequests map T::H256 => Redeem<T::AccountId, T::Balance, T::DateTime>;``

Structs
-------

Redeem
......

Stores the status and information about a single redeem request.

==================  ==========  =======================================================	
Parameter           Type        Description                                            
==================  ==========  =======================================================
``vault``           Account     The vault responsible for this redeem request.
``opentime``        u256        Timestamp of opening the request.
``amount``          PolkaBTC    Amount of PolkaBTC to be redeemed.
``redeemer``        Account     CbA-Redeemer account.
``btcPublicKey``    bytes[20]   Base58 encoded Bitcoin public key of the CbA-Redeemer.  
==================  ==========  =======================================================

*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Redeem<AccountId, Balance, DateTime> {
        vault: AccountId,
        opentime: DateTime,
        amount: Balance,
        redeemer: AccountId,
        btcPublicKey: Bytes
  }

