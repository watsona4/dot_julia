# Script

const SIGHASH_ALL = UInt32(1)
const SIGHASH_NONE = UInt32(2)
const SIGHASH_SINGLE = UInt32(3)

const SCRIPT_TYPES = Dict([
    ("P2PKH", [0x6f, 0x00]),
    ("P2SH", [0xc4, 0x05])
])

# Block

GENESIS_BLOCK_HASH = Dict([
    (false, hex2bytes("000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f")),
    (true, hex2bytes("000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943"))
])

# Network

USER_AGENT = "/bitcoin.jl:0.1/"

const DEFAULT = Dict([
    ("version", 70015),
    ("services", zero(UInt64)),
    ("ip", ip"0.0.0.0"),
    ("port", Dict([(false, 8333),
                   (true, 18333)])),
    ("rpcport", Dict([(false, 8332),
                   (true, 18332)])),
    ("start_height", zero(UInt32)),
    ("relay", true)
])

const IPV4_PREFIX = append!(fill(0x00, 10), [0xff, 0xff])

const NODE_URL = "btc.brane.cc"

const TX_DATA_TYPE = 1
const BLOCK_DATA_TYPE = 2
const FILTERED_BLOCK_DATA_TYPE = 3
const COMPACT_BLOCK_DATA_TYPE = 4

const DATA_MESSAGE_NAME = Dict([
    (1, "MSG_TX"),
    (2, "MSG_BLOCK"),
    (3, "MSG_FILTERED_BLOCK"),
    (4, "MSG_CMPCT_BLOCK"),
    (5, "MSG_WITNESS_BLOCK"),
    (6, "MSG_WITNESS_TX"),
    (7, "MSG_FILTERED_WITNESS_BLOCK")])

const DATA_MESSAGE_TYPE = Dict([
    ("MSG_TX", 1),
    ("MSG_BLOCK", 2),
    ("MSG_FILTERED_BLOCK", 3),
    ("MSG_CMPCT_BLOCK", 4),
    ("MSG_WITNESS_BLOCK", 5),
    ("MSG_WITNESS_TX", 6),
    ("MSG_FILTERED_WITNESS_BLOCK", 7)])

"""
NETWORK_MAGIC is testnet if `true`
"""
const NETWORK_MAGIC = Dict([
    (false, 0xd9b4bef9)
    (true, 0x0709110b)
])

SERVICES_NAME = Dict([
    (0x0000000000000001, "NODE_NETWORK"),
    (0x0000000000000002, "NODE_GETUTXO"),
    (0x0000000000000004, "NODE_BLOOM"),
    (0x0000000000000008, "NODE_WITNESS"),
    (0x0000000000000400, "NODE_NETWORK_LIMITED")
])
