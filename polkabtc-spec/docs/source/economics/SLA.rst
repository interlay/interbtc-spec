.. _service_level_agreements:

Service Level Agreements
========================

Vaults and Staked Relayers take up critical roles in the BTC-Parachain. Both provide collateral, have clearly defined tasks and face punishment in case of misbehavior. However, slashing collateral for each minor protocol deviation would result in too high risk profiles for Vaults and Staked Relayers, yielding these roles unattractive to users.

As a result, we introduce Service Level Agreements for Vaults and Staked Relayers: being online and following protocol rules increases the SLA, while non-critical failures reduces the rating. Higher SLAs result in higher rewards and preferred treatment where applicable in the Issue and Redeem protocols. If the SLA of a Vault or Staked Relayer falls below a certain threshold, a punishment will be incurred, ranging from a mere collateral penalty up to full collateral confiscation and a system ban.

SLA Value
~~~~~~~~~

The SLA value is a number between 0 and 100. When a Vault or Staked Relayer registers with BTC-Parachain, it starts with an SLA of 0.

SLA Actions
~~~~~~~~~~~

We list below several actions that Vaults and Staked Relayers can execute in the protocol that have an impact on their SLA.

Vaults
------

Desired Actions
...............

- **Execute Issue**: execute redeem, on time with the correct amount.
- **Submit Issue Proof**: Vault submits correct Issue proof on behalf of the user.
- **Forward Additional BTC**: Vault submits correct issue or return proof where the vault is the forwarding vault.
 

Undesired Actions
.................

- **Fail Redeem**: redeem not executed on time (or at all) or with the incorrect amount (more specific: fail to provide inclusion proof for BTC payment to BTC-Relay on time)



Staked Relayers
---------------

Desired Actions
...............

Undesired Actions
.................

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
- **Auction Replace**: force-replace an undercollateralized Vault in an Auction

Undesired Actions
.................

- **Fail Replace**: replace protocol (BTC transfer) not executed on time (or at all) or with the incorrect amount.
- **Undercollateralization**: Collateralization rate below  *Secure Collateral Threshold*. 
- **Strong Undercollateralization**:  Collateralization rate below  *Premium Collateral Threshold*. 
- **Critical Undercollateralization**:  Collateralization rate below  *Auction Collateral Threshold*.
- **Liquidation**:   Collateralization rate below  *Liquidation Collateral Threshold*, which triggers liquidation of the Vault.
- **Theft**: the Vault transfers BTC from its UTXO(s) outside of the protocol rules. There is a dedicated check for this in the BTC-Parachain: only redeem, replace and registered migration of assets are allowed and these are clearly defined. 
- **Repeated Failed Redeem**: repeated failed redeem requests can incur a higher SLA deduction#
- **Repeated Failed Replace**: repeated failed replace requests can incur a higher SLA deduction



Staked Relayers
---------------

Desired Actions
...............

Undesired Actions
.................

