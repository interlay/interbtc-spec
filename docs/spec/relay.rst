.. _relay:

Relay
=====

The :ref:`relay` module is responsible for handling theft reporting and block submission to the :ref:`btc_relay`. 

Overview
~~~~~~~~

**Relayers** are participants whose main role it is to run Bitcoin full nodes and:
    
    1. Submit valid Bitcoin block headers to earn rewards.
    2. Check vaults do not move BTC, unless expressly requested during :ref:`redeem-protocol`, :ref:`replace-protocol` or :ref:`refund-protocol`.

In the second case, the module should check the accusation (using a Merkle proof), and liquidate the vault if valid. 
It is assumed that there is at least one honest relayer.

The Governance Mechanism votes on critical changes to the architecture or unexpected failures, e.g. hard forks or detected 51% attacks (if a fork exceeds the specified security parameter *k*, see :ref:`security_parameter_k`.

Data Storage
~~~~~~~~~~~~

Maps
----

TheftReports
............

Mapping of Bitcoin transaction identifiers (SHA256 hashes) to account identifiers of Vaults who have been caught stealing Bitcoin.
Per Bitcoin transaction, multiple Vaults can be accused (multiple inputs can come from multiple Vaults). 
This mapping is necessary to prevent duplicate theft reports.

Functions
~~~~~~~~~

.. _relay_function_report_vault_theft:

report_vault_theft
------------------

A relayer reports misbehavior by a vault, providing a fraud proof (malicious Bitcoin transaction and the corresponding transaction inclusion proof). 

A vault is not allowed to move BTC from any registered Bitcoin address (as specified by ``Vault.wallet``), except in the following three cases:

   1) The vault is executing a :ref:`redeem-protocol`. In this case, we can link the transaction to a ``RedeemRequest`` and check the correct recipient. 
   2) The vault is executing a :ref:`replace-protocol`. In this case, we can link the transaction to a ``ReplaceRequest`` and check the correct recipient. 
   3) The vault is executing a :ref:`refund-protocol`. In this case, we can link the transaction to a ``RefundRequest`` and check the correct recipient. 
   4) [Optional] The vault is "merging" multiple UTXOs it controls into a single / multiple UTXOs it controls, e.g. for maintenance. In this case, the recipient address of all outputs (e.g. ``P2PKH`` / ``P2WPKH``) must be the same Vault. 

In all other cases, the vault is considered to have stolen the BTC.

This function checks if the vault actually misbehaved (i.e., makes sure that the provided transaction is not one of the above valid cases) and automatically liquidates the vault (i.e., triggers :ref:`redeem-protocol`).

Specification
.............

*Function Signature*

``report_vault_theft(vault, raw_merkle_proof, raw_tx)``

*Parameters*

* ``vaultId``: the account of the accused Vault.
* ``raw_merkle_proof``: Raw Merkle tree path (concatenated LE SHA256 hashes).
* ``raw_tx``: Raw Bitcoin transaction including the transaction inputs and outputs.

The ``txId`` is obtained as the ``sha256d()`` of the ``raw_tx``.

*Events*

* :ref:`relay_event_report_vault_theft`

*Preconditions*

* The BTC Parachain status in the :ref:`security` component MUST NOT be ``SHUTDOWN:2``.
* A vault with id ``vaultId`` MUST be registered.
* The txId MUST NOT be in ``TheftReports`` mapping.
* The ``verifyTransactionInclusion`` function in the :ref:`btc_relay` component must return true for the derived ``txId``.

*Postconditions*

* The vault MUST be liquidated.
* The vault's status MUST be set to ``CommittedTheft``. 
* All token accounts (``issuedTokens``, ``toBeIssuedTokens``, etc.) MUST be added to the existing system's ``LiquidationVault``.
* ``TheftReports`` MUST contain the reported txId.

.. _relay_function_report_vault_double_payment:

report_vault_double_payment
---------------------------

A relayer reports a double payment from a vault, this can destabalize the system if the vault holds less BTC than is reported by the :ref:`vault-registry`.

Like in :ref:`relay_function_report_vault_theft`, if the vault actually misbehaved it is automatically liquidated.

Specification
.............

*Function Signature*

``report_vault_double_payment(vault, raw_merkle_proof1, raw_tx1, raw_merkle_proof2, raw_tx2)``

*Parameters*

* ``vaultId``: the account of the accused Vault.
* ``raw_merkle_proof1``: The first raw Merkle tree path.
* ``raw_tx1``: The first raw Bitcoin transaction.
* ``raw_merkle_proof2``: The second raw Merkle tree path.
* ``raw_tx2``: The second raw Bitcoin transaction.

*Events*

* :ref:`relay_event_report_vault_theft`

*Preconditions*

* The BTC Parachain status in the :ref:`security` component MUST NOT be ``SHUTDOWN:2``.
* A vault with id ``vaultId`` MUST be registered.
* ``raw_merkle_proof1`` MUST NOT equal ``raw_merkle_proof2``.
* ``raw_tx1`` MUST NOT equal ``raw_tx2``.
* The ``verifyTransactionInclusion`` function in the :ref:`btc_relay` component must return true for the derived ``txId``.
* Both transactions MUST NOT be in ``TheftReports`` mapping.

*Postconditions*

* The vault MUST be liquidated if both transactions contain the same ``OP_RETURN`` value.
* The vault's status MUST be set to ``CommittedTheft``. 
* All token accounts (``issuedTokens``, ``toBeIssuedTokens``, etc.) MUST be added to the existing system's ``LiquidationVault``.
* ``TheftReports`` MUST contain the reported transactions.

Events
~~~~~~~

.. _relay_event_report_vault_theft:

ReportVaultTheft
----------------

Emits an event when a vault has been accused of theft.

*Event Signature*

``ReportVaultTheft(vault)``

*Parameters*

* ``vault``: account identifier of the vault accused of theft. 

*Functions*

* :ref:`relay_function_report_vault_theft`
* :ref:`relay_function_report_vault_double_payment`

