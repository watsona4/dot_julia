using FoundationDB
using Test

function timewaittask(watchtask, ref_twatch)
    f = () -> begin
        t1 = time()
        fetch(watchtask)
        ref_twatch[] = time() - t1
    end
    @async f()
end

function arraycmp(a, b, cmp)
    cmp(a, b)
end

@testset "start network" begin
    @test !is_client_running()
    @test start_client() === nothing
    @test is_client_running()
end # testset "start network"

try
    @testset "basic julia apis" begin
        chk_closed = Vector{Any}()

        open(FDBCluster()) do cluster
            push!(chk_closed, cluster)
            @test cluster.ptr !== C_NULL

            open(FDBDatabase(cluster)) do db
                push!(chk_closed, db)
                @test db.name == "DB"
                @test db.ptr !== C_NULL

                open(FDBTransaction(db)) do tran
                    @test clearkeyrange(tran, UInt8[0], UInt8[2]) == nothing
                end

                key = UInt8[0,1,2]
                val = UInt8[9, 9, 9]

                open(FDBTransaction(db)) do tran
                    push!(chk_closed, tran)
                    @test tran.ptr !== C_NULL

                    @test clearkey(tran, key) == nothing
                    @test getval(tran, key) == nothing
                    @test setval(tran, key, val) == nothing
                    @test getval(tran, key) == val
                end

                open(FDBTransaction(db)) do tran
                    push!(chk_closed, tran)
                    @test clearkey(tran, key) == nothing
                    @test getval(tran, key) == nothing
                end

                open(FDBTransaction(db)) do tran
                    push!(chk_closed, tran)
                    @test getval(tran, key) == nothing
                end
            end
        end

        for item in chk_closed
            @test !isopen(item)
        end
    end # testset "basic julia apis"

    @testset "auto commit" begin
        open(FDBCluster()) do cluster
            open(FDBDatabase(cluster)) do db
                key = UInt8[0,1,2]
                val = UInt8[9, 9, 9]
                open(FDBTransaction(db)) do tran
                    @test clearkey(tran, key) == nothing
                    @test getval(tran, key) == nothing
                    @test setval(tran, key, val) == nothing
                    @test getval(tran, key) == val
                    @test commit(tran)
                    @test_throws FDBError commit(tran)
                end

                open(FDBTransaction(db)) do tran
                    @test clearkey(tran, key) == nothing
                    @test getval(tran, key) == nothing
                    @test commit(tran)
                end

                open(FDBTransaction(db)) do tran
                    @test getval(tran, key) == nothing
                    @test commit(tran)
                end
            end
        end
    end # testset "auto commit"

    @testset "cancel" begin
        open(FDBCluster()) do cluster
            open(FDBDatabase(cluster)) do db
                key = UInt8[0,1,2]
                val = UInt8[9, 9, 9]
                open(FDBTransaction(db)) do tran
                    @test setval(tran, key, val) == nothing
                    @test cancel(tran) == nothing
                end
                open(FDBTransaction(db)) do tran
                    @test getval(tran, key) == nothing
                end
                open(FDBTransaction(db)) do tran
                    @test setval(tran, key, val) == nothing
                    @test commit(tran)
                    @test cancel(tran) == nothing
                end
                open(FDBTransaction(db)) do tran
                    @test getval(tran, key) == val
                    @test clearkey(tran, key) == nothing
                end
            end
        end
    end # testset "cancel"


    @testset "parallel updates" begin
        sumval = 0
        function do_updates()
            open(FDBCluster()) do cluster
                open(FDBDatabase(cluster)) do db
                    key = UInt8[0,1,2]
                    valarr = Int[1]
                    val = FoundationDB.unsafe_wrap(Array, convert(Ptr{UInt8}, pointer(valarr)), (sizeof(Int),), own=false)
                    for valint in 1:100
                        valarr[1] = valint
                        open(FDBTransaction(db)) do tran
                            @test setval(tran, key, val) == nothing
                        end
                        open(FDBTransaction(db)) do tran
                            @test clearkey(tran, key) == nothing
                        end
                        sleep(rand()/100)
                        open(FDBTransaction(db)) do tran
                            valnow = getval(tran, key)
                            if valnow != nothing
                                sumval += reinterpret(Int, valnow)[1]
                            end
                        end
                    end
                end
            end
        end

        @sync begin
            @async do_updates()
            @async do_updates()
        end

        println("sumval in parallel updates = ", sumval)
        @test 0 <= sumval <= (5050 * 1.5) # series sum of 1:100 = 5050
    end # testset "parallel updates"

    @testset "large key value" begin
        open(FDBCluster()) do cluster
            open(FDBDatabase(cluster)) do db
                key = ones(UInt8, 10000)
                val = ones(UInt8, 100000)
                open(FDBTransaction(db)) do tran
                    @test clearkey(tran, key) == nothing
                    @test getval(tran, key) == nothing
                    @test setval(tran, key, val) == nothing
                    @test getval(tran, key) == val
                    @test commit(tran)
                    @test reset(tran) == nothing
                    @test commit(tran)              # test that commit is allowed after a reset
                end

                open(FDBTransaction(db)) do tran
                    @test clearkey(tran, key) == nothing
                    @test getval(tran, key) == nothing
                end

                open(FDBTransaction(db)) do tran
                    @test getval(tran, key) == nothing
                    @test reset(tran) == nothing
                end
            end
        end
    end # testset "large key value"

    @testset "watch" begin
        open(FDBCluster()) do cluster
            open(FDBDatabase(cluster)) do db
                key = UInt8[0,1,2]
                val1 = UInt8[0, 0, 0]
                val2 = UInt8[0, 0, 0]
                open(FDBTransaction(db)) do tran
                    ref_twatch = Ref(0.0)
                    watchtask = watchkey(tran, key)
                    timetask = timewaittask(watchtask, ref_twatch)
                    sleep(0.5)
                    @test setval(tran, key, val2) == nothing
                    sleep(0.5)
                    @test clearkey(tran, key) == nothing
                    fetch(timetask)
                    @test ref_twatch[] > 0.4

                    watchhandle = FDBFuture()
                    watchtask = watchkey(tran, key; handle=watchhandle)
                    sleep(0.2)
                    @test istaskstarted(watchtask)
                    @test !istaskdone(watchtask)
                    cancel(watchhandle)
                    sleep(0.2)
                    @test istaskdone(watchtask)
                    try
                        fetch(watchtask)
                        error("watchtask should have failed!")
                    catch ex
                        @test isa(ex, FDBError)
                        @test ex.code == 1101 # Asynchronous operation cancelled
                    end
                end
            end
        end

        open(FDBCluster()) do cluster
            open(FDBDatabase(cluster)) do db
                key = UInt8[0,1,2]
                val1 = UInt8[0, 0, 0]
                val2 = UInt8[0, 0, 0]

                # set an initial value
                open(FDBTransaction(db)) do tran
                    @test setval(tran, key, val1) == nothing
                end

                ref_twatch = Ref(0.0)
                # start a watch
                watchtask = open(FDBTransaction(db)) do tran
                    watchkey(tran, key)
                end

                timetask = timewaittask(watchtask, ref_twatch)

                open(FDBTransaction(db)) do tran
                    sleep(0.5)
                    @test setval(tran, key, val2) == nothing
                    sleep(0.5)
                    @test clearkey(tran, key) == nothing
                end

                fetch(timetask)
                @test ref_twatch[] > 0.4
            end
        end
    end # testset "watch"

    @testset "get key" begin
        keys = [UInt8[0,1,x] for x in 1:20]
        val = UInt8[0]

        open(FDBCluster()) do cluster
            open(FDBDatabase(cluster)) do db
                # setup all keys
                open(FDBTransaction(db)) do tran
                    for key in keys
                        @test setval(tran, key, val) == nothing
                    end
                end

                # get
                open(FDBTransaction(db)) do tran
                    emptykey = UInt8[]
                    key = UInt8[0,0,0]
                    @test getkey(tran, keysel(FDBKeySel.last_less_or_equal, key)) == emptykey
                    @test getkey(tran, keysel(FDBKeySel.last_less_than, key)) == emptykey
                    @test getkey(tran, keysel(FDBKeySel.first_greater_than, key)) == UInt8[0,1,1]
                    @test getkey(tran, keysel(FDBKeySel.first_greater_or_equal, key)) == UInt8[0,1,1]

                    key = UInt8[0,1,1]
                    @test getkey(tran, keysel(FDBKeySel.last_less_or_equal, key)) == UInt8[0,1,1]
                    @test getkey(tran, keysel(FDBKeySel.last_less_than, key)) == emptykey
                    @test getkey(tran, keysel(FDBKeySel.first_greater_than, key)) == UInt8[0,1,2]
                    @test getkey(tran, keysel(FDBKeySel.first_greater_or_equal, key)) == UInt8[0,1,1]

                    key = UInt8[0,1,10]
                    @test getkey(tran, keysel(FDBKeySel.last_less_or_equal, key)) == UInt8[0,1,10]
                    @test getkey(tran, keysel(FDBKeySel.last_less_than, key)) == UInt8[0,1,9]
                    @test getkey(tran, keysel(FDBKeySel.first_greater_than, key)) == UInt8[0,1,11]
                    @test getkey(tran, keysel(FDBKeySel.first_greater_or_equal, key)) == UInt8[0,1,10]

                    key = UInt8[0,1,20]
                    @test getkey(tran, keysel(FDBKeySel.last_less_or_equal, key)) == UInt8[0,1,20]
                    @test getkey(tran, keysel(FDBKeySel.last_less_than, key)) == UInt8[0,1,19]
                    @test getkey(tran, keysel(FDBKeySel.first_greater_than, key)) != UInt8[0,1,20]
                    @test getkey(tran, keysel(FDBKeySel.first_greater_or_equal, key)) != UInt8[0,1,19]

                    key = UInt8[0,2,0]
                    @test getkey(tran, keysel(FDBKeySel.last_less_or_equal, key)) == UInt8[0,1,20]
                    @test getkey(tran, keysel(FDBKeySel.last_less_than, key)) == UInt8[0,1,20]
                    @test getkey(tran, keysel(FDBKeySel.first_greater_than, key)) != UInt8[0,2,0]
                    @test getkey(tran, keysel(FDBKeySel.first_greater_or_equal, key)) != UInt8[0,2,0]
                end

                # clear all keys
                open(FDBTransaction(db)) do tran
                    for key in keys
                        @test clearkey(tran, key) == nothing
                    end
                end
            end
        end
    end # testset "get key"

    @testset "get range" begin
        keys = [UInt8[0,1,x] for x in 1:20]
        val = UInt8[1]

        open(FDBCluster()) do cluster
            open(FDBDatabase(cluster)) do db
                # setup all keys
                open(FDBTransaction(db)) do tran
                    for key in keys
                        @test setval(tran, key, val) == nothing
                    end
                end

                # get
                open(FDBTransaction(db)) do tran
                    kvs, more = getrange(tran, keysel(FDBKeySel.first_greater_or_equal, keys[1]), keysel(FDBKeySel.last_less_or_equal, keys[10]))
                    @test length(kvs) == 9
                    @test !more
                    for kv in kvs
                        @test kv[1] in keys
                        @test kv[2] == val
                    end

                    kvs, more = getrange(tran, keysel(FDBKeySel.first_greater_or_equal, keys[1]), keysel(FDBKeySel.last_less_or_equal, keys[10]); limit=1)
                    @test length(kvs) == 1
                    @test more
                end

                # clear all keys
                open(FDBTransaction(db)) do tran
                    @test clearkeyrange(tran, keys[1], UInt8[0,1,21]) == nothing
                    @test getval(tran, keys[10]) == nothing
                end
            end
        end
    end # testset "get range"

    @testset "atomic" begin
        key    = UInt8[0,1,2]
        keymax = UInt8[0,1,3]
        keymin = UInt8[0,1,4]
        keyand = UInt8[0,1,5]
        keyor  = UInt8[0,1,6]
        keyxor = UInt8[0,1,7]

        open(FDBCluster()) do cluster
            open(FDBDatabase(cluster)) do db
                @testset "atomic add" begin
                    # clear key to start with
                    open(FDBTransaction(db)) do tran
                        @test clearkey(tran, key) == nothing
                    end
                    @sync begin
                        for idx in 1:10
                            @async open(FDBTransaction(db)) do tran
                                atomic_add(tran, key, 1)
                            end
                        end
                        for idx in 1:5
                            @async open(FDBTransaction(db)) do tran
                                atomic_add(tran, key, -1)
                            end
                        end
                    end
                    open(FDBTransaction(db)) do tran
                        @test atomic_integer(Int, getval(tran, key)) == 5
                        @test clearkey(tran, key) == nothing
                    end
                end # testset "atomic add"

                @testset "atomic integer min max" begin
                    # clear key to start with
                    open(FDBTransaction(db)) do tran
                        @test clearkey(tran, keymax) == nothing
                        @test clearkey(tran, keymin) == nothing
                    end
                    vals = rand(Cuint, 10)
                    @sync begin
                        for idx in 1:10
                            @async open(FDBTransaction(db)) do tran
                                atomic_max(tran, keymax, vals[idx])
                                atomic_min(tran, keymin, vals[idx])
                            end
                        end
                    end
                    open(FDBTransaction(db)) do tran
                        @test atomic_integer(Cuint, getval(tran, keymin)) == minimum(vals)
                        @test clearkey(tran, keymin) == nothing

                        @test atomic_integer(Cuint, getval(tran, keymax)) == maximum(vals)
                        @test clearkey(tran, keymax) == nothing
                    end
                end # testset "atomic integer min max"

                @testset "atomic bytes min max and or xor" begin
                    # clear key to start with
                    open(FDBTransaction(db)) do tran
                        @test setval(tran, keymax, zeros(UInt8, 10)) == nothing
                        @test setval(tran, keymin, ones(UInt8, 10) * typemax(UInt8)) == nothing
                    end
                    open(FDBTransaction(db)) do tran
                        @test getval(tran, keymax) == zeros(UInt8, 10)
                        @test getval(tran, keymin) == ones(UInt8, 10) * typemax(UInt8)
                    end
                    vals = [rand(UInt8,10) for x in 1:10]
                    maxval = zeros(UInt8, 10)
                    minval = ones(UInt8, 10) * typemax(UInt8)
                    andval = vals[1]
                    orval = vals[1]
                    xorval = vals[1]
                    open(FDBTransaction(db)) do tran
                        @test setval(tran, keyand, andval) == nothing
                        @test setval(tran, keyor, orval) == nothing
                        @test setval(tran, keyxor, xorval) == nothing
                    end
                    for val in vals
                        for idx in 1:length(val)
                            arraycmp(val, maxval, >) && (maxval = val)
                            arraycmp(val, minval, <) && (minval = val)
                            if idx > 1
                                andval = andval .& val
                                orval = orval .| val
                                xorval = xorval .⊻ val
                            end
                        end
                    end
                    @sync begin
                        for idx in 1:10
                            @async open(FDBTransaction(db)) do tran
                                atomic_max(tran, keymax, vals[idx])
                                atomic_min(tran, keymin, vals[idx])
                                atomic_and(tran, keyand, vals[idx])
                                atomic_or(tran, keyor, vals[idx])
                                atomic_xor(tran, keyxor, vals[idx])
                            end
                        end
                    end
                    open(FDBTransaction(db)) do tran
                        for (k,v) in zip([keymin, keymax, keyand, keyor, keyxor], [minval, maxval, andval, orval, xorval])
                            @test getval(tran, k) == v
                            @test clearkey(tran, k) == nothing
                        end
                    end
                end # testset "atomic bytes min max and or xor"
            end
        end
    end # testset "atomic"

    @testset "conflicts" begin
        function test_conflict(db, my_trigger::Channel{Nothing}, other_trigger::Channel{Nothing})
            open(FDBTransaction(db)) do tran
                # add conflict range
                conflict(tran, UInt8[0,1,2], UInt8[0,1,3], FDBConflictRangeType.READ)
                conflict(tran, UInt8[0,1,2], UInt8[0,1,3], FDBConflictRangeType.WRITE)

                # read key, ensure it is there
                if getval(tran, UInt8[0,1,2]) == nothing
                    error("not found")
                end

                # send trigger to other transaction
                put!(other_trigger, nothing)

                # wait for other transaction to also read the key
                wait(my_trigger)

                # delete the key and try to commit
                clearkey(tran, UInt8[0,1,2])
            end
        end

        open(FDBCluster()) do cluster
            open(FDBDatabase(cluster)) do db
                open(FDBTransaction(db)) do tran
                    setval(tran, UInt8[0,1,2], UInt8[0,1,2])
                end

                c1 = Channel{Nothing}(1)
                c2 = Channel{Nothing}(1)

                try
                    @sync begin
                        @async test_conflict(db, c1, c2)
                        @async test_conflict(db, c2, c1)
                    end
                    error("must throw not found")
                catch ex
                    @test isa(ex, CompositeException)
                    @test length(ex.exceptions) == 1
                    @test isa(ex.exceptions[1], CapturedException)
                    @test ex.exceptions[1].ex.msg == "not found"
                end

                open(FDBTransaction(db)) do tran
                    clearkey(tran, UInt8[0,1,2])
                end
            end
        end
    end # testset "conflicts"

    @testset "versionstamp" begin
        open(FDBCluster()) do cluster
            open(FDBDatabase(cluster)) do db
                open(FDBTransaction(db; trackversionstamp=true)) do tran
                    @test tran.versionstamp === nothing
                    atomic_setval(tran, zeros(UInt8, 8), ones(UInt8, 16), FDBMutationType.SET_VERSIONSTAMPED_VALUE)
                    commit(tran)
                    @test tran.versionstamp !== nothing
                    v1 = tran.versionstamp

                    reset(tran)
                    clearkey(tran, zeros(UInt8, 8))
                    commit(tran)
                    @test tran.versionstamp !== nothing
                    @test tran.versionstamp == v1

                    reset(tran)
                    key = UInt8[0,1,2]
                    prep_atomic_key!(key, 2)
                    atomic_setval(tran, key, zeros(UInt8, 5), FDBMutationType.SET_VERSIONSTAMPED_KEY)
                    commit(tran)
                    @test tran.versionstamp !== nothing
                    @test tran.versionstamp != v1
                    v2 = tran.versionstamp

                    reset(tran)
                    key = zeros(UInt8, 13)
                    key[2:11] = v2
                    key[12:13] = UInt8[1,2]
                    @test getval(tran, key) == zeros(UInt8, 5)
                    clearkey(tran, key)
                end
            end
        end
    end

    @testset "stop network" begin
        @test is_client_running()
        @test stop_client() === nothing
        @test !is_client_running()
        @test_throws Exception start_client()
    end
finally
    stop_client()
end
