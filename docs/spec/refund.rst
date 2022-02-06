.. _refund-protocol:

Refund
======

Overview
~~~~~~~~

The Refund module is a user failsafe mechanism. In case a user accidentally locks more Bitcoin than the actual issue request, the refund mechanism seeks to ensure that either (1) the initial issue request is increased to issue more interBTC or (2) the BTC are returned to the sending user.  

Step-by-step
------------

If a user falsely sends additional BTC (i.e., :math:`|\text{BTC}| > |\text{interBTC}|`) during the issue process:

1. **Case 1: The originally selected vault has sufficient collateral locked to cover the entire BTC amount sent by the user**:
    a. Increase the issue request interBTC amount and the fee to reflect the actual BTC amount paid by the user.
    b. As before, issue the interBTC to the user and forward the fees.
    c. Emit an event that the issue amount was increased.
2. **Case 2: The originally selected vault does NOT have sufficient collateral locked to cover the additional BTC amount sent by the user**:
    a. Automatically create a return request from the issue module that includes a return fee (deducted from the originial BTC payment) paid to the vault returning the BTC.
    b. The vault fulfills the return request via a transaction inclusion proof (similar to execute issue). However, this does not create new interBTC.

.. note:: Only case 2 is handled in this module. Case 1 is handled directly by the issue module.

.. note:: Normally, enforcing actions by a vault is achieved by locking collateral of the vault and slashing the vault in case of misbehavior. In the case where a user sends too many BTC and the vault does not have enough “free” collateral left, we cannot lock more collateral. However, the original vault cannot move the additional BTC sent as this would be flagged as theft and the vault would get slashed. The vault can possibly take the overpaid BTC though if the vault would not be backing any interBTC any longer (e.g. due to redeem/replace).


Security
--------

- Unique identification of Bitcoin payments: :ref:`op-return`

Data Model
~~~~~~~~~~

Scalars
-------

.. _refund_scalar_btc_dust_value:

RefundBtcDustValue
..................

The minimum amount of BTC that is required for refund requests; lower values would risk the rejection of payment on Bitcoin.

Maps
----

.. _refund_map_refund_requests:

RefundRequests
..............

Overpaid issue payments create refund requests to return BTC. This mapping provides access from a unique hash ``RefundId`` to a ``Refund`` struct. ``<RefundId, Refund>``.

Structs
-------

Refund
......

Stores the status and information about a single refund request.

.. tabularcolumns:: |l|l|L|

======================  ============  =======================================================	
Parameter               Type          Description                                            
======================  ============  =======================================================
``vault``               AccountId     The account of the Vault responsible for this request.
``amount_btc``          Balance       Amount of interBTC to be refunded.
``fee``                 Balance       Fee charged to the user for refunding.
``transfer_fee_btc``    Balance       Amount subtracted for the Bitcoin inclusion fee.
``issuer``              AccountId     Account that overpaid on issue.
``btc_address``         BtcAddress    User's Bitcoin address.
``issue_id``            H256          The id of the issue request.
``completed``           bool          True if the refund was processed successfully.
======================  ============  =======================================================


External Functions
~~~~~~~~~~~~~~~~~~

.. _refund_function_execute_refund:

execute_refund
--------------

This function finalizes a refund, also referred to as a user failsafe. 
It is typically called by the vault client that performed the refund.

Specification
.............

*Function Signature*

``execute_refund(caller, refund_id, raw_merkle_proof, raw_tx)``

*Parameters*

* ``caller``: address of the user finalizing the refund. Typically the vault client that performed the refund.
* ``refund_id``: the unique hash created during the internal :ref:`refund_function_request_refund` function.
* ``raw_merkle_proof``: raw Merkle tree path (concatenated LE SHA256 hashes).
* ``raw_tx``: raw Bitcoin transaction of the refund payment, including the transaction inputs and outputs.

*Events*

* :ref:`refund_event_execute_refund`

*Preconditions*

* The function call MUST be signed by *someone*, i.e., not necessarily the Vault that performed the refund.
* The BTC Parachain status in the :ref:`security` component MUST NOT be set to ``SHUTDOWN:2``.
* A *pending* ``RefundRequest`` MUST exist with an id equal to ``refund_id``.
* ``refundRequest.completed`` MUST be ``false``.
* The ``raw_tx`` MUST decode to a valid transaction that transfers the amount specified in the ``RefundRequest`` struct. It MUST be a transaction to the correct address, and provide the expected OP_RETURN, based on the ``RefundRequest``.
* The ``raw_merkle_proof`` MUST be valid and prove inclusion to the main chain.
* The ``vault.status`` MUST be ``active``.
* The refunding vault MUST have enough collateral to mint an amount equal to the refund fee.

*Postconditions*

* The ``vault.issuedTokens`` MUST increase by ``fee``.
* The vault's free balance in wrapped currency MUST increase by ``fee``.
* ``refundRequest.completed`` MUST be ``true``.


Internal Functions
~~~~~~~~~~~~~~~~~~

.. _refund_function_request_refund:

request_refund
--------------

Used to request a refund if too much BTC was sent to a Vault by mistake. 

Specification
.............

*Function Signature*

``request_refund(amount, vault, issuer, btc_address, issue_id)``

*Parameters*

* ``amount``: the amount that the user has overpaid.
* ``vault``: id of the vault the issue was made to.
* ``issuer``: id of the user that made the issue request.
* ``btc_address``: the btc address that should receive the refund.
* ``issue_id``: corresponding issue request which was overpaid.

*Events*

* :ref:`refund_event_request_refund`

*Preconditions*

* The function call MUST only be called by :ref:`executeIssue`.
* The BTC Parachain status in the :ref:`security` component MUST NOT be set to ``SHUTDOWN:2``.
* The ``amount - fee`` MUST be greater than or equal to :ref:`refund_scalar_btc_dust_value`.
* A new unique ``refund_id`` MUST be generated via the :ref:`generateSecureId` function.

*Postconditions*

* The new refund request MUST be created as follows:

    * ``refund.vault``: MUST be the ``vault``.
    * ``refund.amountWrapped``: MUST be the ``amount - fee``
    * ``refund.fee``: MUST equal ``amount`` multiplied by :ref:`refundFee`.
    * ``refund.amountBtc``: MUST be the ``amount``.
    * ``refund.issuer``: MUST be the ``issuer``.
    * ``refund.btc_address``: MUST be the ``btc_address``. 
    * ``refund.issue_id``: MUST be the ``issue_id``.
    * ``refund.completed``: MUST be false.

* The new refund request MUST be inserted into :ref:`refund_map_refund_requests` using the generated ``refund_id`` as the key.


Events
~~~~~~

.. _refund_event_request_refund:

RequestRefund
-------------

*Event Signature*

``RequestRefund(refund_id, issuer, amount, vault, btc_address, issue_id, fee)``

*Parameters*

* ``refund_id``: A unique hash created via :ref:`generateSecureId`.
* ``issuer``: The user's account identifier.
* ``amount``: The amount of interBTC overpaid.
* ``vault``: The address of the Vault involved in this refund request.
* ``issue_id``: The unique hash created during :ref:`requestIssue`.
* ``fee``: The amount of interBTC to mint as fees.

.. _refund_event_execute_refund:

ExecuteRefund
-------------

*Event Signature*

``ExecuteRefund(refund_id, issuer, vault, amount, fee)``

*Parameters*

* ``refund_id``: The unique hash created during via :ref:``refund_function_request_refund``.
* ``issuer``: The user's account identifier.
* ``vault``: The address of the Vault involved in this refund request.
* ``amount``: The amount of interBTC refunded.
* ``fee``: The amount of interBTC to mint as fees.