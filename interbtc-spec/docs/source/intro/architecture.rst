Architecture
============

interBTC consists of four different actors and eight modules. The component further uses two additional modules, the BTC-Relay component and the Parachain Governance mechanism.

Actors
~~~~~~

There are four main participant roles in the system. A high-level overview of all modules and actors, as well as interactions between them, is provided in :numref:`high-level` below.

- **Vaults**: Vaults are collateralized intermediaries that are active on both the backing blockchain (Bitcoin) and the issuing blockchain to provide collateral in DOT. They receive and hold BTC from users who wish to create interBTC tokens. When a user destroys interBTC tokens, a vault releases the corresponding amount of BTC to the user's BTC address. Vaults interact with the following modules directly: :ref:`vault-registry`, :ref:`redeem-protocol`, and :ref:`replace-protocol`.

  - **Reporting**: Monitors that other Vaults do not move locked BTC on Bitcoin without prior authorization by the BTC Parachain (i.e., through one of the :ref:`redeem-protocol`, :ref:`replace-protocol` or :ref:`refund-protocol` protocols).
  - **Relaying**: Submits block headers published on Bitcoin to the :ref:`btc-relay`.

- **Users**: Users interact with the BTC Parachain to create, use (trade/transfer/...), and redeem Bitcoin-backed interBTC tokens. Since the different protocol phases can be executed by different users, we introduce the following *sub-roles*:

  - **Requester**: A user that locks BTC with a vault on Bitcoin and issues interBTC on the BTC Parachain. Interacts with the :ref:`issue-protocol` module.
  - **Sender** and **Receiver**: A user (Sender) that sends interBTC to another user (Receiver) on the BTC Parachain. Interacts with the :ref:`treasury-module` module. 
  - **Redeemer**: A user that destroys interBTC on the BTC Parachain to receive the corresponding amount of BTC on the Bitcoin blockchain from a Vault. Interacts with the :ref:`redeem-protocol` module. 

- **Governance Mechanism**: The Parachain Governance Mechanism monitors the correct operation of the BTC Parachain. Interacts with the :ref:`security` module and can manually update the parameterization of all components in the BTC Parachain.

.. note:: The exact composition of the Governance Mechanism is to be defined by Polkadot.  

Modules
~~~~~~~

The eight modules in interBTC plus the BTC-Relay and Governance Mechanism interact with each other, but all have distinct logical functionalities. The figure below shows them.

The specification clearly separates these modules to ensure that each module can be implemented, tested, and verified in isolation. The specification follows the principle of abstracting the internal implementation away and providing a clear interface. This should allow optimisation and improvements of a module with minimal impact on other modules.

.. _high-level:

.. figure:: ../figures/architecture.png
    :alt: architecture diagram

    High level overview of the BTC Parachain. interBTC consists of seven modules. The Oracle module stores the exchange rates based on the input of centralized and decentralized exchanges. The Treasury module maintains the ownership of interBTC, the VaultRegistry module stores information about the current Vaults in the system, and the Issue, Redeem and Replace modules expose funcitons and maintain data related to the respective sub protocols. The StabilizedCollateral modules handles vault collateralization, stabilization against exchange rate fluctuations and automatic liquidation. BTC-Relay tracks the Bitcoin main chain and verifies transaction inclusion. The Parachain Governance maintains correct operation of the BTC Parachain and intervenes / halts operation if necessary. 


Oracle
------

The Oracle module maintains the exchange rate value between the asset that is used to collateralize Vaults (e.g. DOT) and the wrapped asset (interBTC).
Governance authorizes trusted third parties to feed the current exchange rates into the system for a nominal fee.


Treasury
--------

The Treasury module maintains the ownership and balance of interBTC token holders. It allows respective owners of interBTC to send their tokens to other entities  and to query their balance.
Further, it tracks the total supply of tokens.

Vault Registry
--------------

The VaultRegistry module manages the Vaults in the system.It allows Managing the list of active Vaults in the system and the necessary data (e.g. BTC addresses) to execute the Issue, Redeem, and Replace protocols.

This module also handles the collateralization rates of Vaults and reacts to exchange rate fluctuations.
Specifically, it:

* stores how much collateral each vault provided and how much of that collateral is allocated to interBTC.
* tracks the collateralization rate of each vault and triggers measures in case the rate declines, e.g. due to exchange rate fluctuations.
* triggers, as a last resort, automatic liquidation if a vault falls below the minimum collateralization rate.

Collateral
----------

The Collateral module is the central storage for any collateral that is collected in any other module.
It is allows for three simple operations: locking collateral by a party, releasing collateral back to the original party that locked this collateral, and last, slashing collateral where the collateral is relocated to a party other than the one that locked the collateral.

Issue
-----

The Issue module handles the issuing process for interBTC tokens. It tracks issue requests by users, handles the collateral provided by users as griefing protection and exposes functionality for users to prove correct locking on BTC with Vaults (interacting with the endpoints in BTC-Relay). 

Redeem
------

The Redeem module handles the redeem process for interBTC tokens. It tracks redeem requests by users, exposes functionality for Vaults to prove correct release of BTC to users (interacting with the endpoints in BTC-Relay), and handles the Vault's collateral in case of success (free) and failure (slash). 


Replace
-------

The Replace module handles the replace process for Vaults. 
It tracks replace requests by existing Vaults, exposes functionality for to-be-replaced Vaults to prove correct transfer of locked BTC to new vault candidates (interacting with the endpoints in BTC-Relay), and handles the collateral provided by participating Vaults as griefing protection.


Security
--------

The Security module is the kernel of the BTC Parachain. It is imported by most modules to ensure that the chain is running.


Governance Mechanism
--------------------

The Governance Mechanism handles correct operation of the BTC Parachain.

.. note:: The Governance Mechanism is not part of this specification. The BTC Parachain simply expects continous operation of the BTC Parachain.

Interactions
~~~~~~~~~~~~

We provide a detailed overview of the function calls between the different modules in :numref:`fig-interactions`.

.. _fig-interactions:
.. figure:: ../figures/detailed-architecture.png
    :alt: detailed architecture diagram

    Detailed architecture of the BTC Parachain, showing all actors, components and their interactions.
