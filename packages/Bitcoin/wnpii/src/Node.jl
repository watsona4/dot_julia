
using Sockets

mutable struct Node
    host::Union{String,IPv4}
    port::Integer
    testnet::Bool
    logging::Bool
    acknowledged::Bool
    sock::TCPSocket
    Node(host::Union{String,IPv4}, port::Integer, testnet::Bool=false, logging::Bool=false) = new(host, port, testnet, logging, false)
end

Node(host::Union{String,IPv4}, testnet::Bool=false) = Node(host, DEFAULT["port"][testnet], testnet)

"""
    connect!(node::Node) -> TCPSocket

Connect to the host `node.host` on port `node.port`.
"""
function connect!(node::Node)
    try
        if !isopen(node.sock)
            node.sock = connect(node.host, node.port)
        else
            node.sock
        end
    catch
        node.sock = connect(node.host, node.port)
    end
end

"""
    close!(node::Node) -> TCPSocket

Close Node's TCPSocket
"""
function close!(node::Node)
    close(node.sock)
    node.sock
end


"""
    send2node(node::Node, message::T) -> Integers

Send a message to the connected node, returns the numbers of bytes sent
"""
function send2node(node::Node, message::T) where {T<:AbstractMessage}
    envelope = NetworkEnvelope(message.command,
                               serialize(message),
                               node.testnet)
    if node.logging
        println("Sending : ", envelope)
    end
    write(node.sock, serialize(envelope))
end

"""
handshake(node::Node) -> Bool

Do a handshake with the other node, returns true if successful
Handshake is sending a version message and getting a verack back.
"""
function handshake(node::Node, messages::Channel)
    println("Connecting to node...")
    connect!(node)
    @async read(node.sock)
    @async read_messages(node, messages)
    println("Sending version message...")
    send2node(node, VersionMessage())
    i = 0
    while !node.acknowledged
        if eof(node.sock) || i == 2
            println("Failed handshake!")
            return false
        end
        msg = take!(messages)
        answer(node, msg)
        i += 1
    end
    println("Handshake successfull")
    return true
end

"""
    getheaders(node::Node, stop::Integer, start::Integer=1) -> Vector{BlockHeader}

Returns a list of blockheaders, from `start` to `stop` height
!!!Experimental function, not tested as it should
"""
function getheaders(node::Node, stop::Integer, start::Integer=1)
    handshake(node)
    last_block_hash = GENESIS_BLOCK_HASH[node.testnet]
    current_height = start
    result = BlockHeader[]
    while current_height <= stop
        try
            msg = GetHeadersMessage(last_block_hash)
            send2node(node, msg)
            if bytesavailable(node.sock) > 0
                raw = read(node.sock.buffer)
                envelopes = io2envelopes(raw, node.testnet)
                for envelope in envelopes
                    if envelope.command == "headers"
                        headers = PARSE_PAYLOAD[envelope.command](envelope.payload)
                        for header in headers.headers
                            if !check_pow(header)
                                error("bad proof of work at block ", id(header))
                            end
                            if (last_block_hash != GENESIS_BLOCK_HASH) && (header.prev_block != last_block_hash)
                                error("discontinuous block at ", id(header))
                            end
                            if current_height % 2016 == 0
                                println(id(header))
                            end
                            last_block_hash = hash(header)
                            current_height += 1
                            push!(result, header)
                            if node.logging
                                println(header)
                            end
                        end
                    end
                end
            else
                sleep(0.01)
            end
        catch e
            if typeof(e) == InterruptException
                return error("Interrupted")
            end
            println("Error ", e, " was raised, retrying...")
            sleep(1)
        end
    end
    result
end

function read_messages(node::Node, net_msg::Channel)
    while !eof(node.sock)
        envelope = io2envelope(node.sock.buffer, node.testnet)
        command = envelope.command
        msg = haskey(PARSE_PAYLOAD, command) ?
              PARSE_PAYLOAD[command](envelope.payload) :
              bytes2hex(envelope.payload)
        put!(net_msg, msg)
    end
end

function answer(node::Node, msg::HeadersMessage)
    println("\n\n --- Headers received --- \n\n")
    getdata = GetDataMessage()
    for b in msg.headers
        if check_pow(b)
            append!(getdata, DATA_MESSAGE_TYPE["MSG_FILTERED_BLOCK"], hash(b))
        else
            error("Invalid proof of work for block ", b)
        end
    end
    send2node(node, getdata)
end

function answer(node::Node, msg::MerkleBlockMessage)
    if !is_valid(msg)
        error("Merkle proof is *not* valid!")
    else
        println("Merkle proof is valid.")
    end
end

function answer(node::Node, msg::VersionMessage)
    send2node(node, VerAckMessage())
end

function answer(node::Node, msg::VerAckMessage)
    node.acknowledged = true
    println("\n--------\nVersion Acknowledgement received from\n", node)
    return
end

function answer(node::Node, msg::PingMessage)
    send2node(node, PongMessage(serialize(msg)))
end

function answer(node::Node, msg::AbstractMessage)
    println("Ignoring...")
end

function get_tx_of_interest(node::Node, net_msg::Channel, adr::String)
    found = false
    while !found
        msg = take!(net_msg)
        if typeof(msg) <: Tx
            println("\n\n --- Tx received --- \n\n")
            i = 0
            for tx_out in msg.tx_outs
                if script2address(tx_out.script_pubkey, true) == adr
                    println("found: ", txid(msg), " ", i)
                    found = true
                    break
                end
                i += 1
            end
        else
            println("Processing ", msg)
            answer(node, msg)
        end
    end
end
