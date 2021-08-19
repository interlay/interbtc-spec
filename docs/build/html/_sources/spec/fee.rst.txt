Fee
===

Overview
~~~~~~~~

The fee model crate implements the fee model outlined in :ref:`fee_model`.

Step-by-step
------------

1. Fees are paid by Users (e.g., during issue and redeem requests) and forwarded to a reward pool.
2. Fees are then split between incentivised network participants (i.e. Vaults).
3. Network participants can claim these rewards from the pool based on their stake.
4. Stake is determined by their participation in the network - through incentivized actions.
5. Rewards are paid in ``interBTC``.

Data Model
~~~~~~~~~~

Scalars (Fees)
--------------

.. _issueFee:

IssueFee
........

Issue fee share (configurable parameter, as percentage) that users need to pay upon issuing ``interBTC``. 

- Paid in ``interBTC``
- Initial value: 0.5%

.. _issueGriefingCollateral:

IssueGriefingCollateral
.......................

Issue griefing collateral as a percentage of the locked collateral of a Vault a user has to lock to issue ``interBTC``. 

- Paid in collateral
- Initial value: 0.005%

.. _refundFee:

RefundFee
.........

Refund fee (configurable parameter, as percentage) that users need to pay to refund overpaid ``interBTC``. 

- Paid in ``interBTC``
- Initial value: 0.5%

.. _redeemFee:

RedeemFee
.........

Redeem fee share (configurable parameter, as percentage) that users need to pay upon request redeeming ``interBTC``. 

- Paid in ``interBTC``
- Initial value: 0.5%

.. _premiumRedeemFee:

PremiumRedeemFee
................

Fee for users to premium redeem (as percentage). If users execute a redeem with a Vault flagged for premium redeem, they earn a premium slashed from the Vault’s collateral. 

- Paid in collateral
- Initial value: 5%

.. _punishmentFee:

PunishmentFee
.............

Fee (as percentage) that a Vault has to pay if it fails to execute redeem requests (for redeem, on top of the slashed value of the request).
The fee is paid in collateral based on the ``interBTC`` amount at the current exchange rate.

- Paid in collateral
- Initial value: 10%

.. _theftFee:

TheftFee
........

Fee (as percentage) that a reporter receives if another Vault commits theft.
The fee is paid in collateral taken from the liquidated Vault.

- Paid in collateral
- Initial value: 5%

.. _theftFeeMax:

TheftFeeMax
...........

Upper bound to the reward that can be payed to a reporter on success.
This is expressed in Bitcoin to ensure consistency between assets.

- Initial value: 0.1 BTC

.. _replaceGriefingCollateral:

ReplaceGriefingCollateral
.........................

Default griefing collateral as a percentage of the to-be-locked collateral of the new Vault, Vault has to lock to be replaced by another Vault.
This collateral will be slashed and allocated to the replacing Vault if the to-be-replaced Vault does not transfer BTC on time.

- Paid in collateral
- Initial value: 0.005%

Functions
~~~~~~~~~

distributeRewards
-----------------

Distributes fees among incentivised network participants.

Specification
.............

*Function Signature*

``distributeRewards(amount)``

*Preconditions*

* There MUST be at least one registered Vault OR a treasury account.

*Postconditions*

* If there are no registered funds, rewards MUST be sent to the treasury account.
* Otherwise, rewards MUST be distributed according to :ref:`reward_distributeReward`. 

.. _withdrawRewards:

withdrawRewards
---------------

A function that allows incentivised network participants to withdraw all earned rewards.

Specification
.............

*Function Signature*

``withdrawRewards(accountId, vaultId)``

*Parameters*

* ``accountId``: the account withdrawing ``interBTC`` rewards.
* ``vaultId``: the vault that generated ``interBTC`` rewards.

*Events*

* :ref:`withdrawRewardsEvent`

*Preconditions*

* The function call MUST be signed by ``accountId``.
* The BTC Parachain status in the :ref:`security` component MUST NOT be ``SHUTDOWN:2``.
* The ``accountId`` MUST have available rewards for ``interBTC``.

*Postconditions*

* The account's balance MUST increase by the available rewards.
* The account's withdrawable rewards MUST decrease by the withdrawn rewards.

Events
~~~~~~

.. _withdrawRewardsEvent:

WithdrawRewards
---------------

*Event Signature*

``WithdrawRewards(account, amount)``

*Parameters*

* ``account``: the account withdrawing rewards
* ``amount``: the amount of rewards withdrawn

*Functions*

* :ref:`withdrawRewards`
