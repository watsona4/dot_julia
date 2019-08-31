using BenchmarkTools
using Revise
using Base58
using Base64

code_typed(base58encode, (Array{UInt8, 1}, ))
code_llvm(base58encode, (Array{UInt8, 1}, ))
code_native(base58encode, (Array{UInt8, 1}, ))

code_typed(base58decode, (Array{UInt8, 1}, ))
code_llvm(base58decode, (Array{UInt8, 1}, ))
code_native(base58decode, (Array{UInt8, 1}, ))

base58decode([b"   11111"..., test_data[2, 7]...]) |> String
base58decode(b"     ")


base58encode(test_data[1, 4]);
base58encode(test_data[1, 7]);

@btime base58encode($(test_data[1, 7]));
@btime base64encode($(test_data[1, 7]));

@btime base58decode($(test_data[2, 7]));
@btime base64decode($(base64encode(test_data[1, 7])));

test_data = hcat(
    [b"",                b""],
    [[0x00],             b"1"],
    [[0x00, 0x00],       b"11"],
    [b"hello world",     b"StV1DL6CwTryKyV"],
    [b"\0\0hello world", b"11StV1DL6CwTryKyV"],
    [nothing,            b"3vQOB7B6uFg4oH"],
    [b""" !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~""",
                         b"3WSNuyEGf19K7EdeCmokbtTAXJwJUdvg8QXxAacYC7kR1bQoYeWVr5iMUHvxvv4FCFY48dVUrX6BrFLod6zsEhHU9NciUXFM17h1qtveYD7ocbnXQyuY84An9nAvEjdt6H"]
);


@btime base58encode($(test_data[1, 1]));
@btime base64encode($(test_data[1, 1]));

@btime base58encode($(test_data[1, 2]));
@btime base64encode($(test_data[1, 2]));

@btime base58encode($(test_data[1, 3]));
@btime base64encode($(test_data[1, 3]));

@btime base58encode($(test_data[1, 4]));
@btime base64encode($(test_data[1, 4]));

@btime base58encode($(test_data[1, 5]));
@btime base64encode($(test_data[1, 5]));

@btime base58encode($(test_data[1, 7]));
@btime base64encode($(test_data[1, 7]));

function count_leading_zeros(x)
    n_zeros = 0
    while n_zeros < length(x) && x[n_zeros + 1] == 0
        n_zeros += 1
    end
    n_zeros
end


function count_leading_zeros2(x)
    n_zeros = 0
    for c in x
        c != 0 && break
        n_zeros += 1
    end
    n_zeros
end

@btime count_leading_zeros($(test_data[1, 1]))
@btime count_leading_zeros2($(test_data[1, 1]))

@btime count_leading_zeros($(test_data[1, 2]))
@btime count_leading_zeros2($(test_data[1, 2]))

@btime count_leading_zeros($(test_data[1, 3]))
@btime count_leading_zeros2($(test_data[1, 3]))

@btime count_leading_zeros($(test_data[1, 4]))
@btime count_leading_zeros2($(test_data[1, 4]))

@btime count_leading_zeros($(test_data[1, 5]))
@btime count_leading_zeros2($(test_data[1, 5]))

@btime count_leading_zeros($(test_data[1, 7]))
@btime count_leading_zeros2($(test_data[1, 7]))
