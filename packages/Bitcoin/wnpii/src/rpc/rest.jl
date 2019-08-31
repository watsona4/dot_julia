using HTTP

function get_url(testnet::Bool=false)
    string("http://", NODE_URL, ":", DEFAULT["rpcport"][testnet])
end

init_url(url::String, testnet::Bool) = isempty(url) ? get_url(testnet) : url

"""
    get_tx(key::String; url::String="", testnet::Bool=false)
    -> Tx

Returns the bitcoin transaction given a node url with REST server enabled and
transaction hash as an hexadecimal string.
Uses mainnet by default
"""
function get_tx(key::String; url::String="", testnet::Bool=false)
    url *= init_url(url, testnet) *"/rest/tx/" * key * ".bin"
    response = HTTP.request("GET", url)
    try
        response.status == 200
    catch
        error("Unexpected status: ", response.status)
    end
    raw = response.body
    tx = parse(IOBuffer(raw), testnet)::Tx
    if tx.segwit
        computed = id(tx)
    else
        computed = bytes2hex(reverse(hash256(raw)))
    end
    if id(tx) != key
        error("not the same id : ", id(tx),
            "\n             vs : ", tx_id)
    end
    return tx
end

"""
    get_headers(key::String; amount::Integer=1, url::String="", testnet::Bool=false)
    -> BlockHeaders[]

Returns the bitcoin transaction given a node url with REST server enabled and
transaction hash as an hexadecimal string.
"""
function get_headers(key::String; amount::Integer=1, url::String="", testnet::Bool=false)
    url *= init_url(url, testnet) * "/rest/headers/" * string(amount) * "/" * key * ".bin"
    response = HTTP.request("GET", url)
    try
        response.status == 200
    catch
        error("Unexpected status: ", response.status)
    end
    io = IOBuffer(response.body)
    headers = BlockHeader[]
    while io.ptr < io.size
        push!(headers, io2blockheader(io))
    end
    return headers
end

"""
    get_blockhashbyheight(key::Integer; url::String="", testnet::Bool=false)
    -> String

Returns the hash of the block in the current best blockchain based on its
height (how many blocks it is after the Genesis Block).
"""
function get_block(key::Integer; url::String="", testnet::Bool=false)
    url *= init_url(url, testnet) *"/rest/blockhashbyheight/" * string(key) * ".bin"
    response = HTTP.request("GET", url)
    try
        response.status == 200
    catch
        error("Unexpected status: ", response.status)
    end
    return bytes2hex(reverse(response.body))
end

"""
    get_blockhashbyheight(key::Integer; url::String="", testnet::Bool=false)
    -> String

Returns the hash of the block in the current best blockchain based on its
height (how many blocks it is after the Genesis Block).
"""
function get_blockhashbyheight(key::Integer; url::String="", testnet::Bool=false)
    url *= init_url(url, testnet) *"/rest/blockhashbyheight/" * string(key) * ".bin"
    response = HTTP.request("GET", url)
    try
        response.status == 200
    catch
        error("Unexpected status: ", response.status)
    end
    return bytes2hex(reverse(response.body))
end

@deprecate txfetch(tx_id::String, testnet::Bool=false) fetch(tx_id::String, testnet::Bool)
@deprecate fetch(tx_id::String, testnet::Bool=false) get_tx(tx_id, testnet=testnet)
