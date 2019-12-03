Security Analysis
==================


Security Parameter *k*
----------------------



Failure Modes: Halting and Recovery
------------------------------------

* “HALT” means that verification calls to the BTC-Relay from other contracts/users of the parachain are disabled (e.g. transaction verification). Submission of block headers is still enabled - this is necessary for automatic recovery (e.g. submission of correct/valid main chain).

.. note:: Consider whether BTC-Relay should be completely halted, or if verification of “older” transactions (more confirmations that the security parameter k) are still allowed. 

* “RESUME” - resume operation. Can be triggered manually or automatically, depending on reason for HALT. 


* “SHUTDOWN” disables the entire operation of the BTC-Relay (even block header submission). Can be useful if manually disabled by Validator Committee (e.g. to react to spam attacks, handle hard forks etc.)


* “RESTART”: enables block header submission, but nothing else. RESUME must be called in addition, to enable full functionality. 


