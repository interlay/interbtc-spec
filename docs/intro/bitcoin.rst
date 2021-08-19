.. _bitcoin-data-model:

Bitcoin Data Model
==================

This is a high-level overview of Bitcoin's data model. For the full details, refer to https://bitcoin.org/en/developer-reference. While the serialized versions of these structs are used in the bridge's API, they are parsed by the chain into a more convenient internal representation. See :ref:`data-model`. 

.. _bitcoinBlockHeader:

Block Headers
~~~~~~~~~~~~~
The `80 bytes block header <https://en.bitcoin.it/wiki/Protocol_documentation#Block_Headers>`_ encodes the following information:

.. note:: as per `bip64 <https://github.com/bitcoin/bips/blob/master/bip-0065.mediawiki#spv-clients>`_, blocks with a version number of less than 4 are rejected. As a consequence, blocks that were mined before December 2015 will not successfully parse in the bridge. This is acceptable, because the bridge is not expected to be initialized with such an old block as genesis.

.. tabularcolumns:: |l|l|l|L|

=====  ======================  =========  ======================================================================
Bytes  Parameter               Type       Description
=====  ======================  =========  ======================================================================
4      ``version``             i32        The block version to follow.
32     ``hashPrevBlock``       char[32]   The double sha256 hash of the previous block header.
32     ``merkleRoot``          char[32]   The double sha256 hash of the Merkle root of all transaction hashes in this block.
4      ``timestamp``           u32        The block timestamp included by the miner.
4      ``nBits``               u32        The target difficulty threshold, see also the `Bitcoin documentation <https://bitcoin.org/en/developer-reference#target-nbits>`_. 
4      ``nonce``               u32        The nonce chosen by the miner to meet the target difficulty threshold.
=====  ======================  =========  ======================================================================


Transactions
~~~~~~~~~~~~

A transaction is broadcasted in a serialized byte format (also called raw format). It consists of a variable size of bytes and has the following `format <https://en.bitcoin.it/wiki/Protocol_documentation#tx>`_. Both 'normal' transaction and transactions `segregated witness data <https://github.com/bitcoin/bips/blob/master/bip-0141.mediawiki>`_ are supported.

=====  ======================  ==================  ==================================
Bytes  Parameter               Type                Description
=====  ======================  ==================  ==================================
4      ``version``             i32                 Transaction version number.
0/2    ``flags``               Option<u8[2]>       If present, always 0001, and indicates the presence of witness data
var    ``tx_in count``         uint                Number of transaction inputs.
var    ``tx_in``               :ref:`txIn`         List of transaction inputs.
var    ``tx_out count``        uint                The number of transaction outputs.
var    ``tx_out``              :ref:`txOut`        List of transaction outputs.
var    ``tx_witnesses``        :ref:`txWitness`    A list of witnesses, one for each input; omitted if flag is omitted above.
4      ``lock_time``           u32                 A Unix timestamp OR block number.
=====  ======================  ==================  ==================================

.. note:: Bitcoin uses the term "CompactSize Unsigned Integers" to refer to variable-length integers, which are used to indicate the number of bytes representing transaction inputs and outputs. See the `Developer Reference <https://bitcoin.org/en/developer-reference#compactsize-unsigned-integers>`_ for more details.

.. _txIn:

Inputs
~~~~~~

Bitcoin's UTXO model requires a new transaction to spend at least one existing and unspent transaction output as a transaction input. The ``txIn`` type consists of the following bytes. See the `reference <https://bitcoin.org/en/developer-reference#txin>`__ for further details.

.. tabularcolumns:: |l|l|l|L|

=====  ======================  =========  ==================================
Bytes  Parameter               Type       Description
=====  ======================  =========  ==================================
36     ``previous_output``     outpoint   The output to be spent consisting of the transaction hash (32 bytes) and the output index (4 bytes).
var    ``script bytes``        uint       Number of bytes in the signature script (max 10,000 bytes).
var    ``signature script``    char[]     The script satisfying the output's script.
4      ``sequence``            u32        Sequence number (default ``0xffffffff``).
=====  ======================  =========  ==================================


.. _txOut:

Outputs
~~~~~~~

The transaction output has the following format according to the `reference <https://bitcoin.org/en/developer-reference#txout>`__.

=====  ======================  =========  ==================================
Bytes  Parameter               Type       Description
=====  ======================  =========  ==================================
8      ``value``               i64        Number of satoshis to be spent.   
1+     ``pk_script bytes``     uint       Number of bytes in the script.
var    ``pk_script``           char[]     Spending condition as script.
=====  ======================  =========  ==================================


.. _txWitness:

Witness
~~~~~~~

=====  ======================   =======================  ==================================
Bytes  Parameter                Type                     Description
=====  ======================   =======================  ==================================
var    ``count``                uint                     The number of witness stack items in this tx_witness.
var    ``witness_stack``        :ref:`witnessStackItem`  List of witness stack items making up this tx_witness.
=====  ======================   =======================  ==================================

.. _witnessStackItem:

Witness Stack Item
~~~~~~~~~~~~~~~~~~

=====  ======================   ====================  ==================================
Bytes  Parameter                Type                  Description
=====  ======================   ====================  ==================================
var    ``count``                uint                  The number of bytes in this witness stack item.
var    ``witness_stack``        u8[]                  The bytes making up the witness stack item.
=====  ======================   ====================  ==================================
