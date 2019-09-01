using .CApi

#-------------------------------------------------------------------------------
# FDBError
#-------------------------------------------------------------------------------
struct FDBError
    code::fdb_error_t
    desc::String
end

strerrdesc(cs::Cstring) = (cs == C_NULL) ? "unknown" : unsafe_string(cs)
FDBError(code::fdb_error_t) = FDBError(code, strerrdesc(fdb_get_error(code)))
function FDBError(future::fdb_future_ptr_t)
    desc = Ref{Cstring}(C_NULL)
    block_until(future)
    errcode = fdb_future_get_error(future, desc)
    if desc[] == C_NULL
        # try getting it with a different API
        desc[] = fdb_get_error(errcode)
    end
    FDBError(errcode, strerrdesc(desc[]))
end

function throw_on_error(result)
    (result == 0) || throw(FDBError(result))
    nothing
end

function throw_on_error(future::fdb_future_ptr_t)
    err = FDBError(future)
    if err.code != 0
        fdb_future_destroy(future)
        throw(err)
    end
    nothing
end

function show(io::IO, err::FDBError)
    code = Int(err.code)
    print(io, "FDB error ", code, " - ", err.desc)
end

#-------------------------------------------------------------------------------
# Working with futures and starting/stopping network
#-------------------------------------------------------------------------------
"""
An opaque type that represents a Future in the FoundationDB C API.

Most functions in the FoundationDB API are asynchronous, meaning that they may
return to the caller before actually delivering their result. These functions
always return FDBFuture*. An FDBFuture object represents a result value or error
to be delivered at some future time. You can wait for a Future to be “ready” –
to have a value or error delivered – by setting a callback function, or by
blocking a thread, or by polling. Once a Future is ready, you can extract either
an error code or a value of the appropriate type (the documentation for the
original function will tell you which fdb_future_get_*() function you should
call).
"""
const FDBFuture = Ref{fdb_future_ptr_t}

cancel(future::FDBFuture) = fdb_future_cancel(future[])

function block_until(future::fdb_future_ptr_t)
    Bool(fdb_future_is_ready(future)) && return
    wait_task = @async fdb_future_block_until_ready_in_thread(future)
    fetch(wait_task)
    future
end
block_until(errcode) = errcode

function with_err_check(on_success, result::Union{fdb_future_ptr_t,fdb_error_t}, on_error=throw_on_error)
    err = FDBError(result)
    (err.code == 0) ? on_success(result) : on_error(result)
end

function err_check(result::Union{fdb_future_ptr_t,fdb_error_t}, on_error=throw_on_error)
    with_err_check((x)->x, result, on_error)
end

"""
Encapsulates starting and stopping of the FDB Network
"""
struct FDBNetwork
    addr::String
    version::Cint
    task::Task

    function FDBNetwork(addr::String="127.0.0.1:4500", version::Cint=FDB_API_VERSION)
        throw_on_error(fdb_select_api_version(version))
        throw_on_error(fdb_setup_network(addr))
        network_task = @async fdb_run_network_in_thread()
        network = new(addr, version, network_task)
    end
end

const network = Ref{Union{FDBNetwork,Nothing}}(nothing)

is_client_running() = (network[] !== nothing) && !istaskdone((network[]).task)

function start_client(addr::String="127.0.0.1:4500", version::Cint=FDB_API_VERSION)
    if network[] === nothing
        network[] = FDBNetwork(addr, version)
    elseif istaskdone((network[]).task)
        error("Client stopped. Can only start one client in the lifetime of a process.")
    end
    nothing
end

function stop_client()
    if network[] !== nothing
        if !istaskdone((network[]).task)
            fdb_stop_network()
            fetch((network[]).task)
        end
    end
    nothing
end

#-------------------------------------------------------------------------------
# Opening cluster, database, transaction
#-------------------------------------------------------------------------------

"""
An opaque type that represents a Cluster in the FoundationDB C API.
"""
mutable struct FDBCluster
    cluster_file::String
    ptr::fdb_cluster_ptr_t

    function FDBCluster(cluster_file::String="/etc/foundationdb/fdb.cluster")
        cluster = new(cluster_file, C_NULL)
        finalizer((cluster)->close(cluster), cluster)
        cluster
    end
end

function show(io::IO, cluster::FDBCluster)
    print(io, "FDBCluster(", cluster.cluster_file, ") - ", (cluster.ptr == C_NULL) ? "closed" : "open")
end

open(fn::Function, cluster::FDBCluster) = try fn(open(cluster)) finally close(cluster) end
function open(cluster::FDBCluster)
    if !isopen(cluster)
        @assert is_client_running()
        handle = with_err_check(fdb_create_cluster(cluster.cluster_file)) do future
            h = Ref{fdb_cluster_ptr_t}(C_NULL)
            fdb_future_get_cluster(future, h)
            fdb_future_destroy(future)
            h[]
        end
        cluster.ptr = handle
    end
    cluster
end

function close(cluster::FDBCluster)
    if is_client_running() && isopen(cluster)
        fdb_cluster_destroy(cluster.ptr)
        cluster.ptr = C_NULL
    end
    nothing
end

"""
An opaque type that represents a database in the FoundationDB C API.

An FDBDatabase represents a FoundationDB database - a mutable, lexicographically
ordered mapping from binary keys to binary values. Modifications to a database
are performed via transactions.
"""
mutable struct FDBDatabase
    cluster::FDBCluster
    name::String
    ptr::fdb_database_ptr_t

    function FDBDatabase(cluster::FDBCluster, name::String="DB")
        db = new(cluster, name, C_NULL)
        finalizer((db)->close(db), db)
        db
    end
end

function show(io::IO, db::FDBDatabase)
    print(io, "FDBDatabase(", db.name, ") - ", (db.ptr == C_NULL) ? "closed" : "open")
end

open(fn::Function, db::FDBDatabase) = try fn(open(db)) finally close(db) end
function open(db::FDBDatabase)
    if !isopen(db)
        @assert is_client_running()
        cl = db.cluster.ptr
        name = convert(Vector{UInt8}, codeunits(db.name))
        lname = Cint(length(name))
        handle = with_err_check(fdb_cluster_create_database(cl, name, lname)) do future
            h = Ref{fdb_database_ptr_t}(C_NULL)
            fdb_future_get_database(future, h)
            fdb_future_destroy(future)
            h[]
        end
        db.ptr = handle
    end
    db
end

function close(db::FDBDatabase)
    if is_client_running() && isopen(db)
        fdb_database_destroy(db.ptr)
        db.ptr = C_NULL
    end
    nothing
end

"""
An opaque type that represents a transaction in the FoundationDB C API.

In FoundationDB, a transaction is a mutable snapshot of a database. All read and
write operations on a transaction see and modify an otherwise-unchanging version
of the database and only change the underlying database if and when the
transaction is committed. Read operations do see the effects of previous write
operations on the same transaction. Committing a transaction usually succeeds in
the absence of conflicts.

Applications must provide error handling and an appropriate retry loop around
the application code for a transaction. See the documentation for
fdb_transaction_on_error().

Transactions group operations into a unit with the properties of atomicity,
isolation, and durability. Transactions also provide the ability to maintain an
application’s invariants or integrity constraints, supporting the property of
consistency. Together these properties are known as ACID.

Transactions are also causally consistent: once a transaction has been
successfully committed, all subsequently created transactions will see the
modifications made by it.
"""
mutable struct FDBTransaction
    db::FDBDatabase
    ptr::fdb_transaction_ptr_t
    needscommit::Bool
    versionstamp::Union{Nothing,Vector{UInt8}}
    autocommit::Bool
    trackversionstamp::Bool
    versionstampfuture::Union{Nothing,fdb_future_ptr_t}

    function FDBTransaction(db::FDBDatabase; autocommit::Bool=true, trackversionstamp::Bool=false)
        tran = new(db, C_NULL, false, nothing, autocommit, trackversionstamp, nothing)
        finalizer((tran)->close(tran), tran)
        tran
    end
end

function show(io::IO, tran::FDBTransaction)
    print(io, "FDBTransaction - ", (tran.ptr == C_NULL) ? "closed" : "open")
end

function open(fn::Function, tran::FDBTransaction)
    try
        retry = true
        result = nothing
        while retry
            result = fn(open(tran))
            retry = tran.autocommit && tran.needscommit && !commit(tran)
        end
        result
    finally
        close(tran)
    end
end
function open(tran::FDBTransaction)
    if !isopen(tran)
        @assert is_client_running()
        db = tran.db.ptr
        h = Ref{fdb_database_ptr_t}(C_NULL)
        handle = with_err_check(fdb_database_create_transaction(db, h)) do result
            h[]
        end
        tran.ptr = handle
    end
    tran
end

function close(tran::FDBTransaction)
    if is_client_running() && isopen(tran)
        fdb_transaction_destroy(tran.ptr)
        tran.ptr = C_NULL
    end
    nothing
end

"""
Check if it is open.
"""
isopen(x::Union{FDBCluster,FDBDatabase,FDBTransaction}) = !(x.ptr === C_NULL)

#-------------------------------------------------------------------------------
# Transaction Ops
#-------------------------------------------------------------------------------

function reset(tran::FDBTransaction)
    fdb_transaction_reset(tran.ptr)
    nothing
end

function cancel(tran::FDBTransaction)
    fdb_transaction_cancel(tran.ptr)
    tran.needscommit = false
    nothing
end

"""
- returns true on success
- returns false on a retryable error
- throws error on non-retryable error
"""
function retry_on_error(tran::FDBTransaction, future::fdb_future_ptr_t)
    err = FDBError(future)
    if err.code != 0
        throw_on_error(fdb_transaction_on_error(tran.ptr, err.code))
        return false
    end
    true
end

function commit(tran::FDBTransaction, on_error=(result)->retry_on_error(tran,result))
    ret = err_check(fdb_transaction_commit(tran.ptr), on_error)

    if (!isa(ret, Bool) || ret) && tran.trackversionstamp && (tran.versionstampfuture !== nothing)
        keyptr = Ref{Ptr{UInt8}}(C_NULL)
        keylen = Ref{Cint}(0)
        err_check(fdb_future_get_key(tran.versionstampfuture, keyptr, keylen))
        tran.versionstamp = copy(unsafe_wrap(Array, keyptr[], (keylen[],), own=false))
        fdb_future_destroy(tran.versionstampfuture)
        tran.versionstampfuture = nothing
    end

    if isa(ret, Bool)
        if ret
            tran.needscommit = false
        end
        ret
    else
        tran.needscommit = false
        true
    end
end

function get_read_version(tran::FDBTransaction)
    ver = Ref{Int64}(0)
    with_err_check(fdb_transaction_get_read_version(tran.ptr)) do result
        fdb_future_get_version(result, ver)
        fdb_future_destroy(result)
    end
    ver[]
end

function set_read_version(tran::FDBTransaction, version)
    fdb_transaction_set_read_version(tran.ptr, Int64(version))
end

function get_committed_version(tran::FDBTransaction)
    ver = Ref{Int64}(0)
    err_check(fdb_transaction_get_committed_version(tran.ptr, ver))
    ver[]
end

#-------------------------------------------------------------------------------
# Get Set Ops
#-------------------------------------------------------------------------------
struct fdb_key_sel_t
    last_less_than::Symbol
    last_less_or_equal::Symbol
    first_greater_than::Symbol
    first_greater_or_equal::Symbol
end
const FDBKeySel = fdb_key_sel_t(:last_less_than, :last_less_or_equal, :first_greater_than, :first_greater_or_equal)

function keysel(mode::Symbol, key::Vector{UInt8})
    len = Cint(length(key))
    (mode === FDBKeySel.last_less_than)         ? (key, len, Cint(0), Cint(0)) :
    (mode === FDBKeySel.last_less_or_equal)     ? (key, len, Cint(1), Cint(0)) :
    (mode === FDBKeySel.first_greater_than)     ? (key, len, Cint(1), Cint(1)) :
    (mode === FDBKeySel.first_greater_or_equal) ? (key, len, Cint(0), Cint(1)) :
    error("unknown key selector $mode")
end

copyval(tran::FDBTransaction, present::Bool, val::Vector{UInt8}) = present ? copy(val) : nothing

function clearkey(tran::FDBTransaction, key::Vector{UInt8})
    ret = fdb_transaction_clear(tran.ptr, key, Cint(length(key)))
    tran.needscommit = true
    ret
end

function clearkeyrange(tran::FDBTransaction, begin_key::Vector{UInt8}, end_key::Vector{UInt8})
    ret = fdb_transaction_clear_range(tran.ptr, begin_key, Cint(length(begin_key)), end_key, Cint(length(end_key)))
    tran.needscommit = true
    ret
end

getkey(tran::FDBTransaction, keyselector) = getkey(copyval, tran, keyselector)
function getkey(fn::Function, tran::FDBTransaction, keyselector)
    keyptr = Ref{Ptr{UInt8}}(C_NULL)
    keylen = Ref{Cint}(0)
    with_err_check(fdb_transaction_get_key(tran.ptr, keyselector...)) do result
        err_check(fdb_future_get_key(result, keyptr, keylen))
        key = fn(tran, true, unsafe_wrap(Array, keyptr[], (keylen[],), own=false))
        fdb_future_destroy(result)
        key
    end::Vector{UInt8}
end

getval(tran::FDBTransaction, key::Vector{UInt8}) = getval(copyval, tran, key)
function getval(fn::Function, tran::FDBTransaction, key::Vector{UInt8})
    val = nothing
    present = Ref{fdb_bool_t}(false)
    valptr = Ref{Ptr{UInt8}}(C_NULL)
    vallen = Ref{Cint}(0)
    with_err_check(fdb_transaction_get(tran.ptr, key, Cint(length(key)))) do result
        err_check(fdb_future_get_value(result, present, valptr, vallen))
        val = fn(tran, Bool(present[]), unsafe_wrap(Array, valptr[], (vallen[],), own=false))
        fdb_future_destroy(result)
    end
    val
end

copykeyval(tran::FDBTransaction, key::Vector{UInt8}, val::Vector{UInt8}) = (copy(key),copy(val))
function copykeyval(tran::FDBTransaction, keyval::fdb_kv_t)
    key = unsafe_wrap(Array, convert(Ptr{UInt8}, keyval.key), (keyval.key_length,), own=false)
    val = unsafe_wrap(Array, convert(Ptr{UInt8}, keyval.value), (keyval.value_length,), own=false)
    copykeyval(tran, key, val)
end
collectkeyval(tran::FDBTransaction, keyval::fdb_kv_t, into) = push!(into, copykeyval(tran, keyval))
function collectkeyval(tran::FDBTransaction, keyvals::Vector{fdb_kv_t}, into)
    for keyval in keyvals
        collectkeyval(tran, keyval, into)
    end
    into
end
function getrange(tran::FDBTransaction, begin_keysel, end_keysel, into=Vector{Tuple{Vector{UInt8},Vector{UInt8}}}(); kwargs...)
    getrange(tran, begin_keysel, end_keysel; kwargs...) do tran, keyval
        collectkeyval(tran, keyval, into)
    end
end
function getrange(fn::Function, tran::FDBTransaction, begin_keysel, end_keysel; limit::Integer=0, target_bytes::Integer=0,
        streaming_mode::Cint=FDBStreamingMode.WANT_ALL, iteration::Integer=0, snapshot::Integer=0, reverse::Bool=false)
    more = Ref{fdb_bool_t}(false)
    count = Ref{Cint}(0)
    kvptr = Ref{Ptr{Nothing}}(C_NULL)

    fnoutput = with_err_check(fdb_transaction_get_range(tran.ptr,
        begin_keysel[1], begin_keysel[2], begin_keysel[3], begin_keysel[4],
        end_keysel[1], end_keysel[2], end_keysel[3], end_keysel[4],
        Cint(limit), Cint(target_bytes), Cint(streaming_mode), Cint(iteration), Cint(snapshot), fdb_bool_t(reverse ? 1 : 0))) do result

        fnoutput = nothing
        err_check(fdb_future_get_keyvalue_array(result, kvptr, count, more))
        if count[] > 0
            total_size = (sizeof(Ptr{Nothing}) + sizeof(Cint)) * 2 * count[]
            ptr = convert(Ptr{UInt8}, kvptr[])
            valarr = Vector{fdb_kv_t}()
            # the fields are byte packed
            for idx in 1:(count[])
                _key = unsafe_load(convert(Ptr{Ptr{Nothing}}, ptr))
                ptr += sizeof(Ptr{Nothing})
                _key_length = unsafe_load(convert(Ptr{Cint}, ptr))
                ptr += sizeof(Cint)
                _value = unsafe_load(convert(Ptr{Ptr{Nothing}}, ptr))
                ptr += sizeof(Ptr{Nothing})
                _value_length = unsafe_load(convert(Ptr{Cint}, ptr))
                ptr += sizeof(Cint)
                push!(valarr, fdb_kv_t(_key, _key_length, _value, _value_length))
            end
            fnoutput = fn(tran, valarr)
        end
        fdb_future_destroy(result)
        fnoutput
    end
    fnoutput, Bool(more[])
end

function setval(tran::FDBTransaction, key::Vector{UInt8}, val::Vector{UInt8})
    ret = fdb_transaction_set(tran.ptr, key, Cint(length(key)), val, Cint(length(val)))
    tran.needscommit = true
    ret
end

function watchkey_internal(fn::Function, tran::FDBTransaction, key::Vector{UInt8}, on_finish::Function, handle::Union{Nothing,FDBFuture})
    future = fdb_transaction_watch(tran.ptr, key, Cint(length(key)))
    (handle === nothing) || (handle[] = future)
    tran.needscommit = true
    fn(tran, key)
    err_check(future)
    nothing
end

function watchkey(tran::FDBTransaction, key::Vector{UInt8}; on_finish::Function=err_check, handle::Union{Nothing,FDBFuture}=nothing)
    watchstarted = Future()
    watch_task = @async watchkey_internal(tran, key, on_finish, handle) do tran, key
        put!(watchstarted, true)
    end
    wait(watchstarted)
    watch_task
end

function atomic(tran::FDBTransaction, key::Vector{UInt8}, param::Vector{UInt8}, op::Cint)
    tran.needscommit = true
    fdb_transaction_atomic_op(tran.ptr, key, Cint(length(key)), param, Cint(length(param)), op)
end

function atomic_add(tran::FDBTransaction, key::Vector{UInt8}, param::Integer)
    leparam = htol(param) # ensure param is little-endian, unsigned or signed in two's complement format
    param_bytes = convert(Vector{UInt8}, reinterpret(UInt8, [leparam]))
    atomic(tran, key, param_bytes, FDBMutationType.ADD)
end

function atomic_max(tran::FDBTransaction, key::Vector{UInt8}, param::Cuint)
    param_bytes = convert(Vector{UInt8}, reinterpret(UInt8, [param]))
    atomic(tran, key, param_bytes, FDBMutationType.MAX)
end

function atomic_min(tran::FDBTransaction, key::Vector{UInt8}, param::Cuint)
    param_bytes = convert(Vector{UInt8}, reinterpret(UInt8, [param]))
    atomic(tran, key, param_bytes, FDBMutationType.MIN)
end

"""
Loads the value read as an integer type.

Suitable for reading back values for keys used with `atomic_add`, `atomic_max`, `atomic_min` operations.
"""
atomic_integer(::Type{T}, val::Vector{UInt8}) where {T <: Integer} = unsafe_load(convert(Ptr{T}, pointer(val)))

atomic_and(tran::FDBTransaction, key::Vector{UInt8}, param::Vector{UInt8}) = atomic(tran, key, param, FDBMutationType.AND)
atomic_or(tran::FDBTransaction,  key::Vector{UInt8}, param::Vector{UInt8}) = atomic(tran, key, param, FDBMutationType.OR)
atomic_xor(tran::FDBTransaction, key::Vector{UInt8}, param::Vector{UInt8}) = atomic(tran, key, param, FDBMutationType.XOR)
atomic_max(tran::FDBTransaction, key::Vector{UInt8}, param::Vector{UInt8}) = atomic(tran, key, param, FDBMutationType.BYTE_MAX)
atomic_min(tran::FDBTransaction, key::Vector{UInt8}, param::Vector{UInt8}) = atomic(tran, key, param, FDBMutationType.BYTE_MIN)
function prep_atomic_key!(key::Vector{UInt8}, versionpos::Integer)
    pos = htol(UInt16(versionpos-1))  # make it 0 based index
    pos_bytes = reinterpret(UInt8, [pos])
    splice!(key, versionpos:(versionpos-1), zeros(UInt8, 10))
    splice!(key, (length(key)+1):length(key), pos_bytes)
    key
end
function atomic_setval(tran::FDBTransaction, key::Vector{UInt8}, val::Vector{UInt8}, op::Cint)
    @assert (op == FDBMutationType.SET_VERSIONSTAMPED_KEY) || (op == FDBMutationType.SET_VERSIONSTAMPED_VALUE)
    atomic(tran, key, val, op)
    if tran.trackversionstamp && (tran.versionstampfuture === nothing)
        tran.versionstampfuture = fdb_transaction_get_versionstamp(tran.ptr)
    end
    nothing
end

function conflict(tran::FDBTransaction, begin_key::Vector{UInt8}, end_key::Vector{UInt8}, conflict_type::fdb_conflict_range_type_t)
    err_check(fdb_transaction_add_conflict_range(tran.ptr, begin_key, Cint(length(begin_key)), end_key, Cint(length(end_key)), conflict_type))
end
