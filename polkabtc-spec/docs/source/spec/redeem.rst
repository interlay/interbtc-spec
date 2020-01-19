.. _redeem-protocol:

Redeem
======

Overview
~~~~~~~~

The redeem module allows a user to receive BTC on the Bitcoin chain in return for destroying an equivalent amount of PolkaBTC on the BTC Parachain. The process is initiated by a user requesting a redeem procedure by selecting a vault. The vault then needs to send BTC to the user within a given time limit. Next, the vault has to finalize the process by providing a proof to the BTC Parachain that he has send the right amount of BTC to the user. If the vault fails to deliver a valid proof, the user can claim an equivalent amount of DOT from the vault's locked collateral to reimburse him for his loss in BTC.

Step-by-step
------------

1. Precondition: A user owns PolkaBTC.
2. A user locks an amount of PolkaBTC by calling the ``lock`` function. Further, the user selects a vault to execute the redeem request from the list of vaults. The function creates a redeem request with a unique hash.
3. The selected vault listens for the ``Lock`` event issued by the user. The vault then proceeds to transfer BTC to the address specified by the user in the ``lock`` function including a unique hash in the ``OP_RETURN`` of one output.
4. The vault executes the ``redeem`` function by providing the Bitcoin transaction from step 3 together with the redeem request identifier within the time limit. If the function completes successfully, the locked PolkaBTC are destroyed and the user received its BTC. If the function is not successful, a user executes step 5.
5. If step 4 completed unsuccessfully, the user calls ``slash`` after the redeem time limit. The user is then refunded with the DOT collateral the vault provided.

Data Model
~~~~~~~~~~

Scalars
-------

RedeemPeriod
............

The time difference in number of blocks between a redeem request is created and required completion time by a vault. The redeem period has an upper limit to ensure the user gets his BTC in time and to potentially punish a vault for inactivity or stealing BTC.

*Substrate* ::

  RedeemPeriod: T::BlockNumber;

Maps
----

RedeemRequests
.............

Users create redeem requests to receive BTC in return for PolkaBTC. This mapping provides access from a unique hash ``redeemId`` to a ``Redeem`` struct. ``<redeemId, Redeem>``.

*Substrate* ::

  RedeemRequests map T::Hash => Redeem<T::AccountId, T::BlockNumber, T::Balance>


Structs
-------

Redeem
......

Stores the status and information about a single redeem request.

==================  ==========  =======================================================	
Parameter           Type        Description                                            
==================  ==========  =======================================================
``vault``           Account     The BTC Parachain address of the Vault responsible for this redeem request.
``opentime``        u256        Block height of opening the request.
``amount``          BTC         Amount of BTC to be redeemed.
``btcAddress``      bytes[20]   Base58 encoded Bitcoin public key of the User.  
``completed``       bool        Indicates if the redeem has been completed.
==================  ==========  =======================================================

*Substrate*

::
  
  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct Redeem<AccountId, BlockNumber, Balance> {
        vault: AccountId,
        opentime: BlockNumber,
        amount: Balance,
        btcAddress: H160,
        completed: bool
  }

.. _requestRedeem:

requestRedeem
--------------

A user requests to start the redeem procedure.

Specification
.............

*Function Signature*

``lock(redeemer, collateral, amount, btcPublicKey, vaults)``

*Parameters*

* ``redeemer``: address of the user triggering the redeem.
* ``collateral``: a small collateral to prevent griefing.
* ``amount``: the amount of PolkaBTC to destroy and BTC to receive.
* ``btcPublicKey``: the address to receive BTC.
* ``vault``: the vault selected for the redeem request.

*Returns*

* ``True``: 
* ``False``: Otherwise.

*Events*

* ````:

*Errors*

* ````:

*Substrate* ::

  fn lock(origin, ) -> Result {...}

User Story
..........


Function Sequence
.................

