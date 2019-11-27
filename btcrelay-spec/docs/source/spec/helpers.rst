Helper Methods
==============

There are several helper methods available that abstract Bitcoin internals away in the main function implementation.

sha256d
-------
Bitcoin uses a double SHA256 hash to protect against `"length-extension" attacks <https://en.wikipedia.org/wiki/Length_extension_attack>`_. 

*Function Signature*

``sha256d(data)``

*Parameters*

* ``data``: bytes encoded input.

*Returns*

* ``hash``: the double sha256 hash encodes as a bytes from ``data``.

Function Sequence
~~~~~~~~~~~~~~~~~

1. Hash ``data`` with sha256.
2. Hash the result of step 1 with sha256 and return.


nBitsToTarget
-------------


checkCorrectTarget
------------------


computeNewTarget
----------------


computeMerkle
-------------

The computeMerkle function calculates the root of the Merkle tree of transactions in a Bitcoin block. The root is calculated by hashing the transaction hash (``txId``), its position in the tree (``txIndex``), and the according hash in the ``merkleProof``. Further details are included in the `Bitcoin developer reference <https://bitcoin.org/en/developer-reference#parsing-a-merkleblock-message>`_. 

*Function Signature*

``computeMerkle(txId, txIndex, merkleProof)``

*Parameters*

* ``txId``: the hash of the transaction.
* ``txIndex``: index of transaction in the block's tx Merkle tree.
* ``merkleProof``: Merkle tree path (concatenated LE sha256 hashes).

*Returns*

* ``merkleRoot``: the hash of the Merkle root.

*Errors*

* ``ERR_MERKLE_PROOF = "Invalid Merkle Proof structure"``: raise an exception when the Merkle proof is malformed.


Function Sequence
~~~~~~~~~~~~~~~~~

1. Check if the length of the Merkle proof is 32 bytes long.

    a. If true, only the coinbase transaction is included in the block and the Merkle proof is the ``merkleRoot``. Return the ``merkleRoot``.
    b. If false, continue function execution.

2. Check if the length of the Merkle proof is greater or equal to 64 and if it is a  power of 2.

    a. If true, continue function execution.
    b. If false, raise ``ERR_MERKLE_PROOF``.

3. Calculate the ``merkleRoot``. For each 32 bytes long hash in the Merkle proof:

    a. Determine the position of transaction hash (or the last resulting hash) at either ``0`` or ``1``.
    b. Slice the next 32 bytes from the Merkle proof.
    c. Concatenate the transaction hash (or last resulting hash) with the 32 bytes of the Merkle proof in the right order (depending on the transaction/last calculated hash position).
    d. Calculate the double sha256 hash from the concatenated input with the `concatSha256d`_ function.
    e. Repeat until there are no more hashes in the ``merkleProof``.

4. The last resulting hash from step 3 is the Merkle root. Return ``merkleRoot``.

Example
~~~~~~~

Assume we have the following input:

* txId: ``330dbbc15169c538583073fd0a7708d8de2d3dc155d75b361cbf5c24b73f3586``
* txIndex: ``0``
* merkleProof: ``86353fb7245cbf1c365bd755c13d2dded808770afd73305838c56951c1bb0d33b635f586cf6c4763f3fc98b99daf8ac14ce1146dc775777c2cd2c4290578ef2e``

The ``computeMerkle`` function would go past step 1 as our proof is longer than 32 bytes. Next, step 2 would also be passed as the proof is equal to 64 bytes and a power of 2. Last we calculate the Merkle root in step 3 as shown below.

.. figure:: ../figures/computeMerkle.png
    :alt: Compute Merkle example execution.

    An example of the ``computeMerkle`` function with a transaction from a block that contains two transactions in total.


concatSha256d
----------------


*Function Signature*

``concatSha256d(left, right)``

*Parameters*

* ``left``: 32 bytes of input data that are added first.
* ``right``: 32 bytes of input data that are added second.

*Returns*

* ``hash``: the double sha256 hash encodes as a bytes from ``left`` and ``right``.

Function Sequence
~~~~~~~~~~~~~~~~~

1. Concatenate ``left`` and ``right`` into a 64 bytes.
2. Call the `sha256d`_ function to hash the concatenated bytes.
3. Return the hash.

Getters
-------
