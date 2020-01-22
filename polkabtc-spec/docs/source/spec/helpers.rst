Utils
=====

generateId
----------

Generates a unique ID using a nonce, the address of the transaction sender, and a random seed.

Specification
.............

*Function Signature*

``generateId(account)``

*Parameters*

* ``account``: 

*Returns*

* ``hash``:

*Substrate* ::

  fn generateId(account: AccountId) -> T::Hash {...}

Function Sequence
.................

1. Concatenate ``account``, ``Nonce``, and ``random_seed()``.
2. Hash the result of step 1.
3. Return the resulting hash.

.. todo:: Get ``Nonce`` from Security module 
