Architecture
============

The PolkaBTC implementation consists of five different actors, five modules, and is integrated with the BTCRelay module in the same BTC Parachain.

Actors
~~~~~~

There are five actors in the system.

- **Vault**: A collateralized intermediary for backing the issue of PolkaBTC and fulfilling redeem requests.
- **Requester**: A user that locks BTC on the Bitcoin blockchain and issues PolkaBTC on the BTC Parachain.
- **Sender**: A user that sends PolkaBTC to a Receiver on the BTC Parachain.
- **Receiver**: A user that receives PolkaBTC on the BTC Parachain.
- **Redeemer**: A user that destroys PolkaBTC on the BTC Parachain to receive BTC on the Bitcoin blockchain through the Vault.

Modules
~~~~~~~

The five modules in PolkaBTC interact with each other, but all have distinct logical functionalities. The figure below shows them.

The specification clearly separates these modules to ensure that each module can be implemented, tested, and verified in isolation. The specification follows the principle of abstracting the internal implementation away and providing a clear interface. This should allow optimisation and improvements of a module with minimal impact on other modules.

.. figure:: ../figures/PolkaBTC-Architecture.png
    :alt: architecture diagram

    PolkaBTC consists of five modules. The Oracle module stores the exchange rates based on the input f centralized and decentralized exchanges. The Treasury module maintains the ownership of PolkaBTC, the VaultRegistry module stores information about the current Vaults in the system, and the Issue and Redeem module cotain data and funciton related to their respective sub protocols.

Treasury
--------

The Treasury module maintains the ownership and balance of PolkaBTC token holders. It allows respective owners of PolkaBTC to send their tokens to other entities via the :ref:`Transfer protocol <transfer-protocol>` and to query their balance.
Further, it exposes the total supply of tokens.

Oracle
------

The Oracle module maintains the ``ExchangeRate`` value between the asset that is used to collateralize Vaults (DOT) and the to-be-issued asset (BTC).
In the proof-of-concept the Oracle is operated by a trusted third party to feed the current exchange rates into the system.

VaultRegistry
-------------

The VaultRegistry module manages the Vaults in the system. It stores how much collateral each Vault provided and how much of that collateral is allocated to PolkaBTC. Further, this module implements the :ref:`Replace protocol <replace-protocol>`.

Issue
-----

The Issue model stores data related to issuing PolkaBTC tokens. It includes the methods for the :ref:`Issue protocol <issue-protocol>`.

Redeem
------

Last, the Redeem module includes specific data required to redeem PolkaBTC back on the Bitcoin blockchain. It includes the methods necessary for the :ref:`Redeem protocol <redeem-protocol>`.


