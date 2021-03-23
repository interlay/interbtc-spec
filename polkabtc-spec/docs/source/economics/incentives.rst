.. _incentives:

Economic Incentives
===================

Incentives are the core of decentralized systems. Fundamentally, actors in decentralized systems participate in a game where each actor attempts to maximize its utility. Designs of such decentralized systems need to encode a mechanism that provides clear incentives for actors to adhere to protocol rules while discouraging undesired behavior. Specifically, actors make risk-based decisions: payoffs associated with the execution of certain actions are compared against the risk incurred by the action. The BTC Parachain, being an open system with multiple distinct stakeholders, must hence offer a mechanism to assure honest participation outweighs subversive strategies.

The overall objective of the incentive mechanism is an optimization problem with private information in a dynamic setting. Users need to pay fees to Vaults in return for their service. On the one hand, user fees should be low enough to allow them to profit from having PolkaBTC (e.g., if a user stands to gain from earning interest in a stablecoin system using PolkaBTC, then the fee for issuing PolkaBTC should not outweigh the interest gain). On the other hand, fees need to be high enough to encourage Vaults and Staked Relayers to lock their DOT in the system and operate Vault/Staked Relayer clients. This problem is amplified as the BTC Parachain does not exist in isolation and Vaults/Staked Relayers can choose to participate in other protocols (e.g., staking, stablecoin issuance) as well. In the following we outline the constraints we see, a minimal viable incentive model, and pointers to further research questions we plan to solve by getting feedback from potential Vaults and Staked Relayers as well as quantitative modeling.


Roles
~~~~~

We can classify four groups of users, or agents, in the BTC Parachain system. This is mainly based on their prior cryptocurrency holdings - namely BTC and DOT.

Users
-----

- **Protocol role** Users lock BTC with Vaults to create PolkaBTC. They hold and/or use PolkaBTC for payments, lending, or investment in financial products. At some point, users redeem PolkaBTC for BTC by destroying the backed assets.
- **Economics** A user holds BTC and has exposure to an exchange rate from BTC to other assets. A user’s incentives are based on the services (and their rewards) available when issuing PolkaBTC.
- **Risks** A user gives up custody over their BTC to a Vault. The Vault is over-collateralized in DOT (i.e., compared to the USD they will lose when taking away the user’s BTC), however, in a market crisis with significant price drops and liquidity shortages, Vaults might choose to keep the BTC. Users will be reimbursed with DOT in that case - not the currency they initially started out with.

Vaults
------

- **Protocol role** Vaults lock up DOT collateral in the BTC Parachain and hold users’ BTC (i.e., receive custody). When users wish to redeem PolkaBTC for BTC, Vaults release BTC to users according to the events received from the BTC Parachain.
- **Economics** Vaults hold DOT and thus have exposure to the DOT price against other assets. Vaults inherently make a bet that DOT will increase in value against other assets – otherwise they would simply exchange DOT against their preferred asset(s). This is a simplified view of the underlying problem. In reality, we need to additionally consider nominated vaults as well as vault pooling. Moreover, the inflation of DOT will play a major role in selection of the asset that fees should be paid in.
- **Risks** A Vault backs a set of PolkaBTC with DOT collateral. If the exchange rate of the DOT/BTC pair drops the Vault stands at risk to not be able to keep the required level of over-collateralization. This risk can be elevated by a shortage of liquidity.

Staked Relayers
---------------

- **Protocol role** Staked Relayers run Bitcoin full nodes and submit block headers to BTC-Relay, ensuring it remains up to date with Bitcoin’s state. They also report failures occurring on Bitcoin (missing transactional data or invalid blocks) and report misbehaving Vaults who have allegedly stolen BTC (move BTC outside of BTC Parachain constraints). Staked Relayers lock DOT as collateral to disincentivize false ﬂagging on Vaults and Bitcoin failures.
- **Economics** Staked Relayers are exposed to similar mechanics as Vaults, since they also hold DOT. However, they have no direct exposure to the BTC/DOT exchange rate, since they (typically, at least as part of the BTC Parachain) do not hold BTC. As such, Staked Relayers can purely be motivated to earn interest on DOT, but can also have the option to earn interest in PolkaBTC and optimize their holdings depending on the best possible return at any given time.
- **Risks** Staked Relayers need to keep an up-to-date Bitcoin full node running to receive the latest blocks and be able to verify transaction availability and validity. They might risk voting on wrong status update proposals for the BTC Parachain if their node is being attacked, e.g. eclipse or DoS attacks.


Collators
---------

- **Protocol role** Collators are full nodes on both a parachain and the Relay Chain. They collect parachain transactions and produce state transition proofs for the validators on the Relay Chain. They can also send and receive messages from other parachains using XCMP.
- More on collators can be found in the Polkadot wiki: https://wiki.polkadot.network/docs/en/learn-collator#docsNav




