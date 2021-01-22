.. _security-analysis:

Security Analysis
=================

Replay Attacks
~~~~~~~~~~~~~~

Without adequate protection, inclusion proofs for transactions on Bitcoin can be **replayed** by: (i) the user to trick PolkaBTC component into issuing duplicate PolkaBTC tokens and (ii) the vault to reuse a single transaction on Bitcoin to falsely prove multiple redeem requests. 
A simple and practical mitigation is to introduce unique identifiers for each execution of :ref:`issue-protocol` and :ref:`redeem-protocol` and require transactions on Bitcoin submitted to the BTC-Relay of these protocols to contain the corresponding identifier.

In this specification, we achieve this by requiring that both, users and vaults, prepare a transaction with at least two outputs. One output is an OP_RETURN with a unique hash created in the :ref:`security` module.

Counterfeiting
~~~~~~~~~~~~~~

A vault which receives lock transaction from a user during :ref:`issue-protocol` could use these coins to re-execute the issue itself, creating counterfeit PolkaBTC.
This would result in PolkaBTC being issued for the same amount of lock transaction breaking **consistency**, i.e., :math:`|locked_BTC| < |PolkaBTC|`. 
To this end, the PolkaBTC component forbids vaults to move locked funds lock transaction received during :ref:`issue-protocol` and considers such cases as theft.
This theft is observable by any user.
However, we used the specific roles of Staked Relayers to report theft of BTC.
To restore **Consistency**, the PolkaBTC component slashes the vault's entire collateral and executes automatic liquidation, yielding negative utility for the vault.  
To allow economically rational vaults to move funds on the BTC Parachain we use the :ref:`replace-protocol`, a non-interactive atomic cross-chain swap (ACCS) protocol based on cross-chain state verification.


Permanent Blockchain Splits
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Permanent chain splits or *hard forks* occur where consensus rules are loosened or conflicting rules are introduced, resulting in multiple instances of the same blockchain.
Thereby, a mechanism to differentiate between the two resulting chains *replay protection* is necessary for secure operation. 

Backing Chain
-------------

If replay protection is provided after a permanent split of Bitcoin, the BTC-Relay must be updated to verify the latter for Bitcoin (or Bitcoin' respectively).
If no replay protection is implemented, BTC-Relay will behave according to the protocol rules of Bitcoin for selecting the "main" chain. For example, it will follow the chain with most accumulated PoW under Nakamoto consensus. 

Issuing Chain
-------------

A permanent fork on the issuing blockchain results in two chains I and I' with two instances of the PolkaBTC component identified by the same public keys. To prevent an adversary exploiting this to execute replay attacks, both users and vaults must be required to include a unique identifier (or a digest thereof) in the transactions published on Bitcoin as part of :ref:`issue-protocol` and :ref:`redeem-protocol` (in addition to the identifiers introduces in Replay Attacks).

Next, we identify two possibilities to synchronize Bitcoin balances on I and I': (i) deploy a chain relay for I on I' and vice-versa to continuously synchronize the PolkaBTC components or (ii) redeploy the PolkaBTC component on both chains and require users and vaults to re-issue Bitcoin, explicitly selecting I or I'.

Denial-of-Service Attacks
~~~~~~~~~~~~~~~~~~~~~~~~~

PolkaBTC is decentralized by design, thus making denial-of-service (DoS) attacks difficult. Given that any user with access to Bitcoin and BTC Parachain can become a vault, an adversary would have to target all vaults simultaneously. Where there are a large number of vaults, this attack would be impractical and expensive to perform. Alternatively, an attacker may try to target the PolkaBTC component. However, performing a DoS attack against the PolkaBTC component is equivalent to a DoS attack against the entire issuing blockchain or network, which conflicts with our assumptions of a resource bounded adversary and the security models of Bitcoin and BTC Parachain. Moreover, should an adversary perform a Sybil attack and register as a large number of vaults and ignore service requests to perform a DoS attack, the adversary would be required to lock up a large amount of collateral to be effective. This would lead to the collateral being slashed by the PolkaBTC component, making this attack expensive and irrational.

Fee Model Security: Sybil Attacks and Extortion
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

While the exact design of the fee model lies beyond the scope of this paper, we outline the following two restrictions, necessary to protect against attacks by malicious vaults.

Sybil Attacks
-------------

To prevent financial gains from Sybil attacks, where a single adversary creates multiple low collateralized vaults, the PolkaBTC component can enforce (i) a minimum necessary collateral amount and (ii) a fee model based on issued volume, rather than "pay-per-issue". 
In practice, users can in principle easily filter out low-collateral vaults.

Extortion
---------

Without adequate restrictions, vaults could set extreme fees for executing :ref:`redeem-protocol`, making redeeming of Bitcoin unfeasible. 
To this end, the PolkaBTC component must enforce that either (i) no fees can be charged for executing :ref:`redeem-protocol` or (ii) fees for redeeming must be pre-agreed upon during \issue.


.. Collateral
.. ~~~~~~~~~~

.. Collateral thresholds>
.. * Secure
.. * Auction
.. * PremiumRedeem
.. * Liquidation

.. .. not:: PolkaBTC can never be force-liquidated from users. Reason: the tokens could be used in other applications and replacing these with DOT could have negative side-effects. An alternative is to define a new token standard for this (future work).

.. _griefing:

Griefing
~~~~~~~~

Griefing describes the act of blocking a vaults collateral by creating "bogus" requests. There are two cases:

1. A user can create an issue request without the intention to issue tokens. The user "blocks" the vault's collateral for a specific amount of time. if enough users execute this, a legitimate user could possibly not find a vault with free collateral to start an issue request.
2. A vault can request to be replaced without the intention to be replaced. When another vault accepts the replace request, that vault needs to lock additional collateral. The requesting vault, however, could never complete the replace request to e.g. ensure that it will be able to serve more issue requests.

For both cases, we require the requesting parties to lock up a (small) amount of griefing collateral. This makes such attacks costly for the attacker.


Concurrency
~~~~~~~~~~~

We need to ensure that concurrrent issue, redeem, and replace requests are handled.

Concurrent redeem
-----------------

We need to make sure that a vault cannot be used in multiple redeem requests in parallel if that would exceed his amount of locked BTC. **Example**: If the vault has 5 BTC locked and receives two redeem requests for 5 PolkaBTC/BTC, he can only fulfil one and would lose his collateral with the other.

Concurrent issue and redeem
---------------------------

A vault can be used in parallel for issue and redeem requests. In the issue procedure, the vault's ``issuedTokens`` are already increased when the issue request is created. However, this is before (!) the BTC is sent to the vault. If we used these ``issuedTokens`` as a basis for redeem requests, we might end up in a case where the vault does not have enough BTC. **Example**: The vault already has 3 BTC in custody from previous successful issue procedures. A user creates an issue request for 2 PolkaBTC. At this point, the ``issuedTokens`` by this vault are 5. However, his BTC balance is only 3. Now, a user could create a redeem request of 5 PolkaBTC and the vault would have to fulfill those. The user could then cancel the issue request over 2 PolkaBTC. The vault could only send 3 BTC to the user and would lose his deposit. Or the vault just loses his deposit without sending any BTC. 

Solution
--------

We use seperate token balances to handle issue, replace, and redeem requests in the :ref:`Vault-registry`.
