# FoundationDB Julia Client

[![Build Status](https://travis-ci.org/tanmaykm/FoundationDB.jl.svg?branch=master)](https://travis-ci.org/tanmaykm/FoundationDB.jl)
[![Coverage Status](https://coveralls.io/repos/tanmaykm/FoundationDB.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/tanmaykm/FoundationDB.jl?branch=master)
[![codecov.io](http://codecov.io/github/tanmaykm/FoundationDB.jl/coverage.svg?branch=master)](http://codecov.io/github/tanmaykm/FoundationDB.jl?branch=master)

The current implementation covers all of the C-APIs, and provides an easy to use Julia API layer over it for simple key-value pairs.

The Julia APIs are quite easy to follow, with this example:

```
using FoundationDB

open(FDBCluster()) do cluster                        # Read cluster configuration
    open(FDBDatabase(cluster)) do db                 # Open the database
        key = UInt8[0,1,2]                           # This is a key, and ...
        val = UInt8[9, 9, 9]                         # this is a value. Both are byte arrays.
        open(FDBTransaction(db)) do tran             # Start a transaction
            @test clearkey(tran, key) == nothing     # Delete a key if present
            @test getval(tran, key) == nothing       # Get value for a key (nothing if not present)
            @test setval(tran, key, val) == nothing  # Set value for a key
            @test getval(tran, key) == val           # We get the value, once it has been set
            @test commit(tran)                       # Commit changes we made in our snapshot
            @test_throws FDBError commit(tran)       # We can only commit once.
        end

        open(FDBTransaction(db)) do tran             # Open a new transaction 
            @test clearkey(tran, key) == nothing     # Delete a key
            @test getval(tran, key) == nothing
        end                                          # Transactions are auto-committed by default!
                                                     # And also retried automatically when possible

        open(FDBTransaction(db)) do tran             # Need a transaction even for read operation
            @test getval(tran, key) == nothing
        end                                          # Reads don't have to be committed
    end
end
```

Note: The Julia implementation makes use of Julia threading APIs. Make sure you have enabled threading and have at least two threads configured for Julia. E.g.:

```
$> JULIA_NUM_THREADS=2
$> export JULIA_NUM_THREADS
$> julia -e 'using Pkg; Pkg.test("FoundationDB")'
```
