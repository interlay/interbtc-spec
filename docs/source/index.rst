.. interbtc documentation master file

Welcome to the interBTC Technical Specification!
================================================

.. note:: Please note that this specification is a living document. The actual implementation might deviate from the specification. In case of deviations in the code, the code has priority over the specification.

.. toctree::
   :maxdepth: 2
   :caption: Introduction
   
   intro/at-a-glance
   intro/CbA
   intro/polkadot
   intro/xclaim-architecture
   intro/btcrelay-architecture
   intro/bitcoin
   intro/accepted-format
   spec/introduction
   
.. toctree::
   :maxdepth: 2
   :caption: XCLAIM Specification

   spec/collateral
   spec/fee
   spec/oracle
   spec/issue
   spec/refund
   spec/redeem
   spec/replace
   spec/security
   spec/relay
   spec/treasury
   spec/vault-registry
   spec/nomination
   spec/reward
   spec/staking
   spec/governance

.. toctree::
   :maxdepth: 2
   :caption: BTC-Relay Specification

   spec/btc-relay/data-model
   spec/btc-relay/functions
   spec/btc-relay/parser
   spec/btc-relay/helpers
   spec/btc-relay/events
   spec/btc-relay/errors

.. toctree::
   :maxdepth: 2
   :caption: Security and Performance

   security_performance/liquidations
   security_performance/xclaim-security
   security_performance/btcrelay-security
   security_performance/performance

.. toctree::
   :maxdepth: 2
   :caption: Economics

   economics/incentives
   economics/fees

.. toctree::
   :maxdepth: 2
   :caption: All the rest
   
   other/license
   other/interlay
