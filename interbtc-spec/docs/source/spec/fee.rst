Fee
===

Overview
~~~~~~~~

The fee model crate implements the fee model outlined in :ref:`fee_model`.


Step-by-step
------------

1. Fees are paid by Users (e.g., during issue and redeem requests) and forwarded to a reward pool.
2. Fees are then split between Vaults, Staked Relayers, Maintainers, and Collators.
3. Network participants can claim these rewards from the pool based on their stake.
4. Stake is determined by their participation in the network - through incentivized actions.
5. Rewards may be paid in multiple currencies.

Data Model
~~~~~~~~~~

Scalars (Fee Pools)
-------------------

ParachainFeePool
................

Tracks the balance of fees earned by the BTC-Parachain which are to be distributed across all Vault, Staked Relayer, Collator and Maintainer pools. 

VaultRewards
............

Tracks the fee share (in %) allocated to Vaults.

- Initial value: 77%

StakedRelayerRewards
....................

Tracks the fee share (in %) allocated to Staked Relayers.

- Initial value: 3%

CollatorRewards
...............

Tracks the fee share (in %) allocated to Collators (excl. Parachain transaction fees).

- Initial value: 0%

MaintainerRewards
.................

Tracks fee share (in %) allocated to Parachain maintainers. 

- Initial value: 20%

Scalars (Fees)
--------------

IssueFee
........

Issue fee share (configurable parameter, as percentage) that users need to pay upon execute issuing wrapped tokens. 

- Paid in wrapped tokens
- Initial value: 0.5%

IssueGriefingCollateral
.......................

Default griefing collateral as a percentage of the locked collateral of a vault a user has to lock to issue wrapped tokens. 

- Paid in collateral
- Initial value: 0.005%


.. _RedeemFee:

RedeemFee
.........

Redeem fee share (configurable parameter, as percentage) that users need to pay upon request redeeming wrapped tokens. 

- Paid in wrapped tokens
- Initial value: 0.5%

.. _PremiumRedeemFee:

PremiumRedeemFee
................

Fee for users to premium redeem (as percentage). If users execute a redeem with a Vault flagged for premium redeem, they earn a premium slashed from the Vault’s collateral. 

- Paid in collateral
- Initial value: 5%

.. _PunishmentFee:

PunishmentFee
.............

Fee (as percentage) that a vault has to pay if it fails to execute redeem requests (for redeem, on top of the slashed value of the request). The fee is paid in collateral based on the wrapped token amount at the current exchange rate.

- Paid in collateral
- Initial value: 10%

PunishmentDelay
...............

Time period in which a vault cannot participate in issue, redeem or replace requests.

- Measured in Parachain blocks
- Initial value: 1 day (Parachain constant)

.. _ReplaceGriefingCollateral:

ReplaceGriefingCollateral
.........................

Default griefing collateral as a percentage of the to-be-locked collateral of the new vault, vault has to lock to be replaced by another vault. This collateral will be slashed and allocated to the replacing Vault if the to-be-replaced Vault does not transfer BTC on time.

- Paid in collateral
- Initial value: 0.005%


Functions
~~~~~~~~~

distributeRewards
-----------------

Specifies the distribution of fees among incentivised network participants.


Specification
.............

*Function Signature*

``distributeRewards()``


Function Sequence
.................

1. Calculate the total fees for all Vaults using the `VaultRewards` percentage.
2. Calculate the total fees for all Staked Relayers using the `StakedRelayerRewards` percentage.
3. Calculate the total fees for all Collators using the `CollatorRewards` percentage.
4. Send the remaining fees to the Maintainer fund.


.. _withdrawRewards:

withdrawRewards
---------------

A function that allows Staked Relayers, Vaults and Collators to withdraw the fees earned.

Specification
.............

*Function Signature*

``withdrawRewards(account, currency, amount)``

*Parameters*

* ``account``: the account withdrawing rewards
* ``currency``: the currency of the reward to withdraw

*Events*

* ``WithdrawRewards(account, currency, amount)``

Function Sequence
.................

1. Compute the rewards based on the account's stake.
2. Transfer all rewards to the account.

Events
~~~~~~

WithdrawRewards
---------------

*Event Signature*

``WithdrawRewards(account, currency, amount)``

*Parameters*

* ``account``: the account withdrawing rewards
* ``currency``: the currency of the reward to withdraw
* ``amount``: the amount withdrawn

*Functions*

* :ref:`withdrawRewards`

