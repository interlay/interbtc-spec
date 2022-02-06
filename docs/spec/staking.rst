.. _staking:

Staking
=======

Overview
~~~~~~~~

This pallet is very similar to the :ref:`rewards` pallet - it is also based on the `Scalable Reward Distribution <https://solmaz.io/2019/02/24/scalable-reward-changing/>`_ algorithm. The reward pallet keeps track of how much rewards vaults have earned. However, when nomination is enabled, there needs to be a way to relay parts of the vault's rewards to its nominators. Furthermore, the nominator's collaterals can be consumed, e.g., when a redeem is cancelled. This pallet is responsible for both tracking the rewards, and the current amount of contributed collaterals of vaults and nominators.

The idea is to have one reward pool per vault, where both the vault and all of its nominators have a stake equal to their contributed collateral. However, when collateral is consumed, either in :ref:`cancelRedeem` or :ref:`liquidateVault`, the collateral of each of these stakeholders should decrease proportionally to their stake. To be able to achieve this without iteration, in addition to tracking :ref:`staking_map_reward_per_token`, a similar value ``SlashPerToken`` is introduced. Similarly, in addition to :ref:`staking_map_reward_tally`, we now also maintain a ``SlashTally`` is for each stakeholder. When calculating a reward for a stakeholder, a compensated stake is calculated, based on ``Stake``, ``SlashPerToken`` and ``SlashTally``. 

When a vault opts out of nomination, all nominators should receive their collateral back. This is achieved by distributing all funds from the vault's shared collateral as rewards. However, a vault is free to opt back into nominator after having opted out. It is possible for the vault to do this before all nominators have withdrawn their reward. To ensure that the bookkeeping remains intact for the nominators to get their rewards at a later point, all variables are additionally indexed by a nonce, which increases every time a vault opts out of nomination. Effectively, this create a new pool for every nominated period.

.. note:: Most of the functions in this pallet that have a ``_at_index`` also have a version without this suffix that does not take a ``nonce`` argument, and instead uses the value stored in :ref:`Nonce`. For brevity, these functions without the suffix are omitted in this specification. 


Data Model
~~~~~~~~~~

Maps
----

TotalStake
..........

Maps ``(currency_id, nonce, vault_id)`` to the total stake deposited by the given vault and its nominators, with the given nonce and currency_id.

TotalCurrentStake
.................

Maps ``(currency_id, nonce, vault_id)`` to the total stake deposited by the given vault and its nominators, with the given nonce and currency_id, excluding stake that has been slashed.

TotalRewards
............

Maps ``(currency_id, nonce, vault_id)`` to the total rewards distributed to the vault and its nominators. This value is currently only used for testing purposes.

.. _staking_map_reward_per_token:

RewardPerToken
..............

Maps ``(currency_id, nonce, vault_id)`` to the amount of reward the vault and its nominators get per unit of stake.

.. _staking_map_reward_tally:

RewardTally
...........

Maps ``(currency_id, nonce, vault_id, nominator_id)`` to the reward tally the given nominator has for the given vault's reward pool, in the given nonce and currency. The tally influences how much the nominator can withdraw.

Stake
.....

Maps ``(currency_id, nonce, vault_id, nominator_id)`` to the stake the given nominator has in the given vault's reward pool, in the given nonce and currency. Initially, the stake is equal to its contributed collateral. However, after a slashing has occurred, the nominator's collateral must be compensated, using :ref:`staking_function_compute_stake_at_index`.

SlashPerToken
..............

Akin to :ref:`staking_map_reward_per_token`: maps ``(currency_id, nonce, vault_id)`` to the amount the vault and its nominators got slashed for per unit of stake. It is used for computing the effective stake (or equivalently, its collateral) in :ref:`staking_function_compute_stake_at_index`.


SlashTally
...........

Akin to :ref:`staking_map_reward_tally`: maps ``(currency_id, nonce, vault_id, nominator_id)`` to the slash tally the given nominator has for the given vault's reward pool, in the given nonce and currency. It is used for computing the effective stake (or equivalently, its collateral) in :ref:`staking_function_compute_stake_at_index`.

.. _Nonce:

Nonce
.....

Maps ``(currency_id, vault_id)`` current value of the nonce the given vault uses in the given currency. The nonce is increased every time :ref:`staking_function_force_refund` is called, i.e., when a vault opts out of nomination. Since nominators get their collateral back as a withdrawable reward, the bookkeeping must remain intact when the vault once again opts into nomination. By incrementing this nonce, effectively a new reward pool is created for the new session. All externally callable functions use the nonce stored in this map, except for the reward withdrawal function :ref:`staking_function_withdraw_reward_at_index`. 

Functions
~~~~~~~~~

.. _staking_function_deposit_stake:

deposit_stake
-------------

Adds a stake for the given account and currency in the reward pool.

Specification
.............

*Function Signature*

``depositStake(currency_id, vault_id, nominator_id, amount)``

*Parameters*

* ``currency_id``: The currency for which to add the stake
* ``vault_id``: Account of the vault
* ``nominator_id``: Account of the nominator
* ``amount``: The amount by which the stake is to increase

*Events*

* :ref:`staking_event_deposit_stake`

*Postconditions*

* ``Stake[currency_id, nonce, vault_id, nominator_id]`` MUST increase by ``amount``
* ``TotalStake[currency_id, nonce, vault_id]`` MUST increase by ``amount``
* ``TotalCurrentStake[currency_id, nonce, vault_id]`` MUST increase by ``amount``
* ``RewardTally[currency_id, nonce, vault_id, nominator_id]`` MUST increase by ``RewardPerToken[currency_id, nonce, vault_id] * amount``.
* ``SlashTally[currency_id, nonce, vault_id, nominator_id]`` MUST increase by ``SlashPerToken[currency_id, nonce, vault_id] * amount``.


.. _staking_function_withdraw_stake:

withdraw_stake
--------------

Withdraws the given amount stake for the given nominator or vault. This function also modifies the nominator's ``SlashTally`` and ``Stake``, such that the ``Stake`` is once again equal to its collateral. 

Specification
.............

*Function Signature*

``withdraw_stake(currency_id, vault_id, nominator_id, amount)``

*Parameters*

* ``currency_id``: The currency for which to add the stake
* ``vault_id``: Account of the vault
* ``nominator_id``: Account of the nominator
* ``amount``: The amount by which the stake is to decrease

*Events*

* :ref:`staking_event_withdraw_stake`

*Preconditions*

* Let ``nonce`` be ``Nonce[currency_id, vault_id]``, and
* Let ``stake`` be ``Stake[nonce, currency_id, vault_id, nominator_id]``, and
* Let ``slashPerToken`` be ``SlashPerToken[currency_id, nonce, vault_id]``, and
* Let ``slashTally`` be ``slashTally[nonce, currency_id, vault_id, nominator_id]``, and
* Let ``toSlash`` be ``stake * slashPerToken - slashTally``

Then:

* ``stake - toSlash`` MUST be greater than or equal to ``amount``

*Postconditions*

* Let ``nonce`` be ``Nonce[currency_id, vault_id]``, and
* Let ``stake`` be ``Stake[nonce, currency_id, vault_id, nominator_id]``, and
* Let ``slashPerToken`` be ``SlashPerToken[currency_id, nonce, vault_id]``, and
* Let ``slashTally`` be ``slashTally[nonce, currency_id, vault_id, nominator_id]``, and
* Let ``toSlash`` be ``stake * slashPerToken - slashTally``

Then:

* ``Stake[currency_id, nonce, vault_id, nominator_id]`` MUST decrease by ``toSlash + amount``
* ``TotalStake[currency_id, nonce, vault_id]`` MUST decrease by ``toSlash + amount``
* ``TotalCurrentStake[currency_id, nonce, vault_id]`` MUST decrease by ``amount``
* ``SlashTally[nonce, currency_id, vault_id, nominator_id]`` MUST be set to ``(stake - toSlash - amount) * slashPerToken``
* ``RewardTally[nonce, currency_id, vault_id, nominator_id]`` MUST decrease by ``rewardPerToken * amount`` 

.. _staking_function_slash_stake:

slash_stake
-----------

Slashes a vault's stake in the given currency in the reward pool. Conceptually, this decreases the stakes, and thus the collaterals, of all of the vault's stakeholders. Indeed, :ref:`staking_function_compute_stake_at_index` will reflect the stake changes on the stakeholder.

Specification
.............

*Function Signature*

``slash_stake(currency_id, vault_id, amount)``

*Parameters*

* ``currency_id``: The currency for which to add the stake
* ``vault_id``: Account of the vault
* ``amount``: The amount by which the stake is to decrease

*Preconditions*

* ``TotalStake[currency_id, Nonce[currency_id, vault_id], vault_id]`` MUST NOT be zero

*Postconditions*

Let ``nonce`` be ``Nonce[currency_id, vault_id]``, and ``initialTotalStake`` be ``TotalCurrentStake[currency_id, nonce, vault_id]``. Then:

* ``SlashPerToken[currency_id, nonce, vault_id]`` MUST increase by ``amount / TotalStake[currency_id, nonce, vault_id]``
* ``TotalCurrentStake[currency_id, nonce, vault_id]`` MUST decrease by ``amount``
* if ``initialTotalStake - amount`` is NOT zero, ``RewardPerToken[currency_id, nonce, vault_id]`` MUST increase by ``RewardPerToken[currency_id, nonce, vault_id] * amount / (initialTotalStake - amount)``

.. _staking_function_compute_stake_at_index:

compute_stake_at_index
----------------------

Computes a vault's stakeholder's effective stake. This is also the amount collateral that belongs to the stakeholder.

Specification
.............

*Function Signature*

``compute_stake_at_index(nonce, currency_id, vault_id, amount)``

*Parameters*

* ``nonce``: The nonce to compute the stake at
* ``currency_id``: The currency for which to compute the stake
* ``vault_id``: Account of the vault
* ``nominator_id``: Account of the nominator

*Postconditions*

Let ``stake`` be ``Stake[nonce, currency_id, vault_id, nominator_id]``, and
Let ``slashPerToken`` be ``SlashPerToken[currency_id, nonce, vault_id]``, and
Let ``slashTally`` be ``slashTally[nonce, currency_id, vault_id, nominator_id]``, then

* The function MUST return ``stake - stake * slash_per_token + slash_tally``.



.. _staking_function_distribute_reward:

distributeReward
----------------

Distributes rewards to the vault's stakeholders.

Specification
.............

*Function Signature*

``distributeReward(currency_id, reward)``

*Parameters*

* ``currency_id``: The currency being distributed
* ``vault_id``: the vault for which distribute rewards
* ``reward``: The amount being distributed

*Events*

* :ref:`staking_event_distribute_reward`

*Postconditions*

Let ``nonce`` be ``Nonce[currency_id, vault_id]``, and
Let ``initialTotalCurrentStake`` be ``TotalCurrentStake[currency_id, nonce, vault_id]``, then:


* If ``initialTotalCurrentStake`` is zero, or if ``reward`` is zero, then:
  
  * The function MUST return zero.

* Otherwise (if ``initialTotalCurrentStake`` and ``reward`` are not zero), then:

  * ``RewardPerToken[currency_id, nonce, vault_id)]`` MUST increase by ``reward / initialTotalCurrentStake``
  * ``TotalRewards[currency_id, nonce, vault_id]`` MUST increase by ``reward``
  * The function MUST return ``reward``.



.. _staking_function_compute_reward_at_index:

compute_reward_at_index
-----------------------

Calculates the amount of rewards the vault's stakeholder can withdraw.

Specification
.............

*Function Signature*

``compute_reward_at_index(nonce, currency_id, vault_id, amount)``

*Parameters*

* ``nonce``: The nonce to compute the stake at
* ``currency_id``: The currency for which to compute the stake
* ``vault_id``: Account of the vault
* ``nominator_id``: Account of the nominator

*Postconditions*
  
Let ``stake`` be the result of ``compute_stake_at_index(nonce, currency_id, vault_id, nominator_id)``, then:
Let ``rewardPerToken`` be ``RewardPerToken[currency_id, nonce, vault_id]``, and
Let ``rewardTally`` be ``rewardTally[nonce, currency_id, vault_id, nominator_id]``, then

* The function MUST return ``max(0, stake * rewardPerToken - reward_tally)``

.. _staking_function_withdraw_reward_at_index:

withdraw_reward_at_index
------------------------

Withdraws the rewards the given vault's stakeholder has accumulated.

Specification
.............

*Function Signature*

``withdraw_reward_at_index(currency_id, vault_id, amount)``

*Parameters*

* ``nonce``: The nonce to compute the stake at
* ``currency_id``: The currency for which to compute the stake
* ``vault_id``: Account of the vault
* ``nominator_id``: Account of the nominator

*Events*

* :ref:`staking_withdrawRewardEvent`

*Preconditions*

* :ref:`staking_function_compute_reward_at_index` MUST NOT return an error

*Postconditions*
  
Let ``reward`` be the result of ``compute_reward_at_index(nonce, currency_id, vault_id, nominator_id)``, then:
Let ``stake`` be ``Stake(nonce, currency_id, vault_id, nominator_id)``, then:
Let ``rewardPerToken`` be ``RewardPerToken[currency_id, nonce, vault_id]``, and

* ``TotalRewards[currency_id, nonce, vault_id]`` MUST decrease by ``reward``
* ``RewardTally[currency_id, nonce, vault_id, nominator_id]`` MUST be set to ``stake * rewardPerToken``
* The function MUST return ``reward``

.. _staking_function_force_refund:

force_refund
------------

This is called when the vault opts out of nomination. All collateral is distributed among the stakeholders, after which the vault withdraws his part immediately.

Specification
.............

*Function Signature*

``force_refund(currency_id, vault_id)``

*Parameters*

* ``currency_id``: The currency for which to compute the stake
* ``vault_id``: Account of the vault

*Events*

* :ref:`staking_event_force_refund`
* :ref:`staking_event_increase_nonce`

*Preconditions*

Let ``nonce`` be ``Nonce[currency_id, vault_id]``, then:

* ``distributeReward(currency_id, vault_id, TotalCurrentStake[currency_id, nonce, vault_id])`` MUST NOT return an error
* ``withdrawRewardAtIndex(nonce, currency_id, vault_id, vault_id)`` MUST NOT return an error
* ``depositStake(currency_id, vault_id, vault_id, reward)`` MUST NOT return an error
* ``Nonce[currency_id, vault_id]`` MUST be increased by 1

*Postconditions*
  
Let ``nonce`` be ``Nonce[currency_id, vault_id]``, then:

* ``distributeReward(currency_id, vault_id, TotalCurrentStake[currency_id, nonce, vault_id])`` MUST have been called
* ``withdrawRewardAtIndex(nonce, currency_id, vault_id, vault_id)`` MUST have been called
* ``Nonce[currency_id, vault_id]`` MUST be increased by 1
* ``depositStake(currency_id, vault_id, vault_id, reward)`` MUST have been called AFTER having increased the nonce

.. _staking_event_deposit_stake:

DepositStake
---------------

*Event Signature*

``DepositStake(currency_id, vault_id, nominator_id, amount)``

*Parameters*

* ``currency_id``: The currency of the reward pool
* ``vault_id``: Account of the vault
* ``nominator_id``: Account of the nominator
* ``amount``: The amount by which the stake is to increase

*Functions*

* :ref:`staking_function_deposit_stake`



.. _staking_event_withdraw_stake:

WithdrawStake
---------------

*Event Signature*

``WithdrawStake(currency_id, vault_id, nominator_id, amount)``

*Parameters*

* ``currency_id``: The currency of the reward pool
* ``vault_id``: Account of the vault
* ``nominator_id``: Account of the nominator
* ``amount``: The amount by which the stake is to increase

*Functions*

* :ref:`staking_function_withdraw_stake`



.. _staking_event_distribute_reward:

DistributeReward
----------------

*Event Signature*

``DistributeReward(currency_id, vault_id, amount)``

*Parameters*

* ``currency_id``: The currency of the reward pool
* ``vault_id``: Account of the vault
* ``amount``: The amount by which the stake is to increase

*Functions*

* :ref:`staking_function_distribute_reward`



.. _staking_withdrawRewardEvent:

WithdrawReward
--------------

*Event Signature*

``WithdrawReward(currency_id, vault_id, nominator_id, amount)``

*Parameters*

* ``currency_id``: The currency of the reward pool
* ``vault_id``: Account of the vault
* ``nominator_id``: Account of the nominator
* ``amount``: The amount by which the stake is to increase

*Functions*

* :ref:`staking_function_withdraw_reward_at_index`



.. _staking_event_force_refund:

ForceRefund
-----------

*Event Signature*

``ForceRefund(currency_id, vault_id)``

*Parameters*

* ``currency_id``: The currency of the reward pool
* ``vault_id``: Account of the vault

*Functions*

* :ref:`staking_function_force_refund`


.. _staking_event_increase_nonce:

IncreaseNonce
-------------

*Event Signature*

``IncreaseNonce(currency_id, vault_id, nominator_id, amount)``

*Parameters*

* ``currency_id``: The currency of the reward pool
* ``vault_id``: Account of the vault
* ``amount``: The amount by which the stake is to increase

*Functions*

* :ref:`staking_function_force_refund`
