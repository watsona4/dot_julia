mutable struct Script
    instructions::Vector{Any}
    Script(instructions::Nothing) = new(Union{UInt8, Vector{UInt8}}[])
    Script(instructions) = new(instructions)
end

function show(io::IO, z::Script)
    for instruction in z.instructions
        if typeof(instruction) <: Integer
            if haskey(OP_CODE_NAMES, instruction)
                print(io, "\n", OP_CODE_NAMES[Int(instruction)])
            else
                print(io, "\n", string("OP_CODE_", Int(instruction)))
            end
        elseif typeof(instruction) <: Vector{UInt8}
            print(io, "\n", bytes2hex(instruction))
        else
            print(io, "\n", instruction)
        end
    end
end

"""
    scriptparse(::GenericIOBuffer) -> Script

Returns a Script object from an IOBuffer
"""
function scriptparse(s::IOBuffer)
    length_ = read_varint(s)
    instructions = []
    count = 0
    while count < length_
        current = UInt8[]
        readbytes!(s, current, 1)
        count += 1
        current_byte = current[1]
        if current_byte >= 1 && current_byte <= 75
            n = current_byte
            push!(instructions, read(s, n))
            count += n
        elseif current_byte == 76
            # op_pushdata1
            n = read(s, 1)[1]
            push!(instructions, read(s, n))
            count += n + 1
        elseif current_byte == 77
            # op_pushdata2
            n = reinterpret(Int16, read(s, 2))[1]
            push!(instructions, read(s, n))
            count += n + 2
        else
            # op_code
            push!(instructions, current_byte)
        end
    end
    if count != length_
        error("Error: parsing Script failed")
    end
    return Script(instructions)
end

function rawserialize(s::Script)
    result = UInt8[]
    for instruction in s.instructions
        if typeof(instruction) == UInt8
            push!(result, instruction)
        else
            length_ = length(instruction)
            if length_ < 0x4b
                append!(result, UInt8(length_))
            elseif length_ > 0x4b && length_ < 0x100
                append!(result, 0x4c)
                append!(result, UInt8(length_))
            elseif length_ >= 0x100 && length_ <= 0x208
                append!(result, 0x4d)
                result += int2bytes(length_, 2)
            else
                error("too long an instruction")
            end
            append!(result, instruction)
        end
    end
    return result
end

function serialize(s::Script)
    result = rawserialize(s)
    total = length(result)
    prepend!(result, encode_varint(total))
    return result
end

"""
    evaluate(s::Script, z::Integer) -> Bool

Evaluate if Script is valid given the transaction signature hash
"""
function evaluate(s::Script, z::Integer, witness::Union{Script, Nothing}=nothing)
    instructions = copy(s.instructions)
    stack = Vector{UInt8}[]
    altstack = Vector{UInt8}[]
    while length(instructions) > 0
        instruction = popfirst!(instructions)
        if typeof(instruction) <: Integer
            operation = OP_CODE_FUNCTIONS[instruction]
            function badop(instruction::Integer)
                println("bad op: ", OP_CODE_NAMES[instruction])
            end
            if instruction in (99, 100)
                # op_if/op_notif require the  array
                if !operation(stack, instructions)
                    badop(instruction)
                    return false
                end
            elseif instruction in (107, 108)
                # op_toaltstack/op_fromaltstack require the altstack
                if !operation(stack, altstack)
                    badop(instruction)
                    return false
                end
            elseif instruction in (172, 173, 174, 175)
                if !operation(stack, z)
                    badop(instruction)
                    return false
                end
            elseif !operation(stack)
                badop(instruction)
                return false
            end
        else
            push!(stack, instruction)
            # p2sh rule. if the next three instructions are:
            # OP_HASH160 <20 byte hash> OP_EQUAL this is the RedeemScript
            # OP_HASH160 == 0xa9 && OP_EQUAL == 0x87
            if length(instructions) == 3 && instructions[1] == 0xa9 &&
               typeof(instructions[2]) == Vector{UInt8} && length(instructions[2]) == 20 &&
               instructions[3] == 0x87
                println(" ---- ==== !!!! P2SH Script Found !!!! ==== ---- ")
                redeem_script = encode_varint(length(instruction))
                append!(redeem_script, instruction)
                # we execute the next three op codes
                pop!(instructions)
                h160 = pop!(instructions)
                pop!(instructions)
                if !op_hash160(stack)
                    return false
                end
                push!(stack, h160)
                if !op_equal(stack)
                    return false
                end
                # final result should be a 1
                if !op_verify(stack)
                    println("bad p2sh h160")
                    return false
                end
                # hashes match! now add the RedeemScript
                stream = IOBuffer(redeem_script)
                append!(instructions, scriptparse(stream).instructions)
            end

            if witness != nothing
                # witness program version 0 rule. if stack instructions are:
                # 0 <20 byte hash> this is p2wpkh
                if length(stack) == 2 && stack[1] == [0x00] && length(stack[2]) == 20
                    println(" ---- ==== !!!! P2WPKH Script Found !!!! ==== ---- ")
                    h160 = pop!(stack)
                    pop!(stack)
                    append!(instructions, witness.instructions)
                    append!(instructions, p2pkh_script(h160).instructions)
                end
                # witness program version 0 rule. if stack instructions are:
                # 0 <32 byte hash> this is p2wsh
                if length(stack) == 2 && stack[1] == [0x00] && length(stack[2]) == 32
                    println(" ---- ==== !!!! P2WSH Script Found !!!! ==== ---- ")
                    h256 = pop!(stack)
                    pop!(stack)
                    append!(instructions, witness.instructions[1:end-1])
                    witness_script = witness.instructions[end]
                    if h256 != sha256(witness_script)
                        print("bad sha256")
                        return false
                    end
                    # hashes match! now add the Witness Script
                    stream = IOBuffer(append!(encode_varint(length(witness_script)), witness_script))
                    witness_script_instructions = scriptparse(stream).instructions
                    append!(instructions, witness_script_instructions)
                end
            end
        end
    end
    if length(stack) == 0
        return false
    end
    if pop!(stack) == Vector{UInt8}[]
        return false
    end
    return true
end

"""
Takes a hash160 && returns the p2pkh scriptPubKey
"""
function p2pkh_script(h160::Vector{UInt8})
    script = Union{UInt8, Vector{UInt8}}[]
    pushfirst!(script, 0x76, 0xa9)
    push!(script, h160, 0x88, 0xac)
    return Script(script)
end

"""
Takes a hash160 && returns the p2sh scriptPubKey
"""
function p2sh_script(h160::Vector{UInt8})
    script = Union{UInt8, Vector{UInt8}}[]
    pushfirst!(script, 0xa9)
    push!(script, h160, 0x87)
    return Script(script)
end

"""
Takes a hash160 && returns the p2wpkh ScriptPubKey
"""
function p2wpkh_script(h160::Vector{UInt8})
    return Script([0x00, h160])
end

"""
Takes a hash160 && returns the p2wsh ScriptPubKey
"""
function p2wsh_script(hash256::Vector{UInt8})
    return Script([0x00, h256])
end

function scripttype(script::Script)
    if is_p2pkh(script)
        return "P2PKH"
    elseif is_p2sh(script)
        return "P2SH"
    elseif is_p2wsh(script)
        return "P2WSH"
    elseif is_p2wpkh(script)
        return "P2WPKH"
    else
        return error("Unknown Script type")
    end
end

"""
Returns whether this follows the
OP_DUP OP_HASH160 <20 byte hash> OP_EQUALVERIFY OP_CHECKSIG pattern.
"""
function is_p2pkh(script::Script)
    return length(script.instructions) == 5 &&
        script.instructions[1] == 0x76 &&
        script.instructions[2] == 0xa9 &&
        typeof(script.instructions[3]) == Vector{UInt8} &&
        length(script.instructions[3]) == 20 &&
        script.instructions[4] == 0x88 &&
        script.instructions[5] == 0xac
end

"""
Returns whether this follows the
OP_HASH160 <20 byte hash> OP_EQUAL pattern.
"""
function is_p2sh(script::Script)
    return length(script.instructions) == 3 &&
           script.instructions[1] == 0xa9 &&
           typeof(script.instructions[2]) == Vector{UInt8} &&
           length(script.instructions[2]) == 20 &&
           script.instructions[3] == 0x87
end

function is_p2wpkh(script::Script)
    length(script.instructions) == 2 &&
    script.instructions[1] == 0x00 &&
    typeof(script.instructions[2]) == Vector{UInt8} &&
    length(script.instructions[2]) == 20
end

"""
Returns whether this follows the
OP_0 <20 byte hash> pattern.
"""
function is_p2wsh(script::Script)
    length(script.instructions) == 2 &&
    script.instructions[1] == 0x00 &&
    typeof(script.instructions[2]) == Vector{UInt8} &&
    length(script.instructions[2]) == 32

end

const H160_INDEX = Dict([
    ("P2PKH", 3),
    ("P2SH", 2)
])

"""
Returns the address corresponding to the script
"""
function script2address(script::Script, testnet::Bool)
    type = scripttype(script)
    h160 = script.instructions[H160_INDEX[type]]
    return h160_2_address(h160, testnet, type)
end

@deprecate scriptevaluate(s::Script, z::Integer) evaluate(s::Script, z::Integer)
@deprecate scriptserialize(s::Script) serialize(s::Script)
