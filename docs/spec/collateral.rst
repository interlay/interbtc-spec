.. _collateral-module:

Collateral
==========

Overview
~~~~~~~~

There are two different kinds of collateral in use in the bridge. The first is the backing collateral that vaults use as insurance for issued wrapped tokens. Multiple backing collaterals are supported, but similarly to MakerDAO, each vault uses a single currency. If vault operators want to use multiple currencies, they have to register multiple vaults. It is possible to use `key derivation <https://substrate.dev/docs/en/knowledgebase/integrate/subkey#hd-key-derivation>`_ to run multiple vaults using a single mnemonic. When a vault is registered, they have to explicitly choose the used currency. In contrast, when interacting with vaults, the used collateral is implicit. For example, when a vault fails to execute a redeem request, the user will receive some amount of the vault's backing collateral. As such, the user might want to select a vault that uses their preferred currency.

The second type of collateral is griefing collateral. The currency used for this type of collateral is fixed and depends on the used network. This is the currency that is also used to pay transaction fees. For example, in Kusama transaction fees are always paid in

While collateral management is logically distinct from treasury management, they are both implemented using the same :ref:`currency` pallet. This pallet is used to (i) lock, (ii) release, and (iii) slash collateral of either users or vaults. It can only be accessed by other modules and not directly through external transactions.

Multi-Collateral
----------------

The parachain supports the usage of different currencies for usage as collateral. Which currencies are allowed is determined by governance - they have to explicitly white-list currencies to be able to be used as collateral. They also have to set the various safety thresholds for each currency. 

Vaults in the system are identified by a VaultId, which is essentially a (AccountId, CollateralCurrency, WrappedCurrency) tuple. Note the distinction between the AccountId and the VaultId. A vault operator can run multiple vaults using a the same AccountId but different collateral currencies (and thus VaultIds). Each vault is isolated from all others. This means that if vault operator has two running vaults using the same AccountId but different CollateralCurrencies, then if one of the vaults were to get liquidated, the other vaults remains untouched. The vault client manages all VaultIds associated with a given AccountId. Vault operators will be able to register new VaultIds through the UI, and the vault client will automatically start to manage these.

When a user requests an issue, it selects a single vault to issue with (this choice may be made automatically by the UI). However, since the wrapped token is fully fungible, it may be redeemed with any vault, even if that vault is using a different collateral currency. When redeeming, the user again selects a single vault to redeem with. If a vault fails to execute a redeem request, the user is able to either get back its wrapped token, or to get reimbursed in the vault's collateral currency. If the user prefers the latter, the choice of vault becomes relevant because it determines which currency is received in case of failure.

The WrappedCurrency part of the VaultId is currently always required to take the same value - in the future support for different wrapped currencies may be added.

.. note:: Please note that multi-collateral is a recent addition to the code, and the spec has not been fully updated .

Step-by-Step
------------

The protocol has three different "sub-protocols".

- **Lock**: Store a certain amount of collateral from a single entity (user or vault).
- **Unlock**: Transfer a certain amount of collateral back to the entity that paid it.
- **Slash**: Transfer a certain amount of locked collateral to a party that was damaged by the actions of another party.
