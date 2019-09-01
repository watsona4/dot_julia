module FoundationDB

using Distributed

import Base: show, open, close, reset, isopen, getkey
export FDBCluster, FDBDatabase, FDBTransaction, FDBError, FDBKeySel, FDBFuture, start_client, stop_client, is_client_running
export FDBNetworkOption, FDBDatabaseOption, FDBTransactionOption, FDBMutationType, FDBStreamingMode, FDBConflictRangeType
export reset, cancel, commit, get_read_version, set_read_version, get_committed_version
export clearkey, clearkeyrange, getval, setval, watchkey, keysel, getkey, getrange, conflict
export atomic, atomic_add, atomic_and, atomic_or, atomic_xor, atomic_max, atomic_min, atomic_setval, atomic_integer, prep_atomic_key!

include("capi/capi.jl")
include("base.jl")

end # module
