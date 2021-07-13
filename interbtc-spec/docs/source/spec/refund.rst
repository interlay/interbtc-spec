.. _refund-protocol:

Refund
======

Overview
~~~~~~~~

The Refund module is a user failsafe mechanism. In case a user accidentally locks more Bitcoin than the actual issue request, the refund mechanism seeks to ensure that either (1) the initial issue request is increased to issue more interbtc or (2) the BTC are returned to the sending user.  

Step-by-step
------------

If a user falsely sends additional BTC (i.e., :math:`|\text{BTC}| > |\text{interbtc}|`) during the issue process:

1. **Case 1: The originally selected vault has sufficient collateral locked to cover the entire BTC amount sent by the user**:
    a. Increase the issue request interbtc amount and the fee to reflect the actual BTC amount paid by the user.
    b. As before, issue the interbtc to the user and forward the fees.
    c. Emit an event that the issue amount was increased.
2. **Case 2: The originally selected vault does NOT have sufficient collateral locked to cover the additional BTC amount sent by the user**:
    a. Automatically create a return request from the issue module that includes a return fee (deducted from the originial BTC payment) paid to the vault returning the BTC.
    b. The vault fulfills the return request via a transaction inclusion proof (similar to execute issue). However, this does not create new interbtc.

.. note:: Only case 2 is handled in this module. Case 1 is handled directly by the issue module.

.. note:: Normally, enforcing actions by a vault is achieved by locking collateral of the vault and slashing the vault in case of misbehavior. In the case where a user sends too many BTC and the vault does not have enough “free” collateral left, we cannot lock more collateral. However, the original vault cannot move the additional BTC sent as this would be flagged as theft and the vault would get slashed. The vault can possibly take the overpaid BTC though if the vault would not be backing any interbtc any longer (e.g. due to redeem/replace).


Security
--------

- Unique identification of Bitcoin payments: :ref:`op-return`

Functions
~~~~~~~~~

.. _executeRefund:

executeRefund
--------------

This function finalizes a refund, also referred to as a user failsafe. 
It is typically called by the vault client that performed the refund.

Specification
.............

*Function Signature*

``execute_refund(caller, refundId, merkleProof, rawTx)``

*Parameters*

* ``caller``: address of the user finalizing the refund. Typically the vault client that performed the refund.
* ``refundId``: the unique hash created during the internal ``requestRefund`` function.
* ``merkleProof``: merkle tree path (concatenated LE SHA256 hashes).
* ``rawTx``: raw Bitcoin transaction of the refund payment, including the transaction inputs and outputs.

*Events*

* ``ExecuteRefund(refundId, issuer, vault, amount, fee)``

*Preconditions*

* The function call MUST be signed be *someone*, i.e. not necessarily the vault client that performed the refund.
* The BTC Parachain status in the :ref:`security` component MUST NOT be set to ``SHUTDOWN:2``.
* A *pending* ``RefundRequest`` MUST exist with an id equal to ``refundId``.
* ``refundRequest.completed`` MUST be ``false``.
* The ``rawTx`` MUST decode to a valid transaction that transfers the amount specified in the ``RefundRequest`` struct. It MUST be a transaction to the correct address, and provide the expected OP_RETURN, based on the ``RefundRequest``.
* The ``merkleProof`` MUST contain a valid proof of of ``rawTX``.
* The bitcoin payment MUST have been submitted to the relay chain, and MUST have sufficient confirmations.
* The ``vault.status`` MUST be ``active``.
* The ``vault.isBanned()`` MUST return ``false``.
* The refunding vault MUST have enough collateral to mint an amount equal to the refund fee.

*Postconditions*

* The ``vault.issuedTokens`` MUST increase by ``fee``.
* The ``TotalSupply`` in the :ref:`treasury-module` MUST increase by ``fee``.
* The vault's ``SLA`` MUST increase by the :ref:`sla` score of ``Refund``.
