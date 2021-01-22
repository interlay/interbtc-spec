# Changelog

## v1.0 → 1.1

* **VaultRegistry**:

  + Added ``PunishmentDelay`` to data model (indicates how long Vaults are banned by default after misbehavior). Banning Vaults serves both as “mild” punishment (no earning of fees for banned period), as well as protection against users draining an offline Vaults’s collateral via repeated failed Redeem requests. 
  + Added ``bannedUntil`` field to ``Vault`` struct, indicating until when this vault is banned.

* **Redeem**

  + Added boolean flag to ``cancelRedeem`` to indicate whether the user wishes to be reimbursed in DOT or avoid reimbursement and retry the redeem if the current request fails. 
  + Added banning functionality to ``cancelRedeem``: a failed vault is flagged as banned, defined by the ``PunishmentDelay`` parameter in ``VaultRegistry``
  + Added check for banned vault to ``requestRedeem``.
  + Added ``ERR_VAULT_BANNED`` error code

* **Issue**

  + Added check for banned vault to ``requestIssue``
  + Added ``ERR_VAULT_BANNED`` error code

* **Replace**
  
  + Added check for banned vault to ``requestReplace``
  + Added check for banned vault to ``acceptReplace`` (banned vault can’t accept a replace request of another Vault)
  + Added ``ERR_VAULT_BANNED`` error code

* **BTC-Relay**

  + Fixed UNROUNDED_MAX_TARGET defnition to be Substrate compliant
  + Added missing type declarations to ``BlockHeader``
  + Updated text in  ``initialize`` function sequence
  + Updated text in  ``storeBlockHeader`` function sequence
  + Added ``startHeight`` to ``BlockHeader``
  + Removed ``nodata`` and ``invalid`` flags from ``BlockHeader``
  + In ``BlockChain``, ``nodata`` and ``invalid`` are no longer boolean, but ``Vec`` of block heights in the ``chain`` mapping of this ``BlockChain``.
  + Updated ``checkAndDoReorg`` function to overwrite forked out blocks in the main chain (at any point in time, the main chain is a chain that points all the way back to genesis) and set up tracking for these forked blocks in a new ``BlockChain`` entry (i.e., as a ongoing fork).

* **General:**
 
  + Typographical and formatting fixes, incl. syntax fixes in Substrate code snippets
