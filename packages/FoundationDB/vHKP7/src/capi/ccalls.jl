#------------------------------------------------------------------------------
# LIBRARY INITIALIZATION
#------------------------------------------------------------------------------

"""
C function:
```
fdb_error_t fdb_select_api_version_impl(
    int runtime_version,
    int header_version
)
```

This is the actual entry point called by fdb_select_api_version(). It should
never be called directly. fdb_select_api_version(v) is equivalent to
fdb_select_api_version_impl(v, FDB_API_VERSION).

It is an error to call this function after it has returned successfully. It is
not thread safe, and if called from more than one thread simultaneously its
behavior is undefined.

Parameters:
- runtime_version: Version of run-time behavior the API is requested to provide.
    Must be less than or equal to header_version, and almost always be equal.
- header_version: Version of the ABI (application binary interface) that the
    calling code expects to find in the shared library. If you are using an FFI,
    this must correspond to the version of the API you are using as a reference
    (currently 510). E.g., the number of arguments that a function takes may be
    affected by this value, and an incorrect value is unlikely to yield success.
"""
function fdb_select_api_version_impl(runtime_version, header_version)
    ccall((:fdb_select_api_version_impl, fdb_c), fdb_error_t, (Cint, Cint), Cint(runtime_version), Cint(header_version))
end

"""
C function:
`fdb_error_t fdb_select_api_version(int version)`

Must be called before any other API functions.
Parameter version must be <= FDB_API_VERSION (and almost always equal).

Parameters:
- runtime_version: Version of run-time behavior the API is requested to provide.
    Must be <= header_version, and should almost always be equal.
"""
function fdb_select_api_version(runtime_version)
    fdb_select_api_version_impl(Cint(runtime_version), fdb_get_max_api_version())
end

"""
C function:
`int fdb_get_max_api_version()`

Returns FDB_API_VERSION, the current version of the FoundationDB C API.
This is the maximum version that may be passed to fdb_select_api_version().
"""
function fdb_get_max_api_version()
    ccall((:fdb_get_max_api_version, fdb_c), Cint, ())
end

function fdb_get_client_version()
    ccall((:fdb_get_client_version, fdb_c), Cstring, ())
end


#------------------------------------------------------------------------------
# STARTING / STOPPING THE CLIENT EVENT LOOP
#------------------------------------------------------------------------------
"""
C function:
```
fdb_error_t fdb_network_set_option(
    FDBNetworkOption option,
    uint8_t const* value,
    int value_length
)
```

Called to set network options.

If the given option is documented as taking a parameter, you must also pass a
pointer to the parameter value and the parameter value’s length. If the option
is documented as taking an Int parameter, value must point to a signed 64-bit
integer (little-endian), and value_length must be 8. This memory only needs to
be valid until fdb_network_set_option() returns.
"""
function fdb_network_set_option(option::fdb_network_option_t, value, value_length::Cint)
    ccall((:fdb_network_set_option, fdb_c), fdb_error_t, (fdb_network_option_t, Ptr{UInt8}, Cint), option, value, value_length)
end

"""
C function:
`fdb_error_t fdb_setup_network()`

Can be called only once, and after fdb_select_api_version() (and zero or more
calls to fdb_network_set_option()) and before any other function in this API.
"""
function fdb_setup_network(local_address)
    ccall((:fdb_setup_network, fdb_c), fdb_error_t, (Cstring,), local_address)
end

"""
C function:
`fdb_error_t fdb_run_network()`

Must be called after fdb_setup_network() before any asynchronous functions in
this API can be expected to complete. Unless your program is entirely event
driven based on results of asynchronous functions in this API and has no event
loop of its own, you will want to invoke this function on an auxiliary thread
(which it is your responsibility to create).

This function will not return until fdb_stop_network() is called by you or a
serious error occurs. You must not invoke fdb_run_network() concurrently or
reentrantly while it is already running.

In Julia, use `@threadcall` to invoke this.
"""
function fdb_run_network()
    ccall((:fdb_run_network, fdb_c), fdb_error_t, ())
end
function fdb_run_network_in_thread()
    if Threads.nthreads() < 2
        error("You must enable threading in Julia and configure JULIA_NUM_THREADS to be at least 2. It is now $(Threads.nthreads())")
    end
    @threadcall((:fdb_run_network, fdb_c), fdb_error_t, ())
end

"""
C function:
`fdb_error_t fdb_stop_network()`

Signals the event loop invoked by fdb_run_network() to terminate. You must call
this function and wait for fdb_run_network() to return before allowing your
program to exit, or else the behavior is undefined.

This function may be called from any thread. Once the network is stopped it
cannot be restarted during the lifetime of the running program.
"""
function fdb_stop_network()
    ccall((:fdb_stop_network, fdb_c), fdb_error_t, ())
end

"""
C function:
```
fdb_error_t fdb_add_network_thread_completion_hook(
    void (*hook)(void*),
    void *hook_parameter)
```

Must be called after fdb_setup_network() and prior to fdb_run_network() if
called at all. This will register the given callback to run at the completion of
the network thread. If there are multiple network threads running (which might
occur if one is running multiple versions of the client, for example), then the
callback is invoked once on each thread. When the supplied function is called,
the supplied parameter is passed to it.

In Julia, if the network is being run with `@threadcall`, this method must not
be used, because calling back to Julia is not allowed in `@threadcall`.
"""
function fdb_add_network_thread_completion_hook(hook, hook_parameter)
    ccall((:fdb_add_network_thread_completion_hook, fdb_c), fdb_error_t, (Ptr{Nothing}, Ptr{Nothing}), hook, hook_parameter)
end

#------------------------------------------------------------------------------
# FUTURES
#------------------------------------------------------------------------------
"""
C function:
`void fdb_future_cancel(FDBFuture* future)`

Cancels an FDBFuture object and its associated asynchronous operation. If called
before the future is ready, attempts to access its value will return an
operation_cancelled error. Cancelling a future which is already ready has no
effect. Note that even if a future is not ready, its associated asynchronous
operation may have succesfully completed and be unable to be cancelled.
"""
function fdb_future_cancel(f)
    ccall((:fdb_future_cancel, fdb_c), Nothing, (fdb_future_ptr_t,), f)
end

"""
C function:
`void fdb_future_destroy(FDBFuture* future)`

Destroys an FDBFuture object. It must be called exactly once for each FDBFuture*
returned by an API function. It may be called before or after the future is
ready. It will also cancel the future (and its associated operation if the
latter is still outstanding).
"""
function fdb_future_destroy(f)
    ccall((:fdb_future_destroy, fdb_c), Nothing, (fdb_future_ptr_t,), f)
end

"""
C function:
`fdb_error_t fdb_future_block_until_ready(FDBFuture* future)`

Blocks the calling thread until the given Future is ready. It will return
success even if the Future is set to an error – you must call
fdb_future_get_error() to determine that. fdb_future_block_until_ready() will
return an error only in exceptional conditions (e.g. out of memory or other
operating system resources).
"""
function fdb_future_block_until_ready(f)
    ccall((:fdb_future_block_until_ready, fdb_c), fdb_error_t, (fdb_future_ptr_t,), f)
end
function fdb_future_block_until_ready_in_thread(f)
    if Threads.nthreads() < 2
        error("You must enable threading in Julia and configure JULIA_NUM_THREADS to be at least 2. It is now $(Threads.nthreads())")
    end
    @threadcall((:fdb_future_block_until_ready, fdb_c), fdb_error_t, (fdb_future_ptr_t,), f)
end

"""
C function:
`fdb_bool_t fdb_future_is_ready(FDBFuture* future)`

Returns non-zero if the Future is ready. A Future is ready if it has been set to
a value or an error.
"""
function fdb_future_is_ready(f)
    ccall((:fdb_future_is_ready, fdb_c), fdb_bool_t, (fdb_future_ptr_t,), f)
end

"""
C function:
```
fdb_error_t fdb_future_set_callback(
    FDBFuture* future,
    FDBCallback callback,
    void* callback_parameter)
```

Causes the FDBCallback function to be invoked as
callback(future, callback_parameter) when the given Future is ready. If the
Future is already ready, the call may occur in the current thread before this
function returns (but this behavior is not guaranteed). Alternatively, the call
may be delayed indefinitely and take place on the thread on which
fdb_run_network() was invoked, and the callback is responsible for any necessary
thread synchronization (and/or for posting work back to your application event
loop, thread pool, etc. if your application’s architecture calls for that).
"""
function fdb_future_set_callback(f, callback::FDBCallback, callback_parameter)
    ccall((:fdb_future_set_callback, fdb_c), fdb_error_t, (fdb_future_ptr_t, FDBCallback, Ptr{Nothing}), f, callback, callback_parameter)
end

"""
C function:
`void fdb_future_release_memory(FDBFuture* future)`

This function may only be called after a successful (zero return value) call to
fdb_future_get_key(), fdb_future_get_value(), or
fdb_future_get_keyvalue_array(). It indicates that the memory returned by the
prior get call is no longer needed by the application. After this function has
been called the same number of times as fdb_future_get_*(), further calls to
fdb_future_get_*() will return a future_released error. It is still necessary to
later destroy the future with fdb_future_destroy().

Calling this function is optional, since fdb_future_destroy() will also release
the memory returned by get functions. However, fdb_future_release_memory()
leaves the future object itself intact and provides a specific error code which
can be used for coordination by multiple threads racing to do something with the
results of a specific future. This has proven helpful in writing binding code.

Note: This function provides no benefit to most application code. It is designed
for use in writing generic, thread-safe language bindings. Applications should
normally call fdb_future_destroy() only.
"""
function fdb_future_release_memory(f)
    ccall((:fdb_future_release_memory, fdb_c), Nothing, (fdb_future_ptr_t,), f)
end

"""
C function:
`fdb_error_t fdb_future_get_error(FDBFuture* future)`

Returns zero if future is ready and not in an error state, and a non-zero error code otherwise.
"""
function fdb_future_get_error(f, out_description)
    ccall((:fdb_future_get_error, fdb_c), fdb_error_t, (fdb_future_ptr_t, Ptr{Cstring}), f, out_description)
end

#=
# API has been removed (throws: REMOVED FDB API FUNCTION)
function fdb_future_is_error(f)
    ccall((:fdb_future_is_error, fdb_c), fdb_bool_t, (fdb_future_ptr_t,), f)
end
=#

"""
C function:
```
fdb_error_t fdb_future_get_keyvalue_array(
    FDBFuture* future,
    FDBKeyValue const** out_kv,
    int* out_count,
    fdb_bool_t* out_more
)
```

Extracts an array of FDBKeyValue objects from an FDBFuture into caller-provided
variables. future must represent a result of the appropriate type (i.e. must
have been returned by a function documented as returning this type), or the
results are undefined.

Returns zero if future is ready and not in an error state, and a non-zero error
code otherwise (in which case the value of any out parameter is undefined).

Parameters:
- out_kv: Set to point to the first FDBKeyValue object in the array.
- out_count: Set to the number of FDBKeyValue objects in the array.
- out_more: Set to true if (but not necessarily only if) values remain in the
    key range requested (possibly beyond the limits requested).

The memory referenced by the result is owned by the FDBFuture object and will be
valid until either fdb_future_destroy(future) or
fdb_future_release_memory(future) is called.
"""
function fdb_future_get_keyvalue_array(f, out_kv, out_count, out_more)
    ccall((:fdb_future_get_keyvalue_array, fdb_c), fdb_error_t, (fdb_future_ptr_t, Ptr{Ptr{Nothing}}, Ptr{Cint}, Ptr{fdb_bool_t}), f, out_kv, out_count, out_more)
end

"""
C function:
`fdb_error_t fdb_future_get_version(FDBFuture* future, int64_t* out_version)`

Extracts a value of type version from an FDBFuture into a caller-provided
variable of type int64_t. future must represent a result of the appropriate type
(i.e. must have been returned by a function documented as returning this type),
or the results are undefined.

Returns zero if future is ready and not in an error state, and a non-zero error
code otherwise (in which case the value of any out parameter is undefined).
"""
function fdb_future_get_version(f, out_version)
    ccall((:fdb_future_get_version, fdb_c), fdb_error_t, (fdb_future_ptr_t, Ptr{Int64}), f, out_version)
end

"""
C function:
```
fdb_error_t fdb_future_get_key(
    FDBFuture* future,
    uint8_t const** out_key,
    int* out_key_length
)
```

Extracts a value of type key from an FDBFuture into caller-provided variables of
type uint8_t* (a pointer to the beginning of the key) and int (the length of the
key). future must represent a result of the appropriate type (i.e. must have
been returned by a function documented as returning this type), or the results
are undefined.

Returns zero if future is ready and not in an error state, and a non-zero error
code otherwise (in which case the value of any out parameter is undefined).

The memory referenced by the result is owned by the FDBFuture object and will be
valid until either fdb_future_destroy(future) or
fdb_future_release_memory(future) is called.
"""
function fdb_future_get_key(f, out_key, out_key_length)
    ccall((:fdb_future_get_key, fdb_c), fdb_error_t, (fdb_future_ptr_t, Ptr{Ptr{UInt8}}, Ptr{Cint}), f, out_key, out_key_length)
end

"""
C function:
```
fdb_error_t fdb_future_get_cluster(
    FDBFuture* future,
    FDBCluster** out_cluster
)
```

Extracts a value of type FDBCluster* from an FDBFuture into a caller-provided
variable. future must represent a result of the appropriate type (i.e. must have
been returned by a function documented as returning this type), or the results
are undefined.

Returns zero if future is ready and not in an error state, and a non-zero error
code otherwise (in which case the value of any out parameter is undefined).

This function may only be called once on a given FDBFuture object, as it
transfers ownership of the FDBCluster to the caller. The caller is responsible
for calling fdb_cluster_destroy() when finished with the result.
"""
function fdb_future_get_cluster(f, out_cluster)
    ccall((:fdb_future_get_cluster, fdb_c), fdb_error_t, (fdb_future_ptr_t, Ptr{fdb_cluster_ptr_t}), f, out_cluster)
end

"""
C function:
```
fdb_error_t fdb_future_get_database(
    FDBFuture* future,
    FDBDatabase** out_database
)
```

Extracts a value of type FDBDatabase* from an FDBFuture into a caller-provided
variable. future must represent a result of the appropriate type (i.e. must have
been returned by a function documented as returning this type), or the results
are undefined.

Returns zero if future is ready and not in an error state, and a non-zero error
code otherwise (in which case the value of any out parameter is undefined).

This function may only be called once on a given FDBFuture object, as it
transfers ownership of the FDBDatabase to the caller. The caller is responsible
for calling fdb_database_destroy(*out_database) when finished with the result.
"""
function fdb_future_get_database(f, out_database)
    ccall((:fdb_future_get_database, fdb_c), fdb_error_t, (fdb_future_ptr_t, Ptr{fdb_database_ptr_t}), f, out_database)
end

"""
C function:
```
fdb_error_t fdb_future_get_value(
    FDBFuture* future,
    fdb_bool_t* out_present,
    uint8_t const** out_value,
    int* out_value_length
)
```

Extracts a database value from an FDBFuture into caller-provided variables.
future must represent a result of the appropriate type (i.e. must have been
returned by a function documented as returning this type), or the results are
undefined.

Returns zero if future is ready and not in an error state, and a non-zero error
code otherwise (in which case the value of any out parameter is undefined).

Parameters:
- out_present: Set to non-zero if (and only if) the requested value was present
    in the database. (If zero, the other outputs are meaningless.)
- out_value: Set to point to the first byte of the value.
- out_value_length: Set to the length of the value (in bytes).

The memory referenced by the result is owned by the FDBFuture object and will be
valid until either fdb_future_destroy(future) or
fdb_future_release_memory(future) is called.
"""
function fdb_future_get_value(f, out_present, out_value, out_value_length)
    ccall((:fdb_future_get_value, fdb_c), fdb_error_t, (fdb_future_ptr_t, Ptr{fdb_bool_t}, Ptr{Ptr{UInt8}}, Ptr{Cint}), f, out_present, out_value, out_value_length)
end

"""
C function:
```
fdb_error_t fdb_future_get_string_array(
    FDBFuture* future,
    const char*** out_strings,
    int* out_count
)
```

Extracts an array of null-terminated C strings from an FDBFuture into
caller-provided variables. future must represent a result of the appropriate
type (i.e. must have been returned by a function documented as returning this
type), or the results are undefined.

Returns zero if future is ready and not in an error state, and a non-zero error
code otherwise (in which case the value of any out parameter is undefined).

Parameters:
- out_strings: Set to point to the first string in the array.
- out_count: Set to the number of strings in the array.

The memory referenced by the result is owned by the FDBFuture object and will be
valid until either fdb_future_destroy(future) or
fdb_future_release_memory(future) is called.
"""
function fdb_future_get_string_array(f, out_strings, out_count)
    ccall((:fdb_future_get_string_array, fdb_c), fdb_error_t, (fdb_future_ptr_t, Ptr{Ptr{Cstring}}, Ptr{Cint}), f, out_strings, out_count)
end

#------------------------------------------------------------------------------
# CLUSTER
#------------------------------------------------------------------------------

"""
C function:
`FDBFuture* fdb_create_cluster(const char* cluster_file_path)`

Returns an FDBFuture which will be set to an FDBCluster object. You must first
wait for the FDBFuture to be ready, check for errors, call
fdb_future_get_cluster() to extract the FDBCluster object, and then destroy the
FDBFuture with fdb_future_destroy().

Parameters:
- cluster_file_path: A NULL-terminated string giving a local path of a cluster
    file (often called ‘fdb.cluster’) which contains connection information for
    the FoundationDB cluster. If cluster_file_path is NULL or an empty string,
    then a default cluster file will be used.
"""
function fdb_create_cluster(cluster_file_path)
    ccall((:fdb_create_cluster, fdb_c), fdb_future_ptr_t, (Cstring,), cluster_file_path)
end

"""
C function:
`void fdb_cluster_destroy(FDBCluster* cluster)`

Destroys an FDBCluster object. It must be called exactly once for each
successful call to fdb_future_get_cluster(). This function only destroys a
handle to the cluster - your cluster will be fine!
"""
function fdb_cluster_destroy(c)
    ccall((:fdb_cluster_destroy, fdb_c), Nothing, (fdb_cluster_ptr_t,), c)
end

"""
C function:
```
fdb_error_t fdb_cluster_set_option(
    FDBCluster* cluster,
    FDBClusterOption option,
    uint8_t const* value,
    int value_length
)
```

Called to set an option on an FDBCluster. If the given option is documented as
taking a parameter, you must also pass a pointer to the parameter value and the
parameter value’s length. If the option is documented as taking an Int
parameter, value must point to a signed 64-bit integer (little-endian), and
value_length must be 8. This memory only needs to be valid until
fdb_cluster_set_option() returns.
"""
function fdb_cluster_set_option(c, option::fdb_cluster_option_t, value, value_length::Cint)
    ccall((:fdb_cluster_set_option, fdb_c), fdb_error_t, (fdb_cluster_ptr_t, fdb_cluster_option_t, Ptr{UInt8}, Cint), c, option, value, value_length)
end

"""
C function:
```
FDBFuture* fdb_cluster_create_database(
    FDBCluster *cluster,
    uint8_t const* db_name,
    int db_name_length
)
```

Returns an FDBFuture which will be set to an FDBDatabase object. You must first
wait for the FDBFuture to be ready, check for errors, call
fdb_future_get_database() to extract the FDBDatabase object, and then destroy
the FDBFuture with fdb_future_destroy().

Parameters:
- db_name: A pointer to the name of the database to be opened. The value does
    not need to be NULL-terminated. In the current FoundationDB API, the
    database name must be “DB”.
- db_name_length: The length of the parameter specified by db_name.
"""
function fdb_cluster_create_database(c, db_name, db_name_length::Cint)
    ccall((:fdb_cluster_create_database, fdb_c), fdb_future_ptr_t, (fdb_cluster_ptr_t, Ptr{UInt8}, Cint), c, db_name, db_name_length)
end

#------------------------------------------------------------------------------
# DATABASE
#------------------------------------------------------------------------------

"""
C function:
`void fdb_database_destroy(FDBDatabase* database)`

Destroys an FDBDatabase object. It must be called exactly once for each
successful call to fdb_future_get_database(). This function only destroys a
handle to the database – your database will be fine!
"""
function fdb_database_destroy(d)
    ccall((:fdb_database_destroy, fdb_c), Nothing, (fdb_database_ptr_t,), d)
end

"""
C function:
```
fdb_error_t fdb_database_set_option(
    FDBDatabase* database,
    FDBDatabaseOption option,
    uint8_t const* value,
    int value_length)
```

Called to set an option an on FDBDatabase. If the given option is documented as
taking a parameter, you must also pass a pointer to the parameter value and the
parameter value’s length. If the option is documented as taking an Int
parameter, value must point to a signed 64-bit integer (little-endian), and
value_length must be 8. This memory only needs to be valid until
fdb_database_set_option() returns.
"""
function fdb_database_set_option(d, option::fdb_database_option_t, value, value_length::Cint)
    ccall((:fdb_database_set_option, fdb_c), fdb_error_t, (fdb_database_ptr_t, fdb_database_option_t, Ptr{UInt8}, Cint), d, option, value, value_length)
end

"""
C function:
`fdb_error_t fdb_database_create_transaction(FDBDatabase* database, FDBTransaction** out_transaction)`

Creates a new transaction on the given database. The caller assumes ownership of
the FDBTransaction object and must destroy it with fdb_transaction_destroy().

Parameters:
- out_transaction: Set to point to the newly created FDBTransaction.
"""
function fdb_database_create_transaction(d, out_transaction)
    ccall((:fdb_database_create_transaction, fdb_c), fdb_error_t, (fdb_database_ptr_t, Ptr{fdb_transaction_ptr_t}), d, out_transaction)
end

#------------------------------------------------------------------------------
# TRANSACTION
#------------------------------------------------------------------------------

"""
C function:
`void fdb_transaction_destroy(FDBTransaction* transaction)`

Destroys an FDBTransaction object. It must be called exactly once for each
successful call to fdb_database_create_transaction(). Destroying a transaction
which has not had fdb_transaction_commit() called implicitly “rolls back” the
transaction (sets and clears do not take effect on the database).
"""
function fdb_transaction_destroy(tr)
    ccall((:fdb_transaction_destroy, fdb_c), Nothing, (fdb_transaction_ptr_t,), tr)
end

"""
C function:
```
fdb_error_t fdb_transaction_set_option(
    FDBTransaction* transaction,
    FDBTransactionOption option,
    uint8_t const* value,
    int value_length)
```

Called to set an option on an FDBTransaction. If the given option is documented
as taking a parameter, you must also pass a pointer to the parameter value and
the parameter value’s length. If the option is documented as taking an Int
parameter, value must point to a signed 64-bit integer (little-endian), and
value_length must be 8. This memory only needs to be valid until
fdb_transaction_set_option() returns.
"""
function fdb_transaction_set_option(tr, option::fdb_transaction_option_t)
    ccall((:fdb_transaction_set_option, fdb_c), Nothing, (fdb_transaction_ptr_t, fdb_transaction_option_t), tr, option)
end

"""
C function:
`void fdb_transaction_cancel(FDBTransaction* transaction)`

Cancels the transaction. All pending or future uses of the transaction will
return a transaction_cancelled error. The transaction can be used again after it
is reset.

Warning: Be careful if you are using fdb_transaction_reset() and
    fdb_transaction_cancel() concurrently with the same transaction. Since they
    negate each other’s effects, a race condition between these calls will leave
    the transaction in an unknown state.

Warning: If your program attempts to cancel a transaction after
    fdb_transaction_commit() has been called but before it returns,
    unpredictable behavior will result. While it is guaranteed that the
    transaction will eventually end up in a cancelled state, the commit may or
    may not occur. Moreover, even if the call to fdb_transaction_commit()
    appears to return a transaction_cancelled error, the commit may have
    occurred or may occur in the future. This can make it more difficult to
    reason about the order in which transactions occur.
"""
function fdb_transaction_cancel(tr)
    ccall((:fdb_transaction_cancel, fdb_c), Nothing, (fdb_transaction_ptr_t,), tr)
end

"""
C function:
```
void fdb_transaction_set_read_version(
    FDBTransaction* transaction,
    int64_t version
)
```

Sets the snapshot read version used by a transaction. This is not needed in
simple cases. If the given version is too old, subsequent reads will fail with
error_code_past_version; if it is too new, subsequent reads may be delayed
indefinitely and/or fail with error_code_future_version. If any of
fdb_transaction_get_*() have been called on this transaction already, the result
is undefined.
"""
function fdb_transaction_set_read_version(tr, version::Int64)
    ccall((:fdb_transaction_set_read_version, fdb_c), Nothing, (fdb_transaction_ptr_t, Int64), tr, version)
end

"""
C function:
`FDBFuture* fdb_transaction_get_read_version(FDBTransaction* transaction)`

Returns an FDBFuture which will be set to the transaction snapshot read version.
You must first wait for the FDBFuture to be ready, check for errors, call
fdb_future_get_version() to extract the version into an int64_t that you
provide, and then destroy the FDBFuture with fdb_future_destroy().

The transaction obtains a snapshot read version automatically at the time of the
first call to fdb_transaction_get_*() (including this one) and (unless causal
consistency has been deliberately compromised by transaction options) is
guaranteed to represent all transactions which were reported committed before
that call.
"""
function fdb_transaction_get_read_version(tr)
    ccall((:fdb_transaction_get_read_version, fdb_c), fdb_future_ptr_t, (fdb_transaction_ptr_t,), tr)
end

"""
C function:
```
FDBFuture* fdb_transaction_get_addresses_for_key(
    FDBTransaction* transaction,
    uint8_t const* key_name,
    int key_name_length
)
```

Returns a list of public network addresses as strings, one for each of the
storage servers responsible for storing key_name and its associated value.

Returns an FDBFuture which will be set to an array of strings. You must
first wait for the FDBFuture to be ready, check for errors, call
fdb_future_get_string_array() to extract the string array, and then destroy the
FDBFuture with fdb_future_destroy().

Parameters:
- key_name: A pointer to the name of the key whose location is to be queried.
- key_name_length: The length of the parameter specified by key_name.
"""
function fdb_transaction_get_addresses_for_key(tr, key_name, key_name_length::Cint)
    ccall((:fdb_transaction_get_addresses_for_key, fdb_c), fdb_future_ptr_t, (fdb_transaction_ptr_t, Ptr{UInt8}, Cint), tr, key_name, key_name_length)
end

"""
C function:
```
void fdb_transaction_set(
    FDBTransaction* transaction,
    uint8_t const* key_name,
    int key_name_length,
    uint8_t const* value,
    int value_length
)
```

Modify the database snapshot represented by transaction to change the given key
to have the given value. If the given key was not previously present in the
database it is inserted.

The modification affects the actual database only if transaction is later
committed with fdb_transaction_commit().

Parameters:
- key_name: A pointer to the name of the key to be inserted into the database.
    The value does not need to be NULL-terminated.
- key_name_length: The length of the parameter specified by key_name.
- value: A pointer to the value to be inserted into the database. The value does
    not need to be NULL-terminated.
- value_length: The length of the parameter specified by value.
"""
function fdb_transaction_set(tr, key_name, key_name_length::Cint, value, value_length::Cint)
    ccall((:fdb_transaction_set, fdb_c), Nothing, (fdb_transaction_ptr_t, Ptr{UInt8}, Cint, Ptr{UInt8}, Cint), tr, key_name, key_name_length, value, value_length)
end

"""
C function:
```
void fdb_transaction_atomic_op(
    FDBTransaction* transaction,
    uint8_t const* key_name,
    int key_name_length,
    uint8_t const* param,
    int param_length,
    FDBMutationType operationType
)
```

Modify the database snapshot represented by transaction to perform the operation
indicated by operationType with operand param to the value stored by the given
key.

An atomic operation is a single database command that carries out several
logical steps: reading the value of a key, performing a transformation on that
value, and writing the result. Different atomic operations perform different
transformations. Like other database operations, an atomic operation is used
within a transaction; however, its use within a transaction will not cause the
transaction to conflict.

Atomic operations do not expose the current value of the key to the client but
simply send the database the transformation to apply. In regard to conflict
checking, an atomic operation is equivalent to a write without a read. It can
only cause other transactions performing reads of the key to conflict.

By combining these logical steps into a single, read-free operation,
FoundationDB can guarantee that the transaction will not conflict due to the
operation. This makes atomic operations ideal for operating on keys that are
frequently modified. A common example is the use of a key-value pair as a
counter.

Warning: If a transaction uses both an atomic operation and a serializable read
on the same key, the benefits of using the atomic operation (for both conflict
checking and performance) are lost.

The modification affects the actual database only if transaction is later
committed with fdb_transaction_commit().

- key_name: A pointer to the name of the key whose value is to be mutated.
- key_name_length: The length of the parameter specified by key_name.
- param: A pointer to the parameter with which the atomic operation will mutate
    the value associated with key_name.
- param_length: The length of the parameter specified by param.
- operation_type: One of the FDBMutationType values indicating which operation
    should be performed.
"""
function fdb_transaction_atomic_op(tr, key_name, key_name_length::Cint, param, param_length::Cint, operation_type::fdb_mutation_type_t)
    ccall((:fdb_transaction_atomic_op, fdb_c), Nothing, (fdb_transaction_ptr_t, Ptr{UInt8}, Cint, Ptr{UInt8}, Cint, fdb_mutation_type_t), tr, key_name, key_name_length, param, param_length, operation_type)
end

"""
C function:
```
void fdb_transaction_clear(
    FDBTransaction* transaction,
    uint8_t const* key_name,
    int key_name_length
)
```

Modify the database snapshot represented by transaction to remove the given key
from the database. If the key was not previously present in the database, there
is no effect.

The modification affects the actual database only if transaction is later
committed with fdb_transaction_commit().

Parameters:
- key_name: A pointer to the name of the key to be removed from the database.
    The value does not need to be NULL-terminated.
- key_name_length: The length of the parameter specified by key_name.
"""
function fdb_transaction_clear(tr, key_name, key_name_length::Cint)
    ccall((:fdb_transaction_clear, fdb_c), Nothing, (fdb_transaction_ptr_t, Ptr{UInt8}, Cint), tr, key_name, key_name_length)
end

"""
C function:
```
void fdb_transaction_clear_range(
    FDBTransaction* transaction,
    uint8_t const* begin_key_name,
    int begin_key_name_length,
    uint8_t const* end_key_name,
    int end_key_name_length
)
```

Modify the database snapshot represented by transaction to remove all keys (if
any) which are lexicographically greater than or equal to the given begin key
and lexicographically less than the given end_key.

The modification affects the actual database only if transaction is later
committed with fdb_transaction_commit().

Parameters:
- begin_key_name: A pointer to the name of the key specifying the beginning of
    the range to clear. The value does not need to be NULL-terminated.
- begin_key_name_length: The length of the parameter specified by begin_key_name
- end_key_name: A pointer to the name of the key specifying the end of the range
    to clear. The value does not need to be NULL-terminated.
- end_key_name_length: The length of the parameter specified by
    end_key_name_length.
"""
function fdb_transaction_clear_range(tr, begin_key_name, begin_key_name_length::Cint, end_key_name, end_key_name_length::Cint)
    ccall((:fdb_transaction_clear_range, fdb_c), Nothing, (fdb_transaction_ptr_t, Ptr{UInt8}, Cint, Ptr{UInt8}, Cint), tr, begin_key_name, begin_key_name_length, end_key_name, end_key_name_length)
end

"""
C function:
```
FDBFuture* fdb_transaction_watch(
    FDBTransaction* transaction,
    uint8_t const* key_name,
    int key_name_length
)
```

A watch’s behavior is relative to the transaction that created it. A watch
will report a change in relation to the key’s value as readable by that
transaction. The initial value used for comparison is either that of the
transaction’s read version or the value as modified by the transaction
itself prior to the creation of the watch. If the value changes and then
changes back to its initial value, the watch might not report the change.

Until the transaction that created it has been committed, a watch will not
report changes made by other transactions. In contrast, a watch will
immediately report changes made by the transaction itself. Watches cannot be
created if the transaction has set the READ_YOUR_WRITES_DISABLE transaction
option, and an attempt to do so will return an watches_disabled error.

If the transaction used to create a watch encounters an error during commit,
then the watch will be set with that error. A transaction whose commit result is
unknown will set all of its watches with the commit_unknown_result error. If an
uncommitted transaction is reset or destroyed, then any watches it created will
be set with the transaction_cancelled error.

Returns an FDBFuture representing an empty value that will be set once the watch
has detected a change to the value at the specified key. You must first wait for
the FDBFuture to be ready, check for errors, and then destroy the FDBFuture with
fdb_future_destroy().

By default, each database connection can have no more than 10,000 watches that
have not yet reported a change. When this number is exceeded, an attempt to
create a watch will return a too_many_watches error. This limit can be changed
using the MAX_WATCHES database option. Because a watch outlives the transaction
that creates it, any watch that is no longer needed should be cancelled by
calling fdb_future_cancel() on its returned future.

Parameters:
- key_name: A pointer to the name of the key to watch. The value does not need
    to be NULL-terminated.
- key_name_length: The length of the parameter specified by key_name.
"""
function fdb_transaction_watch(tr, key_name, key_name_length::Cint)
    ccall((:fdb_transaction_watch, fdb_c), fdb_future_ptr_t, (fdb_transaction_ptr_t, Ptr{UInt8}, Cint), tr, key_name, key_name_length)
end

"""
C function:
`FDBFuture* fdb_transaction_commit(FDBTransaction* transaction)`

Attempts to commit the sets and clears previously applied to the database
snapshot represented by transaction to the actual database. The commit may or
may not succeed – in particular, if a conflicting transaction previously
committed, then the commit must fail in order to preserve transactional
isolation. If the commit does succeed, the transaction is durably committed to
the database and all subsequently started transactions will observe its effects.

It is not necessary to commit a read-only transaction – you can simply call
fdb_transaction_destroy().

Returns an FDBFuture representing an empty value. You must first wait for the
FDBFuture to be ready, check for errors, and then destroy the FDBFuture with
fdb_future_destroy().

Callers will usually want to retry a transaction if the commit or a prior
fdb_transaction_get_*() returns a retryable error (see
fdb_transaction_on_error()).

As with other client/server databases, in some failure scenarios a client may be
unable to determine whether a transaction succeeded. In these cases,
fdb_transaction_commit() will return a commit_unknown_result error. The
fdb_transaction_on_error() function treats this error as retryable, so retry
loops that don’t check for commit_unknown_result could execute the transaction
twice. In these cases, you must consider the idempotence of the transaction. For
more information, see Transactions with unknown results.

Normally, commit will wait for outstanding reads to return. However, if those
reads were snapshot reads or the transaction option for disabling
“read-your-writes” has been invoked, any outstanding reads will immediately
return errors.
"""
function fdb_transaction_commit(tr)
    ccall((:fdb_transaction_commit, fdb_c), fdb_future_ptr_t, (fdb_transaction_ptr_t,), tr)
end

"""
C function:
```
fdb_error_t fdb_transaction_get_committed_version(
    FDBTransaction* transaction,
    int64_t* out_version
)
```

Retrieves the database version number at which a given transaction was
committed. fdb_transaction_commit() must have been called on transaction and the
resulting future must be ready and not an error before this function is called,
or the behavior is undefined. Read-only transactions do not modify the database
when committed and will have a committed version of -1. Keep in mind that a
transaction which reads keys and then sets them to their current values may be
optimized to a read-only transaction.

Note that database versions are not necessarily unique to a given transaction
and so cannot be used to determine in what order two transactions completed. The
only use for this function is to manually enforce causal consistency when
calling fdb_transaction_set_read_version() on another subsequent transaction.

Most applications will not call this function.
"""
function fdb_transaction_get_committed_version(tr, out_version)
    ccall((:fdb_transaction_get_committed_version, fdb_c), fdb_error_t, (fdb_transaction_ptr_t, Ptr{Int64}), tr, out_version)
end

"""
C function:
`FDBFuture* fdb_transaction_get_versionstamp(FDBTransaction* transaction)`

Returns an FDBFuture which will be set to the versionstamp which was used by any
versionstamp operations in this transaction. You must first wait for the
FDBFuture to be ready, check for errors, call fdb_future_get_key() to extract
the key, and then destroy the FDBFuture with fdb_future_destroy().

The future will be ready only after the successful completion of a call to
fdb_transaction_commit() on this Transaction. Read-only transactions do not
modify the database when committed and will result in the future completing with
an error. Keep in mind that a transaction which reads keys and then sets them to
their current values may be optimized to a read-only transaction.

Most applications will not call this function.
"""
function fdb_transaction_get_versionstamp(tr)
    ccall((:fdb_transaction_get_versionstamp, fdb_c), fdb_future_ptr_t, (fdb_transaction_ptr_t,), tr)
end

"""
C function:
```
FDBFuture* fdb_transaction_on_error(
    FDBTransaction* transaction,
    fdb_error_t error
)
```

Implements the recommended retry and backoff behavior for a transaction. This
function knows which of the error codes generated by other fdb_transaction_*()
functions represent temporary error conditions and which represent application
errors that should be handled by the application. It also implements an
exponential backoff strategy to avoid swamping the database cluster with
excessive retries when there is a high level of conflict between transactions.

On receiving any type of error from an fdb_transaction_*() function, the
application should:
- Call fdb_transaction_on_error() with the returned fdb_error_t code.
- Wait for the resulting future to be ready.
- If the resulting future is itself an error, destroy the future and
    FDBTransaction and report the error in an appropriate way.
- If the resulting future is not an error, destroy the future and restart the
    application code that performs the transaction. The transaction itself will
    have already been reset to its initial state, but should not be destroyed
    and re-created because state used by fdb_transaction_on_error() to implement
    its backoff strategy and state related to timeouts and retry limits is
    stored there.

Returns an FDBFuture representing an empty value. You must first wait for the
FDBFuture to be ready, check for errors, and then destroy the FDBFuture with
fdb_future_destroy().
"""
function fdb_transaction_on_error(tr, error::fdb_error_t)
    ccall((:fdb_transaction_on_error, fdb_c), fdb_future_ptr_t, (fdb_transaction_ptr_t, fdb_error_t), tr, error)
end

"""
C function:
`void fdb_transaction_reset(FDBTransaction* transaction)`

Reset transaction to its initial state. This is similar to calling
fdb_transaction_destroy() followed by fdb_database_create_transaction(). It is
not necessary to call fdb_transaction_reset() when handling an error with
fdb_transaction_on_error() since the transaction has already been reset.
"""
function fdb_transaction_reset(tr)
    ccall((:fdb_transaction_reset, fdb_c), Nothing, (fdb_transaction_ptr_t,), tr)
end

"""
C function:
```
fdb_error_t fdb_transaction_add_conflict_range(
    FDBTransaction* transaction,
    uint8_t const* begin_key_name,
    int begin_key_name_length,
    uint8_t const* end_key_name,
    int end_key_name_length,
    FDBConflictRangeType type
)
```

Adds a conflict range to a transaction without performing the associated read or
write.

Note: Most applications will use the serializable isolation that transactions
provide by default and will not need to manipulate conflict ranges.

Parameters:
- begin_key_name: A pointer to the name of the key specifying the beginning of
    the conflict range. The value does not need to be NULL-terminated.
- begin_key_name_length: The length of the parameter specified by begin_key_name
- end_key_name: A pointer to the name of the key specifying the end of the
    conflict range. The value does not need to be NULL-terminated.
- end_key_name_length: The length of the parameter specified by
    end_key_name_length.
- type: One of the FDBConflictRangeType values indicating what type of conflict
    range is being set.
"""
function fdb_transaction_add_conflict_range(tr, begin_key_name, begin_key_name_length::Cint, end_key_name, end_key_name_length::Cint, _type::fdb_conflict_range_type_t)
    ccall((:fdb_transaction_add_conflict_range, fdb_c), fdb_error_t, (fdb_transaction_ptr_t, Ptr{UInt8}, Cint, Ptr{UInt8}, Cint, fdb_conflict_range_type_t), tr, begin_key_name, begin_key_name_length, end_key_name, end_key_name_length, _type)
end

"""
C function:
```
FDBFuture* fdb_transaction_get(
    FDBTransaction* transaction,
    uint8_t const* key_name,
    int key_name_length,
    fdb_bool_t snapshot
)
```

Reads a value from the database snapshot represented by transaction.

Returns an FDBFuture which will be set to the value of key_name in the database.
You must first wait for the FDBFuture to be ready, check for errors, call
fdb_future_get_value() to extract the value, and then destroy the FDBFuture with
fdb_future_destroy().

See fdb_future_get_value() to see exactly how results are unpacked. If key_name
is not present in the database, the result is not an error, but a zero for
*out_present returned from that function.

Parameters:
- key_name: A pointer to the name of the key to be looked up in the database.
    The value does not need to be NULL-terminated.
- key_name_length: The length of the parameter specified by key_name.
- snapshot: Non-zero if this is a snapshot read.
"""
function fdb_transaction_get(tr, key_name, key_name_length::Cint)
    ccall((:fdb_transaction_get, fdb_c), fdb_future_ptr_t, (fdb_transaction_ptr_t, Ptr{UInt8}, Cint), tr, key_name, key_name_length)
end

"""
C function:
```
FDBFuture* fdb_transaction_get_key(
    FDBTransaction* transaction,
    uint8_t const* key_name,
    int key_name_length,
    fdb_bool_t or_equal,
    int offset,
    fdb_bool_t snapshot
)
```

Resolves a key selector against the keys in the database snapshot represented
by transaction.

Returns an FDBFuture which will be set to the key in the database matching the
key selector. You must first wait for the FDBFuture to be ready, check for
errors, call fdb_future_get_key() to extract the key, and then destroy the
FDBFuture with fdb_future_destroy().

Parameters:
- key_name, key_name_length, or_equal, offset: The four components of a key selector.
- snapshot: Non-zero if this is a snapshot read.
"""
function fdb_transaction_get_key(tr, key_name, key_name_length::Cint, or_equal::fdb_bool_t, offset::Cint)
    ccall((:fdb_transaction_get_key, fdb_c), fdb_future_ptr_t, (fdb_transaction_ptr_t, Ptr{UInt8}, Cint, fdb_bool_t, Cint), tr, key_name, key_name_length, or_equal, offset)
end

"""
C function:
```
FDBFuture* fdb_transaction_get_range(
    FDBTransaction* transaction,
    uint8_t const* begin_key_name,
    int begin_key_name_length,
    fdb_bool_t begin_or_equal,
    int begin_offset,
    uint8_t const* end_key_name,
    int end_key_name_length,
    fdb_bool_t end_or_equal,
    int end_offset,
    int limit,
    int target_bytes,
    FDBStreamingMode mode,
    int iteration,
    fdb_bool_t snapshot,
    fdb_bool_t reverse
)
```

Reads all key-value pairs in the database snapshot represented by transaction
(potentially limited by limit, target_bytes, or mode) which have a key
lexicographically greater than or equal to the key resolved by the begin key
selector and lexicographically less than the key resolved by the end key
selector.

Returns an FDBFuture which will be set to an FDBKeyValue array. You must first
wait for the FDBFuture to be ready, check for errors, call
fdb_future_get_keyvalue_array() to extract the key-value array, and then destroy
the FDBFuture with fdb_future_destroy().

Parameters:
- begin_key_name, begin_key_name_length, begin_or_equal, begin_offset: The four
    components of a key selector describing the beginning of the range.
- end_key_name, end_key_name_length, end_or_equal, end_offset: The four
    components of a key selector describing the end of the range.
- limit: If non-zero, indicates the maximum number of key-value pairs to return.
    If this limit was reached before the end of the specified range, then the
    *more return of fdb_future_get_keyvalue_array() will be set to a non-zero
    value.
- target_bytes: If non-zero, indicates a (soft) cap on the combined number of
    bytes of keys and values to return. If this limit was reached before the end
    of the specified range, then the *more return of
    fdb_future_get_keyvalue_array() will be set to a non-zero value.
- mode: One of the FDBStreamingMode values indicating how the caller would like
    the data in the range returned.
- iteration: If mode is FDB_STREAMING_MODE_ITERATOR, this parameter should start
    at 1 and be incremented by 1 for each successive call while reading this
    range. In all other cases it is ignored.
- snapshot: Non-zero if this is a snapshot read.
- reverse: If non-zero, key-value pairs will be returned in reverse
    lexicographical order beginning at the end of the range.
"""
function fdb_transaction_get_range(tr,
        begin_key_name, begin_key_name_length::Cint, begin_or_equal::fdb_bool_t, begin_offset::Cint,
        end_key_name, end_key_name_length::Cint, end_or_equal::fdb_bool_t, end_offset::Cint,
        limit::Cint=Cint(0), target_bytes::Cint=Cint(0), streaming_mode::Cint=FDBStreamingMode.WANT_ALL, iteration::Cint=Cint(0), snapshot::Cint=Cint(0), reverse::fdb_bool_t=fdb_bool_t(0))
    ccall((:fdb_transaction_get_range, fdb_c), fdb_future_ptr_t, 
        (fdb_transaction_ptr_t,
        Ptr{UInt8}, Cint, fdb_bool_t, Cint,
        Ptr{UInt8}, Cint, fdb_bool_t, Cint,
        Cint, Cint, Cint, Cint, Cint, fdb_bool_t),
        tr,
        begin_key_name, begin_key_name_length, begin_or_equal, begin_offset,
        end_key_name, end_key_name_length, end_or_equal, end_offset,
        limit, target_bytes, streaming_mode, iteration, snapshot, reverse)
end
#=
API signature has changed
function fdb_transaction_get_range(tr, begin_key_name, begin_key_name_length::Cint, end_key_name, end_key_name_length::Cint, limit::Cint)
    ccall((:fdb_transaction_get_range, fdb_c), fdb_future_ptr_t, (fdb_transaction_ptr_t, Ptr{UInt8}, Cint, Ptr{UInt8}, Cint, Cint), tr, begin_key_name, begin_key_name_length, end_key_name, end_key_name_length, limit)
end
=#

#=
API has been removed
function fdb_transaction_get_range_selector(tr, begin_key_name, begin_key_name_length::Cint, begin_or_equal::fdb_bool_t, begin_offset::Cint, end_key_name, end_key_name_length::Cint, end_or_equal::fdb_bool_t, end_offset::Cint, limit::Cint)
    ccall((:fdb_transaction_get_range_selector, fdb_c), fdb_future_ptr_t, (fdb_transaction_ptr_t, Ptr{UInt8}, Cint, fdb_bool_t, Cint, Ptr{UInt8}, Cint, fdb_bool_t, Cint, Cint), tr, begin_key_name, begin_key_name_length, begin_or_equal, begin_offset, end_key_name, end_key_name_length, end_or_equal, end_offset, limit)
end
=#

#------------------------------------------------------------------------------
# MISCELLANEOUS
#------------------------------------------------------------------------------

"""
C function:
`const char* fdb_get_error(fdb_error_t code)`

Returns a (somewhat) human-readable English message from an error code. The
return value is a statically allocated null-terminated string that must not be
freed by the caller.
"""
function fdb_get_error(code::fdb_error_t)
    ccall((:fdb_get_error, fdb_c), Cstring, (fdb_error_t,), code)
end

"""
C function:
`fdb_bool_t fdb_error_predicate(int predicate_test, fdb_error_t code)`

Evaluates a predicate against an error code. The predicate to run should be one
of the codes listed by the FDBErrorPredicate enum defined within
fdb_c_options.g.h. Sample predicates include FDB_ERROR_PREDICATE_RETRYABLE,
which can be used to determine whether the error with the given code is a
retryable error or not.
"""
function fdb_error_predicate(predicate_test::fdb_error_predicate_t, code::fdb_error_t)
    ccall((:fdb_error_predicate, fdb_c), fdb_bool_t, (fdb_error_predicate_t, fdb_error_t), predicate_test, code)
end
