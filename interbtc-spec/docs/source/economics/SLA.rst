.. _service_level_agreements:

Service Level Agreements
========================

Vaults take up a critical role in the BTC-Parachain. They provide collateral, have clearly defined tasks and face punishment in case of misbehavior. However, slashing collateral for each minor protocol deviation would result in too high risk profiles for Vaults, yielding these roles unattractive to users.

As a result, we introduce Service Level Agreements for Vaults: being online and following protocol rules increases the SLA, while non-critical failures reduces the rating. Higher SLAs result in higher rewards and preferred treatment where applicable in the Issue and Redeem protocols.

SLA Value
~~~~~~~~~

The SLA value is a number between 0 and 100. When a Vault registers with the BTC-Parachain, it starts with an SLA of 0.

SLA Actions
~~~~~~~~~~~

We list below several actions that Vaults can execute in the protocol that have an impact on their SLA.

Vaults
------

Desired Actions
...............

- **Execute Issue**: execute redeem, on time with the correct amount.
- **Submit Issue Proof**: Vault submits correct Issue proof on behalf of the user.
- **Forward Additional BTC**: Vault submits correct issue or return proof where the vault is the forwarding vault.
- **Submit BTC block header**: submit a valid Bitcoin block header, that later becomes (**TODO:**define delay to not punish "good" fork submissions) part of the main chain. 
  - [Optional]: even if the block header already is stored, an additional confirmation is treated as beneficial action. This needs to be **time-bounded**. Otherwise, resubmitting old blocks allows to improve SLA, while adding no security and spamming the Parachain)
- **Correctly report theft**: correctly report a Vault for moving BTC outside of the protocol rules (i.e., viewed as theft attempt). 
  - Note: TX inclusion proof must pass (TODO: check how this is currently implemented). 

Undesired Actions
.................

- **Fail Redeem**: redeem not executed on time (or at all) or with the incorrect amount (more specific: fail to provide inclusion proof for BTC payment to BTC-Relay on time)

Non-SLA Actions
~~~~~~~~~~~~~~~

There are several other actions that do not impact the SLA scores at the moment.
For completeness, we list them here. The SLA model might be revised and the below actions may be considered to impact the SLA in the future.

Vaults
------

Desired Actions
...............

- **Execute Redeem**: execute redeem, on time with the correct amount.
- **Collateralization**: Maintain a collateralization rate above the *Secure Collateral Threshold*. 
- **Execute Replace**: if requested replace, transfer the correct amount of BTC to the new Vault on time.

Undesired Actions
.................

- **Fail Replace**: replace protocol (BTC transfer) not executed on time (or at all) or with the incorrect amount.
- **Undercollateralization**: Collateralization rate below  *Secure Collateral Threshold*. 
- **Strong Undercollateralization**:  Collateralization rate below  *Premium Collateral Threshold*. 
- **Liquidation**:   Collateralization rate below  *Liquidation Collateral Threshold*, which triggers liquidation of the Vault.
- **Theft**: the Vault transfers BTC from its UTXO(s) outside of the protocol rules. There is a dedicated check for this in the BTC-Parachain: only redeem, replace and registered migration of assets are allowed and these are clearly defined. 
- **Repeated Failed Redeem**: repeated failed redeem requests can incur a higher SLA deduction#
- **Repeated Failed Replace**: repeated failed replace requests can incur a higher SLA deduction
