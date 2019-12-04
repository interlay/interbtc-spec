Data Model
==========

The data model covers the necessary information to handle the issue and redeem process as well as the management of tokens, i.e. accounts and balances.

Constants
---------

- ``NAME``: ``PolkaBTC``
- ``SYMBOL``: ``pBTC``

Scalars
-------

TotalSupply
...........

The total supply of PolkaBTC.

*Substrate*: ``TotalSupply: u256;``


Maps
----

Balances
........

Mapping from accounts to their balance. ``<Account, Balance>``.

*Substrate*: ``Balances: map T::AccountId => u256;``


Structs
-------

Vault
.....

Stores the information of a vault.

==============  ==============  ========================================================
Parameter       Type            Description
==============  ==============  ========================================================
vault           Account         Account ID of the vault.
tokenSupply     u256            Maximum token supply of this vault (PolkaBTC).
committedToken  u256            Number of tokens committed to CbA Requesters (PolkaBTC).
collateral      u256            Amount of backing collateral (DOT).
replacement     Account         Account ID of replacement vault.
replace         bool            True if vault wants to be replaced.
replacePeriod   u256            Period in which replacement vault needs to complete replacement.
==============  ==============  ========================================================

*Substrate*

::
       
  pub struct Vault<AccountId> {
        vault: AccountId,
        tokenSupply: u256,
        committedToken: u256,
        collateral: u256,
        replacement: AccountId,
        replace: bool,
        replacePeriod: u256
  }

More text here
