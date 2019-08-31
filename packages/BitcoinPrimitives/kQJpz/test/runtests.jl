# Copyright (c) 2019 Guido Kraemer
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

using BitcoinPrimitives, Test

files = readdir(".")

# use only files that are named test_*.jl and start with the newest

filter!(x -> occursin(r"^test_.*\.jl$", x), files)
sort!(files, by = x -> stat(x).mtime, rev = true)

for f in files
    include(f)
end
