module CApi
    using Libdl

    const fdb_c = "libfdb_c"
    const libfdb = Ref{Ptr{Nothing}}(C_NULL)
    
    function __init__()
        global libfdb
        libfdb[] = Libdl.dlopen_e(fdb_c)

        (libfdb[] == C_NULL) && error("Can not open libfdb_c shared library. Please make sure you have Foundation DB client libraries installed.")
    end

    include("common.jl")
    include("ccalls.jl")

    export FDB_API_VERSION
    export FDBNetworkOption, FDBClusterOption, FDBDatabaseOption, FDBTransactionOption, FDBStreamingMode, FDBMutationType, FDBConflictRangeType, FDBErrorPredicate
    export fdb_select_api_version_impl, fdb_select_api_version, fdb_get_max_api_version, fdb_get_client_version, fdb_network_set_option, fdb_setup_network,
            fdb_run_network, fdb_stop_network, fdb_add_network_thread_completion_hook, fdb_future_cancel, fdb_future_destroy, fdb_future_block_until_ready,
            fdb_future_is_ready, fdb_future_set_callback, fdb_future_release_memory, fdb_future_get_error, fdb_future_get_keyvalue_array,
            fdb_future_get_version, fdb_future_get_key, fdb_future_get_cluster, fdb_future_get_database, fdb_future_get_value, fdb_future_get_string_array,
            fdb_create_cluster, fdb_cluster_destroy, fdb_cluster_set_option, fdb_cluster_create_database, fdb_database_destroy, fdb_database_set_option,
            fdb_database_create_transaction, fdb_transaction_destroy, fdb_transaction_set_option, fdb_transaction_cancel, fdb_transaction_set_read_version,
            fdb_transaction_get_read_version, fdb_transaction_get_addresses_for_key, fdb_transaction_set, fdb_transaction_atomic_op, fdb_transaction_clear,
            fdb_transaction_clear_range, fdb_transaction_watch, fdb_transaction_commit, fdb_transaction_get_committed_version, fdb_transaction_get_versionstamp,
            fdb_transaction_on_error, fdb_transaction_reset, fdb_transaction_add_conflict_range, fdb_transaction_get, fdb_transaction_get_key,
            fdb_transaction_get_range, fdb_get_error, fdb_error_predicate
    export fdb_run_network_in_thread, fdb_future_block_until_ready_in_thread
    export fdb_error_t, fdb_bool_t, fdb_transaction_ptr_t, fdb_future_ptr_t, fdb_cluster_ptr_t, fdb_database_ptr_t, fdb_network_option_t, fdb_cluster_option_t,
            fdb_database_option_t, fdb_transaction_option_t, fdb_streaming_mode_t, fdb_mutation_type_t, fdb_conflict_range_type_t, fdb_error_predicate_t,
            fdb_kv_t

    # APIs removed
    #export fdb_transaction_get_range_selector, fdb_future_is_error
end
