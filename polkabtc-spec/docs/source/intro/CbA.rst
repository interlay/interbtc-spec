Cryptocurrency-backed Assets
============================

Building trustless cross-blockchain trading protocols is challenging.
Centralized exchanges thus remain the preferred route to executing transfers across blockchains.
However, these services require trust and therefore undermine the very nature of the blockchains on which they operate.
To overcome this, several decentralized exchanges have recently emerged which offer support for *commit-reveal* atomic cross-chain swaps (ACCS).

Commit-reveal ACCS, most notably based on `HTCLs <https://en.bitcoin.it/wiki/Hashed_Timelock_Contracts>`_, enable the trustless exchange of cryptocurrencies across blockchains.
To this date, this is the only mechanism to have been deployed in production.
However, commit-reveal ACCS face numerous challenges:


+ **Long waiting times:** Each commit-reveal ACCS requires multiple transactions to occur on all
  involved blockchains (commitments and revealing of secrets).
+ **High costs:** Publishing multiple transaction per swap results in high fees to maintain such a system.
+ **Strict online requirements:** Both parties must be online during the ACCS. Otherwise, the trade fails or, in the worst case, *loss of funds is possible*.
+ **Out-of-band channels:** Secure operation requires users to exchange additional data *off-chain* (revocation commitments). 
+ **Race conditions:** Commit-reveal ACCS use time-locks to ensure security. Synchronizing time across
  blockchains, however, is challenging and opens up risks to race conditions.
+ **Inefficiency:** Finally, commit-reveal ACCS are *one-time*. That is, all of the above challenges are faced with each and every trade.

Commit-reveal ACCS have been around since 2012. The practical challenges explain their limited use in practice.





Recommended Background Reading
------------------------------

+ **XCLAIM: Trustless, Interoperable, Cryptocurrency-backed Assets**. *IEEE Security and Privacy (S&P).* Zamyatin, A., Harz, D., Lind, J., Panayiotou, P., Gervais, A., & Knottenbelt, W. (2019).
+ **Enabling Blockchain Innovations with Pegged Sidechains**. *Back, A., Corallo, M., Dashjr, L., Friedenbach, M., Maxwell, G., Miller, A., Poelstra A., Timon J.,  & Wuille, P*. (2019)
+ **SoK: Communication Across Distributed Ledgers**. *Cryptology ePrint Archiv, Report 2019/1128*. Zamyatin A, Al-Bassam M, Zindros D, Kokoris-Kogias E, Moreno-Sanchez P, Kiayias A, Knottenbelt WJ. (2019)
+ **Proof-of-Work Sidechains**. *Workshop on Trusted Smart Contracts, Financial Cryptography* Kiayias, A., & Zindros, D. (2018)

