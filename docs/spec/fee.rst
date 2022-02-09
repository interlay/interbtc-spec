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

.. _fee_scalar_issue_fee:

IssueFee
........

Issue fee share (configurable parameter, as percentage) that users need to pay upon issuing ``interBTC``. 

- Paid in ``interBTC``
- Initial value: 0.5%

.. _fee_scalar_issue_griefing_collateral:

IssueGriefingCollateral
.......................

Issue griefing collateral as a percentage of the locked collateral of a Vault a user has to lock to issue ``interBTC``. 

- Paid in collateral
- Initial value: 0.005%

.. _fee_scalar_refund_fee:

RefundFee
.........

Refund fee (configurable parameter, as percentage) that users need to pay to refund overpaid ``interBTC``. 

- Paid in ``interBTC``
- Initial value: 0.5%

.. _fee_scalar_redeem_fee:

RedeemFee
.........

Redeem fee share (configurable parameter, as percentage) that users need to pay upon request redeeming ``interBTC``. 

- Paid in ``interBTC``
- Initial value: 0.5%

.. _fee_scalar_premium_redeem_fee:

PremiumRedeemFee
................

Fee for users to premium redeem (as percentage). If users execute a redeem with a Vault flagged for premium redeem, they earn a premium slashed from the Vault’s collateral. 

- Paid in collateral
- Initial value: 5%

.. _fee_scalar_punishment_fee:

PunishmentFee
.............

Fee (as percentage) that a Vault has to pay if it fails to execute redeem requests (for redeem, on top of the slashed value of the request).
The fee is paid in collateral based on the ``interBTC`` amount at the current exchange rate.

- Paid in collateral
- Initial value: 10%

.. _fee_scalar_theft_fee:

TheftFee
........

Fee (as percentage) that a reporter receives if another Vault commits theft.
The fee is paid in collateral taken from the liquidated Vault.

- Paid in collateral
- Initial value: 5%

.. _fee_scalar_theft_fee_max:

TheftFeeMax
...........

Upper bound to the reward that can be payed to a reporter on success.
This is expressed in Bitcoin to ensure consistency between assets.

- Initial value: 0.1 BTC

.. _fee_scalar_replace_griefing_collateral:

ReplaceGriefingCollateral
.........................

Default griefing collateral as a percentage of the to-be-locked collateral of the new Vault, Vault has to lock to be replaced by another Vault.
This collateral will be slashed and allocated to the replacing Vault if the to-be-replaced Vault does not transfer BTC on time.

- Paid in collateral
- Initial value: 0.005%

Functions
~~~~~~~~~

distribute_rewards
------------------

Distributes fees among incentivised network participants.

Specification
.............

*Function Signature*

``distribute_rewards(amount)``

*Preconditions*

* There MUST be at least one registered Vault OR a treasury account.

*Postconditions*

* If there are no registered funds, rewards MUST be sent to the treasury account.
* Otherwise, rewards MUST be distributed according to :ref:`reward_distributeReward`. 

.. _fee_function_withdraw_rewards:

withdraw_rewards
----------------

A function that allows incentivised network participants to withdraw all earned rewards.

Specification
.............

*Function Signature*

``withdraw_rewards(account_id, vault_id)``

*Parameters*

* ``account_id``: the account withdrawing ``interBTC`` rewards.
* ``vault_id``: the vault that generated ``interBTC`` rewards.

*Events*

* :ref:`fee_event_withdraw_rewards`

*Preconditions*

* The function call MUST be signed by ``account_id``.
* The BTC Parachain status in the :ref:`security` component MUST NOT be ``SHUTDOWN:2``.
* The ``account_id`` MUST have available rewards for ``interBTC``.

*Postconditions*

* The account's balance MUST increase by the available rewards.
* The account's withdrawable rewards MUST decrease by the withdrawn rewards.

Events
~~~~~~

.. _fee_event_withdraw_rewards:

WithdrawRewards
---------------

*Event Signature*

``WithdrawRewards(account, amount)``

*Parameters*

* ``account``: the account withdrawing rewards
* ``amount``: the amount of rewards withdrawn

*Functions*

* :ref:`fee_function_withdraw_rewards`
