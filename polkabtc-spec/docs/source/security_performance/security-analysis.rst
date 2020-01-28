.. _security-analysis:

Security Analysis
==================

Collateral
~~~~~~~~~~

Add operation modes for each Vault
* Secure Operation
* Buffered Collateral
* Liquidation

.. _griefing:

Griefing
~~~~~~~~

Add details about griefing here.


Concurrency
~~~~~~~~~~~


.. todo:: Handling of concurrent redeem procedures: we need to make sure that a vault cannot be used in multiple redeem requests in parallel if that would exceed his amount of locked BTC. **Example**: If the vault has 5 BTC locked and receives two redeem requests for 5 PolkaBTC/BTC, he can only fulfil one and would lose his collateral with the other!

.. todo:: Handling of concurrent issue and redeem procedures: a vault can be used in parallel for issue and redeem requests. In the issue procedure, the vault's ``committedTokens`` are already increased when the issue request is created. However, this is before (!) the BTC is sent to the vault. If we used these ``committedTokens`` as a basis for redeem requests, we might end up in a case where the vault does not have enough BTC. **Example**: The vault already has 3 BTC in custody from previous successful issue procedures. A user creates an issue request for 2 PolkaBTC. At this point, the ``committedTokens`` by this vault are 5. However, his BTC balance is only 3. Now, a user could create a redeem request of 5 PolkaBTC and the vault would have to fulfill those. The user could then cancel the issue request over 2 PolkaBTC. The vault could only send 3 BTC to the user and would lose his deposit. Or the vault just loses his deposit without sending any BTC. 
