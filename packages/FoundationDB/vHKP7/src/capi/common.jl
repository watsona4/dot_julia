struct enum_fdb_network_option
    LOCAL_ADDRESS::Cint
    CLUSTER_FILE::Cint
    TRACE_ENABLE::Cint
    TRACE_ROLL_SIZE::Cint
    TRACE_MAX_LOGS_SIZE::Cint
    TRACE_LOG_GROUP::Cint
    KNOB::Cint
    TLS_PLUGIN::Cint
    TLS_CERT_BYTES::Cint
    TLS_CERT_PATH::Cint
    TLS_KEY_BYTES::Cint
    TLS_KEY_PATH::Cint
    TLS_VERIFY_PEERS::Cint
    BUGGIFY_ENABLE::Cint
    BUGGIFY_DISABLE::Cint
    BUGGIFY_SECTION_ACTIVATED_PROBABILITY::Cint
    BUGGIFY_SECTION_FIRED_PROBABILITY::Cint
    DISABLE_MULTI_VERSION_CLIENT_API::Cint
    CALLBACKS_ON_EXTERNAL_THREADS::Cint
    EXTERNAL_CLIENT_LIBRARY::Cint
    EXTERNAL_CLIENT_DIRECTORY::Cint
    DISABLE_LOCAL_CLIENT::Cint
    DISABLE_CLIENT_STATISTICS_LOGGING::Cint
    ENABLE_SLOW_TASK_PROFILING::Cint
end

struct enum_fdb_cluster_option
    DUMMY_DO_NOT_USE::Cint
end

struct enum_fdb_database_option
    LOCATION_CACHE_SIZE::Cint
    MAX_WATCHES::Cint
    MACHINE_ID::Cint
    DATACENTER_ID::Cint
end

struct enum_fdb_transaction_option
    CAUSAL_WRITE_RISKY::Cint
    CAUSAL_READ_RISKY::Cint
    CAUSAL_READ_DISABLE::Cint
    NEXT_WRITE_NO_WRITE_CONFLICT_RANGE::Cint
    COMMIT_ON_FIRST_PROXY::Cint
    CHECK_WRITES_ENABLE::Cint
    READ_YOUR_WRITES_DISABLE::Cint
    READ_AHEAD_DISABLE::Cint
    DURABILITY_DATACENTER::Cint
    DURABILITY_RISKY::Cint
    DURABILITY_DEV_NULL_IS_WEB_SCALE::Cint
    PRIORITY_SYSTEM_IMMEDIATE::Cint
    PRIORITY_BATCH::Cint
    INITIALIZE_NEW_DATABASE::Cint
    ACCESS_SYSTEM_KEYS::Cint
    READ_SYSTEM_KEYS::Cint
    DEBUG_DUMP::Cint
    DEBUG_RETRY_LOGGING::Cint
    TRANSACTION_LOGGING_ENABLE::Cint
    TIMEOUT::Cint
    RETRY_LIMIT::Cint
    MAX_RETRY_DELAY::Cint
    SNAPSHOT_RYW_ENABLE::Cint
    SNAPSHOT_RYW_DISABLE::Cint
    LOCK_AWARE::Cint
    USED_DURING_COMMIT_PROTECTION_DISABLE::Cint
    READ_LOCK_AWARE::Cint
end

struct enum_fdb_streaming_mode
    WANT_ALL::Cint
    ITERATOR::Cint
    EXACT::Cint
    SMALL::Cint
    MEDIUM::Cint
    LARGE::Cint
    SERIAL::Cint
end

struct enum_fdb_mutation_type
    ADD::Cint
    AND::Cint
    BIT_AND::Cint
    OR::Cint
    BIT_OR::Cint
    XOR::Cint
    BIT_XOR::Cint
    MAX::Cint
    MIN::Cint
    SET_VERSIONSTAMPED_KEY::Cint
    SET_VERSIONSTAMPED_VALUE::Cint
    BYTE_MIN::Cint
    BYTE_MAX::Cint
end

struct enum_fdb_conflict_range_type_t
    READ::Cint
    WRITE::Cint
end

struct enum_fdb_error_predicate_t
    RETRYABLE::Cint
    MAYBE_COMMITTED::Cint
    RETRYABLE_NOT_COMMITTED::Cint
end

const FDBNetworkOption = enum_fdb_network_option(
    Cint(10), # FDB_NET_OPTION_LOCAL_ADDRESS 
    Cint(20), # FDB_NET_OPTION_CLUSTER_FILE 
    Cint(30), # FDB_NET_OPTION_TRACE_ENABLE 
    Cint(31), # FDB_NET_OPTION_TRACE_ROLL_SIZE 
    Cint(32), # FDB_NET_OPTION_TRACE_MAX_LOGS_SIZE 
    Cint(33), # FDB_NET_OPTION_TRACE_LOG_GROUP 
    Cint(40), # FDB_NET_OPTION_KNOB 
    Cint(41), # FDB_NET_OPTION_TLS_PLUGIN 
    Cint(42), # FDB_NET_OPTION_TLS_CERT_BYTES 
    Cint(43), # FDB_NET_OPTION_TLS_CERT_PATH 
    Cint(45), # FDB_NET_OPTION_TLS_KEY_BYTES 
    Cint(46), # FDB_NET_OPTION_TLS_KEY_PATH 
    Cint(47), # FDB_NET_OPTION_TLS_VERIFY_PEERS 
    Cint(48), # FDB_NET_OPTION_BUGGIFY_ENABLE 
    Cint(49), # FDB_NET_OPTION_BUGGIFY_DISABLE 
    Cint(50), # FDB_NET_OPTION_BUGGIFY_SECTION_ACTIVATED_PROBABILITY 
    Cint(51), # FDB_NET_OPTION_BUGGIFY_SECTION_FIRED_PROBABILITY 
    Cint(60), # FDB_NET_OPTION_DISABLE_MULTI_VERSION_CLIENT_API 
    Cint(61), # FDB_NET_OPTION_CALLBACKS_ON_EXTERNAL_THREADS 
    Cint(62), # FDB_NET_OPTION_EXTERNAL_CLIENT_LIBRARY 
    Cint(63), # FDB_NET_OPTION_EXTERNAL_CLIENT_DIRECTORY 
    Cint(64), # FDB_NET_OPTION_DISABLE_LOCAL_CLIENT 
    Cint(70), # FDB_NET_OPTION_DISABLE_CLIENT_STATISTICS_LOGGING 
    Cint(71)  # FDB_NET_OPTION_ENABLE_SLOW_TASK_PROFILING
)

const FDBClusterOption = enum_fdb_cluster_option(
    Cint(-1) # FDB_CLUSTER_OPTION_DUMMY_DO_NOT_USE
)

const FDBDatabaseOption = enum_fdb_database_option(
    Cint(10), # FDB_DB_OPTION_LOCATION_CACHE_SIZE
    Cint(20), # FDB_DB_OPTION_MAX_WATCHES
    Cint(21), # FDB_DB_OPTION_MACHINE_ID
    Cint(22)  # FDB_DB_OPTION_DATACENTER_ID
)

const FDBTransactionOption = enum_fdb_transaction_option(
    Cint(10),  # FDB_TR_OPTION_CAUSAL_WRITE_RISKY
    Cint(20),  # FDB_TR_OPTION_CAUSAL_READ_RISKY
    Cint(21),  # FDB_TR_OPTION_CAUSAL_READ_DISABLE
    Cint(30),  # FDB_TR_OPTION_NEXT_WRITE_NO_WRITE_CONFLICT_RANGE
    Cint(40),  # FDB_TR_OPTION_COMMIT_ON_FIRST_PROXY
    Cint(50),  # FDB_TR_OPTION_CHECK_WRITES_ENABLE
    Cint(51),  # FDB_TR_OPTION_READ_YOUR_WRITES_DISABLE
    Cint(52),  # FDB_TR_OPTION_READ_AHEAD_DISABLE
    Cint(110), # FDB_TR_OPTION_DURABILITY_DATACENTER
    Cint(120), # FDB_TR_OPTION_DURABILITY_RISKY
    Cint(130), # FDB_TR_OPTION_DURABILITY_DEV_NULL_IS_WEB_SCALE
    Cint(200), # FDB_TR_OPTION_PRIORITY_SYSTEM_IMMEDIATE
    Cint(201), # FDB_TR_OPTION_PRIORITY_BATCH
    Cint(300), # FDB_TR_OPTION_INITIALIZE_NEW_DATABASE
    Cint(301), # FDB_TR_OPTION_ACCESS_SYSTEM_KEYS
    Cint(302), # FDB_TR_OPTION_READ_SYSTEM_KEYS
    Cint(400), # FDB_TR_OPTION_DEBUG_DUMP
    Cint(401), # FDB_TR_OPTION_DEBUG_RETRY_LOGGING
    Cint(402), # FDB_TR_OPTION_TRANSACTION_LOGGING_ENABLE
    Cint(500), # FDB_TR_OPTION_TIMEOUT
    Cint(501), # FDB_TR_OPTION_RETRY_LIMIT
    Cint(502), # FDB_TR_OPTION_MAX_RETRY_DELAY
    Cint(600), # FDB_TR_OPTION_SNAPSHOT_RYW_ENABLE
    Cint(601), # FDB_TR_OPTION_SNAPSHOT_RYW_DISABLE
    Cint(700), # FDB_TR_OPTION_LOCK_AWARE
    Cint(701), # FDB_TR_OPTION_USED_DURING_COMMIT_PROTECTION_DISABLE
    Cint(702)  # FDB_TR_OPTION_READ_LOCK_AWARE
)

const FDBStreamingMode = enum_fdb_streaming_mode(
    Cint(-2), # FDB_STREAMING_MODE_WANT_ALL
    Cint(-1), # FDB_STREAMING_MODE_ITERATOR
    Cint(0),  # FDB_STREAMING_MODE_EXACT
    Cint(1),  # FDB_STREAMING_MODE_SMALL
    Cint(2),  # FDB_STREAMING_MODE_MEDIUM
    Cint(3),  # FDB_STREAMING_MODE_LARGE
    Cint(4)   # FDB_STREAMING_MODE_SERIAL
)

const FDBMutationType = enum_fdb_mutation_type(
    Cint(2),  # FDB_MUTATION_TYPE_ADD
    Cint(6),  # FDB_MUTATION_TYPE_AND
    Cint(6),  # FDB_MUTATION_TYPE_BIT_AND
    Cint(7),  # FDB_MUTATION_TYPE_OR
    Cint(7),  # FDB_MUTATION_TYPE_BIT_OR
    Cint(8),  # FDB_MUTATION_TYPE_XOR
    Cint(8),  # FDB_MUTATION_TYPE_BIT_XOR
    Cint(12), # FDB_MUTATION_TYPE_MAX
    Cint(13), # FDB_MUTATION_TYPE_MIN
    Cint(14), # FDB_MUTATION_TYPE_SET_VERSIONSTAMPED_KEY
    Cint(15), # FDB_MUTATION_TYPE_SET_VERSIONSTAMPED_VALUE
    Cint(16), # FDB_MUTATION_TYPE_BYTE_MIN
    Cint(17)  # FDB_MUTATION_TYPE_BYTE_MAX
)

const FDBConflictRangeType = enum_fdb_conflict_range_type_t(
    Cint(0), # FDB_CONFLICT_RANGE_TYPE_READ
    Cint(1)  # FDB_CONFLICT_RANGE_TYPE_WRITE
)

const FDBErrorPredicate = enum_fdb_error_predicate_t(
    Cint(50000), # FDB_ERROR_PREDICATE_RETRYABLE
    Cint(50001), # FDB_ERROR_PREDICATE_MAYBE_COMMITTED
    Cint(50002)  # FDB_ERROR_PREDICATE_RETRYABLE_NOT_COMMITTED
)

const FDB_API_VERSION = Cint(510)
const fdb_error_t = Cint
const fdb_bool_t = Cint
const fdb_transaction_ptr_t = Ptr{Nothing}
const fdb_future_ptr_t = Ptr{Nothing}
const fdb_cluster_ptr_t = Ptr{Nothing}
const fdb_database_ptr_t = Ptr{Nothing}
const fdb_network_option_t = Cint
const fdb_cluster_option_t = Cint
const fdb_database_option_t = Cint
const fdb_transaction_option_t = Cint
const fdb_streaming_mode_t = Cint
const fdb_mutation_type_t = Cint
const fdb_conflict_range_type_t = Cint
const fdb_error_predicate_t = Cint

"""
A pointer to a function which takes FDBFuture* and void* and returns void.
"""
const FDBCallback = Ptr{Nothing}

"""
Represents a single key-value pair in the output of
fdb_future_get_keyvalue_array().

- key: A pointer to a key.
- key_length: The length of the key pointed to by key.
- value: A pointer to a value.
- value_length: The length of the value pointed to by value.
"""
struct fdb_kv_t
    key::Ptr{Nothing}
    key_length::Cint
    value::Ptr{Nothing}
    value_length::Cint
end
