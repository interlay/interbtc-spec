.. _rewards:

Reward
======

Overview
~~~~~~~~

This pallet provides a way distribute rewards to any number of accounts, proportionally to their stake. It does so using the `Scalable Reward Distribution <https://solmaz.io/2019/02/24/scalable-reward-changing/>`_ algorithm. It does not directly transfer any rewards - rather, the stakeholders have to actively withdraw their accumulated rewards, which they can do at any time. Stakeholders can also change their stake at any time, without impacting the rewards gained in the past.

Invariants
~~~~~~~~~~

* For each ``currency_id``,

  * ``TotalStake[currency_id]`` MUST be equal to the sum of ``Stake[currency_id, account_id]`` over all accounts.
  * ``TotalReward[currency_id]`` MUST be equal to the sum of ``Stake[currency_id, account_id] * RewardPerToken[currency_id] - RewardTally[currency_id, account_id]`` over all accounts.
  * For each ``account_id``,
  
    * ``RewardTally[currency_id, account_id]`` MUST be smaller than or equal to ``Stake[currency_id, account_id] * RewardPerToken[currency_id]``
    *  ``Stake[currency_id, account_id]`` MUST NOT be negative
    * ``RewardTally[currency_id, account_id]`` MUST NOT be negative

Data Model
~~~~~~~~~~

Maps
----

TotalStake
..........

The total stake deposited to the reward with the given currency.

TotalRewards
............

The total unclaimed rewards in the given currency distributed to this reward pool. This value is currently only used for testing purposes.

RewardPerToken
..............

The amount of reward the stakeholders get for the given currency per unit of stake.

Stake
.....

The stake in the given currency for the given account.

RewardTally
...........

The amount of rewards in the given currency a given account has already withdrawn, plus a compensation that is added on stake changes.


Functions
~~~~~~~~~


.. _reward_function_get_total_rewards:

get_total_rewards
-----------------

This function gets the total amount of rewards distributed in the pool with the given currency_id.

Specification
.............

*Function Signature*

``get_total_rewards(currency_id)``

*Parameters*

* ``currency_id``: Determines of which currency the amount is returned. 

*Postconditions*

* The function MUST return the total amount of rewards that have been distributed in the given currency. 



.. _reward_function_deposit_stake:

deposit_stake
-------------

Adds a stake for the given account and currency in the reward pool.

Specification
.............

*Function Signature*

``deposit_stake(currency_id, account_id, amount)``

*Parameters*

* ``currency_id``: The currency for which to add the stake
* ``account_id``: The account for which to add the stake
* ``amount``: The amount by which the stake is to increase

*Events*

* :ref:`reward_event_deposit_stake`

*Preconditions*

*Postconditions*

* ``Stake[currency_id, account_id]`` MUST increase by ``amount``
* ``TotalStake[currency_id]`` MUST increase by ``amount``
* ``RewardTally[currency_id, account_id]`` MUST increase by ``RewardPerToken[currency_id] * amount``. This ensures the amount of rewards the given account_id can withdraw remains unchanged.



.. _reward_function_distribute_reward:

distribute_reward
-----------------

Distributes rewards to the stakeholders.

Specification
.............

*Function Signature*

``distribute_reward(currency_id, reward)``

*Parameters*

* ``currency_id``: The currency being distributed
* ``reward``: The amount being distributed

*Events*

* :ref:`reward_event_distribute_reward`


*Preconditions*

* ``TotalStake[currency_id]`` MUST NOT be zero.

*Postconditions*

* ``RewardPerToken[currency_id]`` MUST increase by ``reward / TotalStake[currency_id]``
* ``TotalRewards[currency_id]`` MUST increase by ``reward``



.. _reward_function_compute_reward:

compute_reward
--------------

Computes the amount a given account can withdraw in the given currency.

Specification
.............

*Function Signature*

``compute_reward(currency_id, account_id)``

*Parameters*

* ``currency_id``: The currency for which the rewards are being calculated
* ``account_id``: Account for which the rewards are being calculated.

*Postconditions*

* The function MUST return ``Stake[currency_id, account_id] * RewardPerToken[currency_id] - RewardTally[currency_id, account_id]``.



.. _reward_function_withdraw_stake:

withdrawStake
-------------

Decreases a stake for the given account and currency in the reward pool.

Specification
.............

*Function Signature*

``withdrawStake(currency_id, account_id, amount)``

*Parameters*

* ``currency_id``: The currency for which to decrease the stake
* ``account_id``: The account for which to decrease the stake
* ``amount``: The amount by which the stake is to decrease

*Events*

* :ref:`reward_event_withdraw_stake`

*Preconditions*

* ``amount`` MUST NOT be greater than ``Stake[currency_id, account_id]``

*Postconditions*

* ``Stake[currency_id, account_id]`` MUST decrease by ``amount``
* ``TotalStake[currency_id]`` MUST decrease by ``amount``
* ``RewardTally[currency_id, account_id]`` MUST decrease by ``RewardPerToken[currency_id] * amount``. This ensures the amount of rewards the given account_id can withdraw remains unchanged.



.. _reward_function_withdraw_reward:

withdraw_reward
---------------

Withdraw all available rewards of a given account and currency 

Specification
.............

*Function Signature*

``withdraw_reward(currency_id, reward)``

*Parameters*

* ``currency_id``: The currency being withdrawn
* ``account_id``: The account for which to withdraw the rewards

*Events*

* :ref:`reward_event_withdraw_reward`

*Preconditions*

* ``TotalStake[currency_id]`` MUST NOT be zero.

*Postconditions*

Let ``reward`` be the result :ref:`reward_function_compute_reward` when it is called with ``currency_id`` and ``account_id`` as arguments. Then:

* ``TotalRewards[currency_id]`` MUST decrease by ``reward``
* ``RewardPerToken[currency_id]`` MUST be set to ``RewardPerToken[currency_id] * Stake[currency_id, account_id]``



Events
~~~~~~

.. _reward_event_deposit_stake:

DepositStake
------------

*Event Signature*

``DepositStake(currency_id, account_id, amount)``

*Parameters*

* ``currency_id``: the currency for which the stake has been changed
* ``account_id``: the account for which the stake has been changed
* ``amount``: the increase in stake

*Functions*

* :ref:`reward_function_deposit_stake`



.. _reward_event_withdraw_stake:

WithdrawStake
---------------

*Event Signature*

``WithdrawStake(currency_id, account_id, amount)``

*Parameters*

* ``currency_id``: the currency for which the stake has been changed
* ``account_id``: the account for which the stake has been changed
* ``amount``: the decrease in stake

*Functions*

* :ref:`reward_function_withdraw_stake`


.. _reward_event_distribute_reward:

DistributeReward
----------------

*Event Signature*

``DistributeReward(currency_id, account_id, amount)``

*Parameters*

* ``currency_id``: the currency for which the reward has been withdrawn
* ``amount``: the distributed amount

*Functions*

* :ref:`reward_function_distribute_reward`


.. _reward_event_withdraw_reward:

WithdrawReward
---------------

*Event Signature*

``WithdrawReward(currency_id, account_id, amount)``

*Parameters*

* ``currency_id``: the currency for which the reward has been withdrawn
* ``account_id``: the account for which the reward has been withdrawn
* ``amount``: the withdrawn amount

*Functions*

* :ref:`reward_function_withdraw_reward`
