Performance and Costs
==============================

Estimation of Storage Costs
----------------------------


BTC-Relay Optimizations
-----------------------

Pruning
~~~~~~~

**Idea**: Consturct ``_mainChain`` as a FIFO queue and remove sufficiently old block headers from ``_blockHeaders``. 


**Goal**: Prevent the tracked main chain from growing indefinitely. While this may be acceptable for Bitcoin alone, Polkadot is exepcted to connect to numerous blockchains and tracking the entire blockchain history for each would unnecessarily bloat parachains (especially if parachains are non-exclusive to specific blockchains).


**Reasoning**: The pruning depth can be set to e.g. 10 000 blocks. There is no need to store more block headers, as verification of transactions contained in older blocks can still be performed by requiring users to re-spend. (we can also probably look up some stats on the spending behaviour in Bitcoin, i.e., UTXOs of which age are spent most frequently and when at which "depth" the spending behavior declines) 


Batch Submissions
~~~~~~~~~~~~~~~~~~


Outlook on Sub-Linear Verification in Bitcoin
---------------------------------------------

Reference to FlyClient and NiPoPoWs.

