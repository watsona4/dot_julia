using Ripemd
using Nettle
using BenchmarkTools

reload("Ripemd")
d = b"";
@benchmark Ripemd.ripemd160($d)
@benchmark Nettle.digest("ripemd160", $d)

d = b"a";
@benchmark Ripemd.ripemd160($d)
@benchmark Nettle.digest("ripemd160", $d)

d = [b"a"[1] for j in 1:10000];
@benchmark Ripemd.ripemd160($d)
@benchmark Nettle.digest("ripemd160", $d)

d = *(["a" for j in 1:10000]...);
@benchmark Ripemd.ripemd160($d)
@benchmark Nettle.digest("ripemd160", $d)
