.. _staked-relayers:

Staked Relayers
===============

The :ref:`staked-relayers` module is responsible for handling the registration and staking of Staked Relayers. 
It also exposes functions for Staked Relayers to vote on Parachain state updates. 


Overview
~~~~~~~~

**Staked Relayers** are collateralized Parachain participants, whose main role it is to run Bitcoin full nodes and check that:
    
    1. Transactional data is available for submitted Bitcoin block headers (``NO_DATA_BTC_RELAY: 0`` code).
    2. Submitted blocks are valid under Bitcoin's consensus rules  (``INVALID_BTC_RELAY: 1`` code).
    3. Vaults do not move BTC to another Bitcoin address, unless expressly requested during :ref:`redeem-protocol` or :ref:`replace-protocol`.
    4. If a Vault is under-collateralized, i.e., the collateral rate has fallen below ``LiquidationCollateralThreshold``, as defined in :ref:`vault-registry`. 

 If one of the above failures is detected, Staked Relayers file a report with the :ref:`security` module. In cases (1) and (2), a vote is initiated, whereby this module acts as bulleting board and collects Staked Relayer signatures - if a majority is reached, as defined by ``STAKED_RELAYER_VOTE_THRESHOLD``, the state of the BTC Parachain is updated. In cases (3) and (4) a single Staked Relayer report suffices - the Security module checks if the accusation against the Vault is correct, and if yes updates the BTC Parachain state and flags the Vault according to the reported failure.


Staked Relayers are overseen by the Parachain **Governance Mechanism**. 
The Governance Mechanism also votes on critical changes to the architecture or unexpected failures, e.g. hard forks or detected 51% attacks (if a fork exceeds the specified security parameter *k*, see `Security Parameter k <https://interlay.gitlab.io/polkabtc-spec/btcrelay-spec/security_performance/security.html#security-parameter-k>`_.). 



Data Model
~~~~~~~~~~

Enums
------

ProposalStatus
...............

Indicated the state of a proposed ``StatusUpdate``.

* ``PENDING: 0`` - this ``StatusUpdate`` is current under review and is being voted upon.

* ``ACCEPTED: 1``- this ``StatusUpdate`` has been accepted.

* ``REJECTED: 2`` -this ``StatusUpdate`` has been rejected.

.. *Substrate* 

::

  enum ProposalStatus {
        PENDING = 0,
        ACCEPTED = 1,
        REJECTED = 2,
  }


Structs
--------

StatusUpdate
.............

Struct providing information for an occurred halting of BTC-Relay. Contains the following fields.

======================  ==============  ============================================
Parameter               Type            Description
======================  ==============  ============================================
``newStatusCode``       StatusCode      New status of the BTC Parachain.
``oldStatusCode``       StatusCode      Previous status of the BTC Parachain.
``addErrors``           Set<ErrorCode>  If ``newStatusCode`` is ``Error``, specifies which errors are to be added to the BTC Parachain``Errors``.         
``removeErrors``        Set<ErrorCode>  Indicates which ``ErrorCode`` entries are to be removed from ``Errors`` (recovery).           
``time``                U256            Parachain block number at which this status update was suggested.
``proposalStatus``      ProposalStatus  Status of the proposed status update. See ``ProposalStatus``.
``msg``                 String          Message providing more details on the change of status (detailed error message or recovery reason). 
``btcBlockHash``        H256            Block hash of the Bitcoin block where the error was detected, if related to BTC-Relay.
``votesYes``            Set<AccountId>  Set of accounts which have voted FOR this status update. This can be either Staked Relayers or the Governance Mechanism. Checks are performed depending on the type of status change. Should maintain insertion order to allow checking who proposed this update (at index ``0``). 
``votesNo``             Set<AccountId>  Set of accounts which have voted AGAINST this status update. 
======================  ==============  ============================================

.. note:: ``StatusUpdates`` executed by the Governance Mechanism are not voted upon by Staked Relayers (hence ``votesNo`` will be empty).

.. *Substrate* 

::

  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct StatusUpdate<StatusCode, ErrorCode, BlockNumber, AccountId> {
        newStatusCode: StatusCode,
        oldStatusCode: StatusCode,
        addErrors: BTreeSet<ErrorCode>,
        removeErrors: BTreeSet<ErrorCode>,
        time: BlockNumber,
        msg: String,
        votesYes: BTreeSet<AccountId>,
        votesNo: BTreeSet<AccountId>,
  }



StakedRelayer
..............

Stores the information of a Staked Relayer.

.. tabularcolumns:: |l|l|L|

=========================  =========  ========================================================
Parameter                  Type       Description
=========================  =========  ======================================================== 
``stake``                  DOT        Total amount of collateral/stake provided by this Staked Relayer.
=========================  =========  ========================================================

.. *Substrate* 

::

  #[derive(Encode, Decode, Default, Clone, PartialEq)]
  #[cfg_attr(feature = "std", derive(Debug))]
  pub struct StatusUpdate<Balance> {
        stake: Balance
  }

.. note:: Struct used here in case more information needs to be stored for Staked Relayers, e.g. SLA (votes cast vs. votes missed).


Data Storage
~~~~~~~~~~~~

Constants
---------

STAKED_RELAYER_VOTE_THRESHOLD
...............................

Integer denoting the percentage of Staked Relayer signatures/votes necessary to alter the state of the BTC Parachain (``NO_DATA_BTC_RELAY`` and ``INVALID_BTC_RELAY`` error codes).

.. note:: Must be a number between 0 and 100.


.. *Substrate* ::

  STAKED_RELAYER_VOTE_THRESHOLD: U8;


STAKED_RELAYER_STAKE
......................

Integer denoting the minimum DOT stake which Staked Relayers must provide when registering. 


.. *Substrate* ::

  STAKED_RELAYER_STAKE: Balance;


StatusCounter
.................

Integer increment-only counter used to track status updates.

.. *Substrate* ::

  StatusCounter: U256;


Maps
----

StakedRelayers
...............

Mapping from accounts of StakedRelayers to their struct. ``<Account, StakedRelayer>``.

.. *Substrate* ::

    StakedRelayers map T::AccountId => StakedRelayer<Balance>



StatusUpdates
..............

Map of ``StatusUpdates``, identified by an integer key. ``<U256, StatusUpdate>``.

.. *Substrate* ::

    StatusUpdates map U256 => StatusUpdate<StatusCode, ErrorCode, BlockNumber, AccountId>


TheftReports
.............

Mapping of Bitcoin transaction identifiers (SHA256 hashes) to account identifiers of Vaults who have been caught stealing Bitcoin.
Per Bitcoin transaction, multiple Vaults can be accused (multiple inputs can come from multiple Vaults). 
This mapping is necessary to prevent duplicate theft reports.
``<H256, Set<AccountId>>``.

.. *Substrate* ::

    TheftReports map H256 => BTreeSet<AccountId>



Functions
~~~~~~~~~

.. _registerStakedRelayer:

registerStakedRelayer
----------------------

Registers a new Staked Relayer, locking the provided collateral, which must exceed ``STAKED_RELAYER_STAKE``.

Specification
.............

*Function Signature*

``registerStakedRelayer(stakedRelayer, stake)``

*Parameters*

* ``stakedRelayer``: The account of the Staked Relayer to be registered.
* ``stake``: to-be-locked collateral/stake in DOT.


*Events*

* ``RegisterStakedRelayer(StakedRelayer, collateral)``: emit an event stating that a new Staked Relayer (``stakedRelayer``) was registered and provide information on the Staked Relayer's stake (``stake``). 

*Errors*

* ``ERR_ALREADY_REGISTERED = "This AccountId is already registered as a Staked Relayer"``: The given account identifier is already registered. 
* ``ERR_INSUFFICIENT_STAKE = "Insufficient stake provided"``: The provided stake was insufficient - it must be above ``STAKED_RELAYER_STAKE``.
  
.. *Substrate* ::

  fn registerStakedRelayer(origin, amount: Balance) -> Result {...}

Preconditions
.............

Function Sequence
.................

The ``registerStakedRelayer`` function takes as input a Parachain AccountID, and DOT collateral (to be used as stake), and registers a new Staked Relayer in the system.

1) Check that the ``stakedRelayer`` is not already in ``StakedRelayers``. Return ``ERR_ALREADY_REGISTERED`` if this check fails.

2) Check that ``stake > STAKED_RELAYER_STAKE`` holds, i.e., the Staked Relayer provided sufficient collateral. Return ``ERR_INSUFFICIENT_STAKE`` error if this check fails.

3) Lock the DOT stake/collateral by calling :ref:`lockCollateral` and passing ``stakedRelayer`` and the ``stake`` as parameters.

4) Store the provided information (amount of ``stake``) in a new ``StakedRelayer`` and insert it into the ``StakedRelayers`` mapping using the ``stakedRelayer`` AccountId as key.

5) Emit a ``RegisterStakedRelayer(StakedRelayer, collateral)`` event. 

6) Return.


.. _deRegisterStakedRelayer:

deRegisterStakedRelayer
-----------------------

De-registers a Staked Relayer, releasing the associated stake.

Specification
.............

*Function Signature*

``registerStakedRelayer(stakedRelayer)``

*Parameters*

* ``stakedRelayer``: The account of the Staked Relayer to be de-registered.


*Events*

* ``DeRegisterStakedRelayer(StakedRelayer)``: emit an event stating that a Staked Relayer has been de-registered (``stakedRelayer``).

*Errors*

* ``ERR_NOT_REGISTERED = "This AccountId is not registered as a Staked Relayer"``: The given account identifier is not registered. 
  
.. *Substrate* ::

  fn deRegisterStakedRelayer(origin) -> Result {...}

Preconditions
.............

Function Sequence
.................

1) Check if the ``stakedRelayer`` is indeed registered in ``StakedRelayers``. Return ``ERR_NOT_REGISTERED`` if this check fails.

3) Release the DOT stake/collateral of the ``stakedRelayer`` by calling :ref:`lockCollateral` and passing ``stakedRelayer`` and the ``StakeRelayer.stake`` (as retrieved from ``StakedRelayers``) as parameters.

4) Remove the entry from ``StakedRelayers`` which has ``stakedRelayer`` as key.

5) Emit a ``DeRegisterStakedRelayer(StakedRelayer)`` event. 

6) Return.



.. _suggestStatusUpdate: 

suggestStatusUpdate
----------------------

Suggest a new status update and opens it up for voting.

.. warning:: This function can only be called by Staked Relayers. The Governance Mechanism can change the ``ParachainStatus`` using :ref:`executeStatusUpdate` directly.

Specification
.............

*Function Signature*

``suggestStatusUpdate(stakedRelayer, newStatusCode, addErrors, removeErrors, blockHash, msg)``

*Parameters*

* ``stakedRelayer``: The AccountId of the Staked Relayer suggesting the status change.
* ``newStatusCode``: Suggested BTC Parachain status (``StatusCode`` enum).
* ``addErrors``: If the suggested status is ``Error``, this set of ``ErrorCodes`` indicates which errors are to be added to the ``Errors`` mapping.
* ``removeErrors``: Set of ``ErrorCodes`` to be removed from the ``Errors`` list.
* ``blockHash``: [Optional] When reporting an error related to BTC-Relay, this field indicates the affected Bitcoin block (header).
* ``msg`` : String message providing the detailed reason for the suggested status change. 


*Events*

* ``StatusUpdateSuggested(newStatusCode, addErrors, removeErrors, msg, stakedRelayer)`` - emits an event indicating the status change, with ``newStatusCode`` being the new ``StatusCode``, ``addErrors`` the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``), ``removeErrors`` the set of to-be-removed ``ErrorCode`` entries, ``msg`` the detailed message provided by the function caller, and ``stakedRelayer`` the account identifier of the Staked Relayer suggesting the update.

*Errors*

* ``ERR_GOVERNANCE_ONLY = This action can only be executed by the Governance Mechanism``: The suggested status (``SHUTDOWN``) can only be triggered by the Governance Mechanism but the caller of the function is not part of the Governance Mechanism.
* ``ERR_STAKED_RELAYERS_ONLY = "This action can only be executed by Staked Relayers"``: The caller of this function was not a Staked Relayer. Only Staked Relayers are allowed to suggest and vote on BTC Parachain status updates.
  
.. *Substrate* ::

  fn suggestStatusUpdate(origin, newStatusCode: StatusCode, addErrors: BTreeSet<ErrorCode>, removeErrors: BTreeSet<ErrorCode>, msg: String) -> Result {...}

Preconditions
.............

Function Sequence
.................

1. Check if the suggested ``newStatusCode`` is ``SHUTDOWN``. If yes, check whether the caller of this function is the Governance Mechanism. Return ``ERR_GOVERNANCE_ONLY`` if this check fails.

2. Check if the caller is in the ``StakedRelayers`` mapping. Return ``ERR_STAKED_RELAYERS_ONLY`` if this check fails.

3. Create a new ``StatusUpdate`` struct, with:

   * ``StatusUpdate.newStatusCode = newStatusCode``,
   * ``StatusUpdate.oldStatusCode = ParachainStatus``,
   * Set ``StatusUpdate.addErrors = addErrors``,
   * Set ``StatusUpdate.removeErrors = removeErrors``,
   * ``StatusUpdate.time =`` current Parachain block number,
   * ``StatusUpdate.blockHash = blockHash``,
   * ``StatusUpdate.msg = msg``,
   * ``StatusUpdate.proposalStatus = ProposalStatus.PENDING``,
   * Initialize ``StatusUpdate.votesYes`` with a new Set (``BTreeSet``), and insert ``stakedRelayer`` (as the first vote),
   * Initialize ``StatusUpdate.votesNo`` with an empty Set (``BTreeSet``).

4. Insert the new ``StatusUpdate`` into the ``StatusUpdates`` mapping, using :ref:`getStatusCounter` as key.

4. Emit a ``StatusUpdateSuggested(newStatusCode, addErrors, removeErrors, msg, stakedRelayer)`` event.

5. Return.

.. _voteOnStatusUpdate: 

voteOnStatusUpdate
----------------------

A Staked Relayer casts a vote on a suggested ``StatusUpdate``.
Checks the threshold of votes and executes / cancels a StatusUpdate depending on the threshold reached.
 
.. warning:: This function can only be called by Staked Relayers. The Governance Mechanism can change the ``ParachainStatus`` using :ref:`executeStatusUpdate` directly.


Specification
.............

*Function Signature*

``voteOnStatusUpdate(stakedRelayer, statusUpdateId, vote)``

*Parameters*

* * ``stakedRelayer``: The AccountId of the Staked Relayer casting the vote.
* ``statusUpdateId``: Identifier of the ``StatusUpdate`` voted upon in ``StatusUpdates``.
* ``vote``: ``True`` or ``False``, depending on whether the Staked Relayer agrees or disagrees with the suggested suggestStatusUpdate.


*Events*

* ``VoteOnStatusUpdate(statusUpdateId, stakedRelayer, vote)``: emit an event informing about the vote (``vote``) cast by a ``stakedRelayer`` on a ``StatusUpdate``  with the specified identifier (``statusUpdateId``).

*Errors*

* ``ERR_STAKED_RELAYERS_ONLY = "This action can only be executed by Staked Relayers"``: The caller of this function was not a Staked Relayer. Only Staked Relayers are allowed to suggest and vote on BTC Parachain status updates.
* ``ERR_STATUS_UPDATE_NOT_FOUND = "No StatusUpdate found with given identifier"``: No ``StatusUpdate`` with the given ``statusUpdateId`` exists in ``StatusUpdates``.

.. *Substrate* ::found

  fn voteOnStatusUpdate(origin, statusUpdateId: U256, vote: bool) -> Result {...}


Function Sequence
.................

1. Check if the caller of the function is a Staked Relayer in ``StakedRelayers``. Return ``ERR_STAKED_RELAYERS_ONLY`` if this check fails.

2. Retrieve the ``StatusUpdate`` from ``StatusUpdates`` using ``statusUpdateId``. Return ``ERR_STATUS_UPDATE_NOT_FOUND`` if this check fails.

3. Register the vote:

   a. If ``vote == True``: add ``stakedRelayer`` to ``StatusUpdate.voteYes``. Check if the ``stakedRelayer`` is also included in ``StatusUpdate.voteNo`` (i.e., previously voted "No") and if this is the case, remove the entry - i.e., the Staked Relayer changed vote.

   b. If ``vote == False``: add ``stakedRelayer`` to ``StatusUpdate.voteNo``. Check if the ``stakedRelayer`` is also included in ``StatusUpdate.voteYes`` (i.e., previously voted "Yes") and if this is the case, remove the entry - i.e., the Staked Relayer changed vote.

.. attention:: This ensures a Staked Relayer cannot cast two conflicting votes on the same ``StatusUpdate``. 

4a. Check if the "Yes" votes exceed the necessary ``STAKED_RELAYER_VOTE_THRESHOLD``, i.e., check if ``StatusUpdate.voteYes.length * 100 / StakedRelayers.length`` exceeds ``STAKED_RELAYER_VOTE_THRESHOLD``. If this is the case, call :ref:`executeStatusUpdate`, passing ``statusUpdateId`` as parameter.

4b. Otherwise, check if the ``StatusUpdate`` has been rejected. For this ``(StatusUpdate.voteNo.length *100 / StakedRelayers.length`` exceeds ``100 - STAKED_RELAYER_VOTE_THRESHOLD`` (i.e., ``STAKED_RELAYER_VOTE_THRESHOLD`` can no longer be reached by the "Yes" votes). If this is the case, call :ref:`rejectStatusUpdate` passing ``statusUpdateId`` as parameter

5. Return.

.. note:: We do not automatically slash Staked Relayers who voted against a majority. This is left for the Governance Mechanism to decide and execute manually via :ref:`slashStakedRelayer`.

.. _executeStatusUpdate:

executeStatusUpdate
--------------------

Executes a ``StatusUpdate`` that has received sufficient "Yes" votes.

.. warning:: This function can only be called internally if a ``StatusUpdate`` has received more votes than required by ``STAKED_RELAYER_VOTE_THRESHOLD``.

.. note:: In case of BTC-Relay errors/recovery, this function calls into :ref:`btc-relay` to flag / un-flag the corresponding ``BlockHeader`` and ``BlockChain`` entries, as specified _recoverFromBTCRelayFailure ``blockHash``.

Specification
..............

*Function Signature*

``executeStatusUpdate(statusUpdateId)``

*Parameters*

* ``statusUpdateId``: Identifier of the ``StatusUpdate`` voted upon in ``StatusUpdates``.



*Errors*

* ``ERR_STATUS_UPDATE_NOT_FOUND = "No StatusUpdate found with given identifier"``: No ``StatusUpdate`` with the given ``statusUpdateId`` exists in ``StatusUpdates``.
* ``ERR_INSUFFICIENT_YES_VOTES = "Insufficient YES votes to execute this StatusUpdate"``: The ``StatusUpdate`` does not have enough "Yes" votes to be executed.

*Events*

* ``ExecuteStatusUpdate(newStatusCode, addErrors, removeErrors, msg)`` - emits an event indicating the status change, with ``newStatusCode`` being the new ``StatusCode``, ``addErrors`` the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``), ``removeErrors`` the set of to-be-removed ``ErrorCode`` entries, and ``msg`` the detailed reason for the status update. 

.. *Substrate*::

  fn executeStatusUpdate(statusUpdateId: U256) -> Result {...}


Precondition
..............

Function Sequence
...................

1.  Retrieve the ``StatusUpdate`` from ``StatusUpdates`` using ``statusUpdateId``. Return ``ERR_STATUS_UPDATE_NOT_FOUND`` if this check fails. 

2. Check if the ``StatusUpdate`` given by ``statusUpdateId`` has sufficient "Yes" votes, i.e., check if ``StatusUpdate.voteYes.length * 100 / StakedRelayers.length`` exceeds ``STAKED_RELAYER_VOTE_THRESHOLD``. If this check fails, return ``ERR_INSUFFICIENT_YES_VOTES``.

3. Set ``ParachainStatus``  to ``StatusUpdate.statusCode``. 

4. If ``newStatusCode == Error``, add ``addErrors`` to  ``Errors``,

5. If ``addErrors`` contains ``NO_DATA_BTC_RELAY`` or ``INVALID_BTC_RELAY``, call *flagBlockError* in :ref:`btc-relay` passing ``addErrors`` and ``StatusUpdate.blockHash`` as parameters.

6. If ``removeErrors`` contains ``NO_DATA_BTC_RELAY`` or ``INVALID_BTC_RELAY``, call *clearBlockError* in :ref:`btc-relay` passing ``removeErrors`` and ``StatusUpdate.blockHash`` as parameters.

7. If ``oldStatusCode == Error``, subtract ``removeErrors`` from  ``Errors``, 

8. Set ``StatusUpdate.proposalStatus`` to ``ProposalStatus.ACCEPTED``.

9. Emit ``StatusUpdateExecuted(StatusUpdate.statusCode, StatusUpdate.addErrors, StatusUpdate.removeErrors, StatusUpdate.msg)`` event.

10. Return.


.. _rejectStatusUpdate:

rejectStatusUpdate
--------------------

Rejects a suggested ``StatusUpdate``. 

.. note:: This function DOES NOT slash Staked Relayers who have lost the vote on this ``StatusUpdate``. Slashing is executed solely by the Governance Mechanism.



Specification
..............

*Function Signature*

``rejectStatusUpdate(statusUpdateId)``

*Parameters*

* ``statusUpdateId``: Identifier of the ``StatusUpdate`` voted upon in ``StatusUpdates``.



*Errors*

* ``ERR_STATUS_UPDATE_NOT_FOUND = "No StatusUpdate found with given identifier"``: No ``StatusUpdate`` with the given ``statusUpdateId`` exists in ``StatusUpdates``.
* ``ERR_INSUFFICIENT_NO_VOTES = "Insufficient YES votes to reject this StatusUpdate"``: The ``StatusUpdate`` does not have enough "No" votes to be rejected. 

*Events*

* ``RejectStatusUpdate(newStatusCode, addErrors, removeErrors, msg)`` - emits an event indicating the rejected status change, with ``newStatusCode`` being the new ``StatusCode``, ``addErrors`` the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``), ``removeErrors`` the set of to-be-removed ``ErrorCode`` entries, and ``msg`` the detailed reason for the status update. 

.. *Substrate*::

  fn rejectStatusUpdate(statusUpdateId: U256) -> Result {...}


Precondition
..............

Function Sequence
...................

1.  Retrieve the ``StatusUpdate`` from ``StatusUpdates`` using ``statusUpdateId``. Return ``ERR_STATUS_UPDATE_NOT_FOUND`` if this check fails. 

2. Check if the ``StatusUpdate`` given by ``statusUpdateId`` has sufficient "No" votes, i.e., check if ``StatusUpdate.voteNo.length * 100 / StakedRelayers.length`` exceeds ``1 - STAKED_RELAYER_VOTE_THRESHOLD``. If this check fails, return ``ERR_INSUFFICIENT_NO_VOTES``.

4. Set ``StatusUpdate.proposalStatus`` to ``ProposalStatus.REJECTED``.

5. Emit ``RejectStatusUpdate(StatusUpdate.statusCode, StatusUpdate.addErrors, StatusUpdate.removeErrors, StatusUpdate.msg)`` event.

6. Return.


.. _forceStatusUpdate:

forceStatusUpdate
--------------------

.. warning:: This function can only be called by the Governance Mechanism.


Specification
..............

*Function Signature*

``forceStatusUpdate(governanceMechanism, newStatusCode, addErrors, removeErrors, msg)``

*Parameters*

* ``governanceMechanism``: The AccountId of the Governance Mechanism.
* ``newStatusCode``: Suggested BTC Parachain status (``StatusCode`` enum).
* ``errors``: If the suggested status is ``Error``, this set of ``ErrorCode`` entries provides details on the occurred errors.
* ``msg`` : String message providing the detailed reason for the suggested status change. 


*Events*

* ``ForceStatusUpdate(newStatusCode, addErrors, removeErrors, msg)`` - emits an event indicating the status change, with ``newStatusCode`` being the new ``StatusCode``, ``addErrors`` the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``), ``removeErrors`` the set of to-be-removed ``ErrorCode`` entries, and ``msg`` the detailed message provided by the function caller.

*Errors*

* ``ERR_GOVERNANCE_ONLY = This action can only be executed by the Governance Mechanism``: The suggested status (``SHUTDOWN``) can only be triggered by the Governance Mechanism but the caller of the function is not part of the Governance Mechanism.

.. *Substrate*::

  fn forceStatusUpdate(origin, newStatusCode: StatusCode, addErrors: BTreeSet<ErrorCode>, removeErrors: BTreeSet<ErrorCode>, msg, String) -> Result {...}


Precondition
..............


Function Sequence
...................

1. Check that the caller of this function is indeed the Governance Mechanism. Return ``ERR_GOVERNANCE_ONLY`` if this check fails.

2. Create a new ``StatusUpdate`` struct, with:

   * ``StatusUpdate.newStatusCode = newStatusCode``,
   * ``StatusUpdate.oldStatusCode = ParachainStatus``,
   * Set  ``StatusUpdate.addErrors = addErrors``,
   * Set  ``StatusUpdate.removeErrors = removeErrors``,
   * ``StatusUpdate.time =`` current Parachain block number,
   * ``StatusUpdate.msg = msg``,
   * ``StatusUpdate.proposalStatus = ProposalStatus.ACCEPTED``,
   * Initialize ``StatusUpdate.votesYes`` with a new Set (``BTreeSet``), and insert ``governanceMechanism`` (as the first any **only** vote),
   * Initialize ``StatusUpdate.votesNo`` with an empty Set (``BTreeSet``).


3. Insert the new ``StatusUpdate`` into the ``StatusUpdates`` mapping, using :ref:`getStatusCounter` as key.

4. Set ``ParachainStatus``  to ``newStatusCode``.

5. If ``newStatusCode == Error`` add  ``StatusUpdate.addErrors`` to ``Errors``.

6. Subtract  ``StatusUpdate.removeErrors`` to ``Errors``.

7. Emit ``ForceStatusUpdate(newStatusCode, addErrors, removeErrors, msg)`` event 


.. _slashStakedRelayer: 

slashStakedRelayer
----------------------

Slashes the stake/collateral of a Staked Relayer and removes them from the Staked Relayer list (mapping).

.. warning:: This function can only be called by the Governance Mechanism.


Specification
.............

*Function Signature*

``slashStakedRelayer(governanceMechanism, stakedRelayer)``

*Parameters*

* ``governanceMechanism``: The AccountId of the Governance Mechanism.
* ``stakedRelayer``: The account of the Staked Relayer to be slashed.


*Events*

* ``SlashStakedRelayer(stakedRelayer)``: emits an event indicating that a given Staked Relayer (``stakedRelayer``) has been slashed and removed from ``StakedRelayers``.

*Errors*

* ``ERR_GOVERNANCE_ONLY = This action can only be executed by the Governance Mechanism``: Only the Governance Mechanism can slash Staked Relayers.
* ``ERR_NOT_REGISTERED = "This AccountId is not registered as a Staked Relayer"``: The given account identifier is not registered. 

  
.. *Substrate* ::

  fn stakedRelayer(stakedRelayer: AccountId) -> Result {...}


Function Sequence
.................

1. Check that the caller of this function is indeed the Governance Mechanism. Return ``ERR_GOVERNANCE_ONLY`` if this check fails.

2. Retrieve the Staked Relayer with the given account identifier (``stakedRelayer``) from ``StakedRelayers``. Return ``ERR_NOT_REGISTERED`` if not Staked Relayer with the given identifier can be found.

3. Confiscate the Staked Relayer's collateral. For this, call :ref:`slashCollateral` providing ``stakedRelayer`` and ``governanceMechanism`` as parameters.

4. Remove ``stakedRelayer`` from ``StakedRelayers``

5. Emit ``SlashStakedRelayer(stakedRelayer)`` event.

6. Return.


.. _reportVaultTheft:

reportVaultTheft
-----------------

A Staked Relayer reports misbehavior by a Vault, providing a fraud proof (malicious Bitcoin transaction and the corresponding transaction inclusion proof). 

A Vault is not allowed to move BTC from its Bitcoin address (as specified by ``Vault.btcAddress``, except in the following three cases:

   1) The Vault is executing a :ref:`redeem-protocol`. In this case, we can link the transaction to a ``RedeemRequest`` and check the correct recipient. 
   2) The Vault is executing a :ref:`replace-protocol`. In this case, we can link the transaction to a ``ReplaceRequest`` and check the correct recipient. 
   3) [Optional] The Vault is "merging" multiple UTXOs it controls into a single / multiple UTXOs it controls, e.g. for maintenance. In this case, the recipient address of all outputs (``P2PKH`` / ``P2WPKH``) must be the same Vault. 

In all other cases, the Vault is considered to have stolen the BTC.

This function checks if the Vault actually misbehaved (i.e., makes sure that the provided transaction is not one of the above valid cases) and automatically liquidates the Vault (i.e., triggers :ref:`redeem-protocol`).

.. note:: Status updates triggered by this function require no Staked Relayer vote, as the report can be programmatically verified by the BTC Parachain.


Specification
.............

*Function Signature*

``reportVaultTheft(vault, txId, txBlockHeight, txIndex, merkleProof, rawTx)``


*Parameters*

* ``vault``: the account of the accused Vault.
* ``txId``: The hash of the Bitcoin transaction.
* ``txBlockHeight``: Bitcoin block height at which the transaction is supposedly included.
* ``txIndex``: Index of transaction in the Bitcoin block’s transaction Merkle tree.
* ``MerkleProof``: Merkle tree path (concatenated LE SHA256 hashes).
* ``rawTx``: Raw Bitcoin transaction including the transaction inputs and outputs.


*Events*

* ``ReportVaultTheft(vault)`` - emits an event indicating that a Vault (``vault``) has been caught displacing BTC without permission.
* ``ExecuteStatusUpdate(newStatusCode, addErrors, removeErrors, msg)`` - emits an event indicating the status change, with ``newStatusCode`` being the new ``StatusCode``, ``addErrors`` the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``), ``removeErrors`` the set of to-be-removed ``ErrorCode`` entries, and ``msg`` the detailed reason for the status update. 

*Errors*

* ``ERR_STAKED_RELAYERS_ONLY = "This action can only be executed by Staked Relayers"``: The caller of this function was not a Staked Relayer. Only Staked Relayers are allowed to suggest and vote on BTC Parachain status updates.
* ``ERR_ALREADY_REPORTED = "This txId has already been logged as a theft by the given Vault"``: This transaction / Vault combination has already been reported.
* ``ERR_VAULT_NOT_FOUND = "There exists no Vault with the given account id"``: The specified Vault does not exist. 
* ``ERR_ALREADY_LIQUIDATED = "This Vault is already being liquidated``: The specified Vault is already being liquidated.
* ``ERR_VALID_REDEEM_OR_REPLACE = "The given transaction is a valid Redeem or Replace execution by the accused Vault"``: The given transaction is associated with a valid :ref:`redeem-protocol` or :ref:`replace-protocol`.
* ``ERR_VALID_MERGE_TRANSACTION = "The given transaction is a valid 'UTXO merge' transaction by the accused Vault"``: The given transaction represents an allowed "merging" of UTXOs by the accused Vault (no BTC was displaced).


.. *Substrate* ::

  fn reportVaultTheft(vault: AccountId, txId: T::H256, txBlockHeight: U256, txIndex: u64, merkleProof: Bytes, rawTx: Bytes) -> T::H256 {...}

Function Sequence
.................

1. Check that the caller of this function is indeed a Staked Relayer. Return ``ERR_STAKED_RELAYERS_ONLY`` if this check fails.

2. Check if the specified ``vault`` exists in ``Vaults`` in :ref:`vault-registry`. Return ``ERR_VAULT_NOT_FOUND`` if there is no Vault with the specified account identifier.

3. Check if this ``vault`` is already being liquidated, i.e., is in the ``LiquidationList``. If this is the case, return ``ERR_ALREADY_LIQUIDATED`` (no point in duplicate reporting).

4. Check if the given Bitcoin transaction is already associated with an entry in ``TheftReports`` (use ``txId`` as key for lookup). If yes, check if the specified ``vault`` is already listed in the associated set of Vaults. If the Vault is already in the set, return ``ERR_ALREADY_REPORTED``. 

5. Extract the ``outputs`` from ``rawTx`` using `extractOutputs` from the BTC-Relay.

6. Check if the transaction is a "migration" of UTXOs to the same Vault. For each output, in the extracted ``outputs``, extract the recipient Bitcoin address (using `extractOutputAddress` from the BTC-Relay). 

   a) If one of the extracted Bitcoin addresses does not match the Bitcoin address of the accused ``vault`` (``Vault.btcAddress``) **continue to step 7**. 

   b) If all extracted addresses match the Bitcoin address of the accused ``vault`` (``Vault.btcAddress``), abort and return ``ERR_VALID_MERGE_TRANSACTION``.

7. Check if the transaction is part of a valid :ref:`redeem-protocol` or :ref:`replace-protocol` process. 

  a) Extract the OP_RETURN value from the (second) output (``outputs[1]``) using `extractOPRETURN` from the BTC-Relay. If this call returns an error (not a valid OP_RETURN output, hence not valid :ref:`redeem-protocol` or :ref:`replace-protocol` process), **continue to step 8**. 

  c) Check if the extracted OP_RETURN value matches any ``redeemId`` in ``RedeemRequest`` (in ``RedeemRequests`` in :ref:`redeem-protocol`) or any ``replaceId`` in ``ReplaceRequest`` (in ``RedeemRequests`` in :ref:`redeem-protocol`) entries *associated with this Vault*. If no match is found, **continue to step 8**.

  d) Otherwise, if an associated ``RedeemRequest``  or ``ReplaceRequest`` was found: extract the value (using `extractOutputValue` from the BTC-Relay) and recipient Bitcoin address (using `extractOutputAddress` from the BTC-Relay) from the first output (``outputs[0]``). Next, check 

     
     i ) if the value is it is equal (or greater) than ``paymentValue`` in the ``RedeemRequest``  or ``ReplaceRequest``. 
     
     ii ) if the recipient Bitcoin address matches the recipient specified in the ``RedeemRequest``  or ``ReplaceRequest``.

    If both checks are successful, abort and return ``ERR_VALID_REDEEM_OR_REPLACE``. Otherwise, **continue to step 8**.

8. The Vault misbehaved (displaced BTC). 

    a) Call :ref:`liquidateVault`, liquidating the Vault and transferring all of its balances and DOT collateral to th ``LiquidationVault`` for failure and reimbursement handling;

    b) set ``ParachainStatus = ERROR`` and add ``LIQUIDATION`` to ``Errors``,

    c) emit ``ExecuteStatusUpdate(ParachainStatus, [LIQUIDATION], [], "Vault 'vault' displaced BTC and is being liquidated")``
  
5. Return


.. _reportVaultUndercollateralized:

reportVaultUndercollateralized
-------------------------------

A Staked Relayer reports that a Vault is undercollateralized, i.e., below the ``LiquidationCollateralThreshold`` as defined in :ref:`vault-registry`. This function checks if the Vault's collateral is indeed below this rate and if yes, flags the Vault for liquidation and updates the ``ParachainStatus`` to ``ERROR`` and adding ``LIQUIDATION`` to ``Errors``.

.. note:: Status updates triggered by this function require no Staked Relayer vote, as the report can be programmatically verified by the BTC Parachain.

Specification
.............

*Function Signature*

``reportVaultUndercollateralized(vault)``


*Parameters*

* ``vault``: the account of the accused Vault.



*Events*

* ``ExecuteStatusUpdate(newStatusCode, addErrors, removeErrors, msg)`` - emits an event indicating the status change, with ``newStatusCode`` being the new ``StatusCode``, ``addErrors`` the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``), ``removeErrors`` the set of to-be-removed ``ErrorCode`` entries, and ``msg`` the detailed reason for the status update. 

*Errors*

* ``ERR_STAKED_RELAYERS_ONLY = "This action can only be executed by Staked Relayers"``: The caller of this function was not a Staked Relayer. Only Staked Relayers are allowed to suggest and vote on BTC Parachain status updates.
* ``ERR_COLLATERAL_OK = "The accused Vault's collateral rate is above the liquidation threshold"``: The accused Vault's collateral rate is  above ``LiquidationCollateralThreshold``.
* ``ERR_VAULT_NOT_FOUND = "There exists no Vault with the given account id"``: The specified Vault does not exist. 

.. *Substrate* ::

  fn reportVaultUndercollateralized(vault: AccountId) -> T::H256 {...}

Function Sequence
.................

1. Check that the caller of this function is indeed a Staked Relayer. Return ``ERR_STAKED_RELAYERS_ONLY`` if this check fails.

2. Retrieve the Vault from ``Vaults`` in :ref:`vault-registry` using ``vault``. Return ``ERR_VAULT_NOT_FOUND`` if there is no Vault with the specified account identifier.

3. Check if the Vault's collateralization rate is below ``LiquidationCollateralThreshold`` as defined in :ref:`vault-registry`.  That is, check ``Vault.collateral`` against ``Vault.issuedTokens``. If the Vault's collateral rate is above ``LiquidationCollateralThreshold``, return ``ERR_COLLATERAL_OK``

4. Otherwise, if the Vault is undercollateralized:

    a) Call :ref:`liquidateVault`, liquidating the Vault and transferring all of its balances and DOT collateral to th ``LiquidationVault`` for failure and reimbursement handling;

    b) set ``ParachainStatus = ERROR`` and add ``LIQUIDATION`` to ``Errors``,

    c) emit ``ExecuteStatusUpdate(ParachainStatus, [LIQUIDATION], [],`` ``"Undercollateralized Vault 'vault' is being liquidated")``
  
5. Return


.. _reportOracleOffline:

reportOracleOffline
--------------------

A Staked Relayer reports that the :ref:`oracle` is offline. This function checks if the last exchange rate data in the Exchange Rate Oracle is indeed older than the indicated threshold. 

.. note:: Status updates triggered by this function require no Staked Relayer vote, as the report can be programmatically verified by the BTC Parachain.

Specification
.............

*Function Signature*

``reportOracleOffline()``



*Events*

* ``ExecuteStatusUpdate(newStatusCode, addErrors, removeErrors, msg)`` - emits an event indicating the status change, with ``newStatusCode`` being the new ``StatusCode``, ``addErrors`` the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``), ``removeErrors`` the set of to-be-removed ``ErrorCode`` entries, and ``msg`` the detailed reason for the status update. 

*Errors*

* ``ERR_STAKED_RELAYERS_ONLY = "This action can only be executed by Staked Relayers"``: The caller of this function was not a Staked Relayer. Only Staked Relayers are allowed to suggest and vote on BTC Parachain status updates.
* ``ERR_ORACLE_ONLINE = "The exchange rate oracle shows up-to-date data"``: The :ref:`oracle` does not appear to be offline. 

.. *Substrate* ::

  fn reportOracleOffline() -> Result {...}

Function Sequence
.................

1. Check that the caller of this function is indeed a Staked Relayer. Return ``ERR_STAKED_RELAYERS_ONLY`` if this check fails.

2. Retrieve the UNIX timestamp of the last exchange rate data submission to :ref:`oracle` via :ref:`getLastExchangeRateTime`.

3. If the current (UNIX) time minus ``LastExchangeRateTime`` is below ``MaxDelay``, return ``ERR_ORACLE_ONLINE`` error.

4. Otherwise, the :ref:`oracle` appears to be offline.

    a) set ``ParachainStatus = ERROR`` and add ``ORACLE_OFFLINE`` to ``Errors``,

    b) emit ``ExecuteStatusUpdate(ParachainStatus, [ORACLE_OFFLINE], [],`` ``"Exchange Rate Oracle is missing up to date data.")``
  
5. Return


.. _recoverFromLIQUIDATION:

recoverFromLIQUIDATION
----------------------

Internal function. Recovers the BTC Parachain state from a ``LIQUIDATION`` error and sets ``ParachainStatus`` to ``RUNNING`` if there are no other errors.

.. attention:: Can only be called from :ref:`vault-registry` (:ref:`redeemTokensLiquidation` function).

Specification
.............

*Function Signature*

``recoverFromLIQUIDATION()``

*Events*

* ``ExecuteStatusUpdate(newStatusCode, addErrors, removeErrors, msg)`` - emits an event indicating the status change, with ``newStatusCode`` being the new ``StatusCode``, ``addErrors`` the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``), ``removeErrors`` the set of to-be-removed ``ErrorCode`` entries,, and ``msg`` the detailed reason for the status update. 

.. *Substrate* ::

  fn recoverFromLIQUIDATE() -> Result {...}

Function Sequence
.................

1. Remove ``LIQUIDATION`` from ``Errors``

2. If ``Errors`` is empty, set ``ParachainStatus`` to ``RUNNING``

3. Emit ``ExecuteStatusUpdate(ParachainStatus, [], [LIQUIDATION], "Recovered from LIQUIDATION error.")`` event.


.. _recoverFromORACLEOFFLINE:

recoverFromORACLEOFFLINE
-------------------------

Internal function. Recovers the BTC Parachain state from a ``ORACLE_OFFLINE`` error and sets ``ParachainStatus`` to ``RUNNING`` if there are no other errors.

.. attention:: Can only be called from :ref:`oracle`.

Specification
.............

*Function Signature*

``recoverFromORACLEOFFLINE()``

*Events*

* ``ExecuteStatusUpdate(newStatusCode, addErrors, removeErrors, msg)`` - emits an event indicating the status change, with ``newStatusCode`` being the new ``StatusCode``, ``addErrors`` the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``), ``removeErrors`` the set of to-be-removed ``ErrorCode`` entries,, and ``msg`` the detailed reason for the status update. 

.. *Substrate* ::

  fn recoverFromORACLEOFFLINE() -> Result {...}

Function Sequence
.................

1. Remove ``ORACLE_OFFLINE`` from ``Errors``

2. If ``Errors`` is empty, set ``ParachainStatus`` to ``RUNNING``

3. Emit ``ExecuteStatusUpdate(ParachainStatus, [], [ORACLE_OFFLINE], "Recovered from ORACLE_OFFLINE error.")`` event.


.. _recoverFromBTCRelayFailure:

recoverFromBTCRelayFailure
---------------------------

Internal function. Recovers the BTC Parachain state from a ``NO_DATA_BTC_RELAY`` or ``INVALID_BTC_RELAY`` error (when a chain reorganization occurs and the new main chain has no errors) and sets ``ParachainStatus`` to ``RUNNING`` if there are no other errors.

.. attention:: Can only be called from :ref:`btc-relay`.

Specification
.............

*Function Signature*

``recoverFromBTCRelayFailure()``

*Events*

* ``ExecuteStatusUpdate(newStatusCode, addErrors, removeErrors, msg)`` - emits an event indicating the status change, with ``newStatusCode`` being the new ``StatusCode``, ``addErrors`` the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``), ``removeErrors`` the set of to-be-removed ``ErrorCode`` entries, and ``msg`` the detailed reason for the status update. 

.. *Substrate* ::

  fn recoverFromBTCRelayFailure() -> Result {...}

Function Sequence
.................

1. Remove ``NO_DATA_BTC_RELAY`` and ``INVALID_BTC_RELAY`` from ``Errors``

2. If ``Errors`` is empty, set ``ParachainStatus`` to ``RUNNING``

3. Emit ``ExecuteStatusUpdate(ParachainStatus, [], [INVALID_BTC_RELAY, NO_DATA_BTC_RELAY] "Recovered from BTC Relay error due to new main chain (reorganization).")`` event.


Events
~~~~~~~

RegisterStakedRelayer
----------------------

Emit an event stating that a new Staked Relayer was registered and provide information on the Staked Relayer's stake

*Event Signature*

``RegisterStakedRelayer(StakedRelayer, collateral)``

*Parameters*

* ``stakedRelayer``: newly registered staked Relayer
* ``stake``: stake provided by the staked relayer upon registration 

*Functions*

* :ref:`registerStakedRelayer`

.. *Substrate* ::

  RegisterStakedRelayer(AccountId, Balance);


DeRegisterStakedRelayer
-------------------------

Emit an event stating that a Staked Relayer has been de-registered 

*Event Signature*

``DeRegisterStakedRelayer(StakedRelayer)``

*Parameters*

* ``stakedRelayer``: account identifier of de-registered Staked Relayer

*Functions*

* :ref:`deRegisterStakedRelayer`

.. *Substrate* ::

  DeRegisterStakedRelayer(AccountId);


StatusUpdateSuggested
---------------------

Emits an event indicating a status change of the BTC Parachain.

*Event Signature*

* ``StatusUpdateSuggested(newStatusCode, addErrors, removeErrors, msg, stakedRelayer)`` 

*Parameters*

* ``newStatusCode``: the new ``StatusCode``
* ``addErrors``: the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``)
* ``removeErrors``: the set of to-be-removed ``ErrorCode`` entries
* ``msg``: the detailed message provided by the function caller
* ``stakedRelayer``: the account identifier of the Staked Relayer suggesting the update.


*Functions*

* :ref:`suggestStatusUpdate`

.. *Substrate* ::

  StatusUpdateSuggested(StatusCode, BTreeSet<ErrorCode>, BTreeSet<ErrorCode>, String, AccountId);


VoteOnStatusUpdate
--------------------

Emit an event informing about the vote cast by a staked relayer on a pending status update.

*Event Signature*

``VoteOnStatusUpdate(statusUpdateId, stakedRelayer, vote)``:

*Parameters*

* ``statusUpdateId``: identifier of the ``StatusUpdate`` being voted upon
* ``stakedRelayer``: account identifier of voting staked relayer
* ``vote``: boolean vote cast by the ``stakedRelayer`` 

*Functions*

* :ref:`voteOnStatusUpdate`

.. *Substrate* ::

  VoteOnStatusUpdate(U256, AccountId, bool);

 


ExecuteStatusUpdate
--------------------

Emit an event when a BTC Parachain status update is executed

* ``ExecuteStatusUpdate(newStatusCode, addErrors, removeErrors, msg)`` -  with 


*Event Signature*

``ExecuteStatusUpdate(newStatusCode, addErrors, removeErrors, msg)``

*Parameters*

* ``newStatusCode``: the new ``StatusCode``
* ``addErrors``: the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``)
* ``removeErrors``: the set of to-be-removed ``ErrorCode`` entries
* ``msg``: the detailed reason for the status update.


*Functions*

* :ref:`executeStatusUpdate`
* :ref:`reportVaultTheft`
* :ref:`reportVaultUndercollateralized`
* :ref:`reportOracleOffline`
* :ref:`recoverFromLIQUIDATION`
* :ref:`recoverFromORACLEOFFLINE`
* :ref:`recoverFromBTCRelayFailure`


.. *Substrate* ::

  ExecuteStatusUpdate(StatusCode, BTreeSet<ErrorCode>, BTreeSet<ErrorCode>, String);


RejectStatusUpdate
--------------------
Emits an event when a BTC Parachain status change proposal is rejected.

*Event Signature*

 ``RejectStatusUpdate(newStatusCode, addErrors, removeErrors, msg)``

*Parameters*

* ``newStatusCode``: the new ``StatusCode``
* ``addErrors``: the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``)
* ``removeErrors``: the set of to-be-removed ``ErrorCode`` entries
* ``msg``: the detailed reason for the status update.


*Functions*

* :ref:`rejectStatusUpdate`

.. *Substrate* ::

  RejectStatusUpdate(StatusCode, BTreeSet<ErrorCode>, BTreeSet<ErrorCode>, String);


ForceStatusUpdate
-------------------

Emit an event indicating a forced status change of the BTC Parachain, triggered by the Governance Mechanism. 


*Event Signature*

``ForceStatusUpdate(newStatusCode, addErrors, removeErrors, msg)``

*Parameters*

* ``newStatusCode``: the new ``StatusCode``
* ``addErrors``: the set of to-be-added ``ErrorCode`` entries (if the new status is ``Error``)
* ``removeErrors``: the set of to-be-removed ``ErrorCode`` entries
* ``msg``: the detailed reason for the status update.


*Functions*

* :ref:`forceStatusUpdate`

.. *Substrate* ::

  ForceStatusUpdate(StatusCode, BTreeSet<ErrorCode>, BTreeSet<ErrorCode>, String);



SlashStakedRelayer
-------------------

Emits an event indicating that a Staked Relayer has been slashed.


*Event Signature*

``SlashStakedRelayer(stakedRelayer)``

*Parameters*

* ``stakedRelayer``: account identifier of the slashed staked relayer.

*Functions*

* :ref:`slashStakedRelayer`

.. *Substrate* ::

  SlashStakedRelayer(AccountId);



ReportVaultTheft
-------------------

Emits an event when a Vault has been accused of theft.

*Event Signature*

``ReportVaultTheft(vault)``

*Parameters*

* ``vault``: account identifier of the Vault accused of theft. 

*Functions*

* :ref:`reportVaultTheft`

.. *Substrate* ::

  ReportVaultTheft(AccountId)


``ERR_NOT_REGISTERED``

* **Message**: "This AccountId is not registered as a Staked Relayer."
* **Function**: :ref:`deRegisterStakedRelayer`, :ref:`slashStakedRelayer`
* **Cause**: The given account identifier is not registered. 

``ERR_GOVERNANCE_ONLY``

* **Message**: "This action can only be executed by the Governance Mechanism"
* **Function**: :ref:`suggestStatusUpdate`, :ref:`forceStatusUpdate`, :ref:`slashStakedRelayer`
* **Cause**: The suggested status (``SHUTDOWN``) can only be triggered by the Governance Mechanism but the caller of the function is not part of the Governance Mechanism.

``ERR_STAKED_RELAYERS_ONLY``

* **Message**: "This action can only be executed by Staked Relayers"
* **Function**: :ref:`suggestStatusUpdate`, :ref:`voteOnStatusUpdate`, :ref:`reportVaultTheft`, :ref:`reportVaultUndercollateralized`
* **Cause**: The caller of this function was not a Staked Relayer. Only Staked Relayers are allowed to suggest and vote on BTC Parachain status updates.
  
``ERR_STATUS_UPDATE_NOT_FOUND``

* **Message**: "No StatusUpdate found with given identifier"
* **Function**: :ref:`voteOnStatusUpdate`, :ref:`executeStatusUpdate`, :ref:`rejectStatusUpdate`
* **Cause**: No ``StatusUpdate`` with the given ``statusUpdateId`` exists in ``StatusUpdates``.

``ERR_INSUFFICIENT_YES_VOTES``

* **Message**: "Insufficient YES votes to execute this StatusUpdate"
* **Function**: :ref:`executeStatusUpdate`
* **Cause**: The ``StatusUpdate`` does not have enough "Yes" votes to be executed.

``ERR_INSUFFICIENT_NO_VOTES``

* **Message**: "Insufficient YES votes to reject this StatusUpdate"
* **Function**: :ref:`rejectStatusUpdate`
* **Cause**: The ``StatusUpdate`` does not have enough "No" votes to be rejected. 

``ERR_ALREADY_REPORTED``

* **Message**: "This txId has already been logged as a theft by the given Vault"
* **Function**: :ref:`reportVaultTheft`
* **Cause**: This transaction / Vault combination has already been reported.


``ERR_VAULT_NOT_FOUND``

* **Message**: "There exists no Vault with the given account id"
* **Function**: :ref:`reportVaultTheft`, :ref:`reportVaultUndercollateralized`
* **Cause**:  The specified Vault does not exist. 

``ERR_ALREADY_LIQUIDATED``

* **Message**: "This Vault is already being liquidated"
* **Function**: :ref:`reportVaultTheft`
* **Cause**:  The specified Vault is already being liquidated.

``ERR_VALID_REDEEM_OR_REPLACE``

* **Message**: "The given transaction is a valid Redeem or Replace execution by the accused Vault"
* **Function**: :ref:`reportVaultTheft`
* **Cause**: The given transaction is associated with a valid :ref:`redeem-protocol` or :ref:`replace-protocol`.


``ERR_VALID_MERGE_TRANSACTION``

* **Message**: "The given transaction is a valid 'UTXO merge' transaction by the accused Vault"
* **Function**: :ref:`reportVaultTheft`
* **Cause**: The given transaction represents an allowed "merging" of UTXOs by the accused Vault (no BTC was displaced).

``ERR_COLLATERAL_OK``
* **Message**: "The accused Vault's collateral rate is above the liquidation threshold"
* **Function**: :ref:`reportVaultUndercollateralized`
* **Cause**: The accused Vault's collateral rate is above ``LiquidationCollateralThreshold``.

``ERR_ORACLE_ONLINE``
* **Message**: "The exchange rate oracle shows up-to-date data"
* **Function**: :ref:`reportOracleOffline`
* **Cause**: The :ref:`oracle` does not appear to be offline. 

* **Message**: 
* **Function**: :ref:`reportVaultTheft`
* **Cause**: 