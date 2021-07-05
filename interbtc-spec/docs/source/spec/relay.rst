.. _relay:

Relay
=====

The :ref:`relay` module is responsible for handling theft reporting and block submission to the :ref:`btc-relay`. 

Overview
~~~~~~~~

**Relayers** are participants whose main role it is to run Bitcoin full nodes and:
    
    1. Submit valid Bitcoin block headers to increase their :ref:`sla` score.
    2. Check vaults do not move BTC, unless expressly requested during :ref:`redeem-protocol`, :ref:`replace-protocol` or :ref:`refund-protocol`.

In the second case, the module should check the accusation (using a Merkle proof), and liquidate the vault if valid. 
It is assumed that there is at least one honest relayer.

The Governance Mechanism votes on critical changes to the architecture or unexpected failures, e.g. hard forks or detected 51% attacks (if a fork exceeds the specified security parameter *k*, see `Security Parameter k <https://interlay.gitlab.io/interbtc-spec/btcrelay-spec/security_performance/security.html#security-parameter-k>`_.). 

Data Storage
~~~~~~~~~~~~

Maps
----

TheftReports
.............

Mapping of Bitcoin transaction identifiers (SHA256 hashes) to account identifiers of Vaults who have been caught stealing Bitcoin.
Per Bitcoin transaction, multiple Vaults can be accused (multiple inputs can come from multiple Vaults). 
This mapping is necessary to prevent duplicate theft reports.

Functions
~~~~~~~~~

.. _reportVaultTheft:

reportVaultTheft
----------------

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

``reportVaultTheft(vault, rawMerkleProof, rawTx)``

*Parameters*

* ``vaultId``: the account of the accused Vault.
* ``rawMerkleProof``: Raw Merkle tree path (concatenated LE SHA256 hashes).
* ``rawTx``: Raw Bitcoin transaction including the transaction inputs and outputs.

The ``TxId`` is obtained as the ``sha256d()`` of the ``rawTx``.

*Events*

* ``ReportVaultTheft(vaultId)`` - emits an event indicating that a vault has been caught displacing BTC without permission.

*Preconditions*

* The BTC Parachain status in the :ref:`security` component MUST NOT be ``SHUTDOWN:2``.
* A vault with id ``vaultId`` MUST be registered.
* The TxId MUST NOT be in ``TheftReports`` mapping.
* The TxId MUST be included in the main chain - with ``k`` confirmations.

*Postconditions*

* The vault MUST be liquidated.
* The vault's status is set to ``CommittedTheft``. 
* All accounting (``issuedTokens``, ``toBeIssuedTokens``, etc.) is moved to the system's ``LiquidationVault``.
* ``TheftReports`` MUST contain the reported TxId.

.. _reportVaultDoublePayment:

reportVaultDoublePayment
------------------------

A relayer reports a double payment from a vault, this can destabalize the system if the vault holds less BTC than is reported by the :ref:`vault-registry`.

Like in :ref:`reportVaultTheft`, if the vault actually misbehaved it is automatically liquidated.

Specification
.............

*Function Signature*

``reportVaultDoublePayment(vault, rawMerkleProof1, rawTx1, rawMerkleProof2, rawTx2)``

*Parameters*

* ``vaultId``: the account of the accused Vault.
* ``rawMerkleProof1``: The first raw Merkle tree path.
* ``rawTx1``: The first raw Bitcoin transaction.
* ``rawMerkleProof2``: The second raw Merkle tree path.
* ``rawTx2``: The second raw Bitcoin transaction.

*Events*

* ``ReportVaultTheft(vaultId)`` - emits an event indicating that a vault has been caught displacing BTC without permission.

*Preconditions*

* The BTC Parachain status in the :ref:`security` component MUST NOT be ``SHUTDOWN:2``.
* A vault with id ``vaultId`` MUST be registered.
* ``rawMerkleProof1`` MUST NOT equal ``rawMerkleProof2``.
* ``rawTx1`` MUST NOT equal ``rawTx2``.
* Both transactions MUST be included in the main chain - with ``k`` confirmations.
* Both transactions MUST NOT be in ``TheftReports`` mapping.

*Postconditions*

* The vault MUST be liquidated if both transactions contain the same ``OP_RETURN`` value.
* The vault's status is set to ``CommittedTheft``. 
* All accounting (``issuedTokens``, ``toBeIssuedTokens``, etc.) is moved to the system's ``LiquidationVault``.
* ``TheftReports`` MUST contain the reported transactions.

Events
~~~~~~~

ReportVaultTheft
----------------

Emits an event when a vault has been accused of theft.

*Event Signature*

``ReportVaultTheft(vault)``

*Parameters*

* ``vault``: account identifier of the vault accused of theft. 

*Functions*

* :ref:`reportVaultTheft`

Errors
~~~~~~~

``ERR_ALREADY_REPORTED``

* **Message**: "This TxId has already been logged as a theft by the given Vault"
* **Function**: :ref:`reportVaultTheft`
* **Cause**: This transaction / vault combination has already been reported.

``ERR_VALID_REDEEM``

* **Message**: "The given transaction is a valid Redeem execution by the accused Vault"
* **Function**: :ref:`reportVaultTheft`
* **Cause**: The given transaction is associated with a valid :ref:`redeem-protocol`.

``ERR_VALID_REPLACE``

* **Message**: "The given transaction is a valid Replace execution by the accused Vault"
* **Function**: :ref:`reportVaultTheft`
* **Cause**: The given transaction is associated with a valid :ref:`replace-protocol`.

``ERR_VALID_REFUND``

* **Message**: "The given transaction is a valid Refund execution by the accused Vault"
* **Function**: :ref:`reportVaultTheft`
* **Cause**: The given transaction is associated with a valid :ref:`refund-protocol`.

``ERR_VALID_MERGE_TRANSACTION``

* **Message**: "The given transaction is a valid 'UTXO merge' transaction by the accused Vault"
* **Function**: :ref:`reportVaultTheft`
* **Cause**: The given transaction represents an allowed "merging" of UTXOs by the accused vault (no BTC was displaced).