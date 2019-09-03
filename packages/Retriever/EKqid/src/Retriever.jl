module Retriever

using Pkg
using PyCall

export check_for_updates, dataset_names, download
export install_csv, install_mysql, install_postgres
export install_sqlite, install_msaccess, install_json
export install_xml, reset_retriever

@pyimport retriever as rt

"""
```julia
    check_for_updates()
```

Check Retriever scripts for updates.
"""
function check_for_updates()
    rt.check_for_updates()
end

"""
```julia
    reload_scripts()
```

Retriever reload scripts.
"""
function reload_scripts()
    rt.reload_scripts()
end

"""
```julia
    reset_retriever(scope::String="all", ask_permission::Bool=true)
```

Retriever reset scripts or data or all.
"""
function reset_retriever(scope::String="all", ask_permission::Bool=true)
    rt.reset_retriever(scope, ask_permission)
end

"""
```julia
    dataset_names()
```

Return list of all available dataset names.
"""
function dataset_names()
    rt.dataset_names()
end

"""
```julia
    download(dataset; path::String="./", quite::Bool=false,
                subdir::String="", debug::Bool=false, use_cache::Bool=false)
```

Download scripts for retriever.
"""
function download(dataset; path::String="./", quite::Bool=false,
                subdir::String="", debug::Bool=false, use_cache::Bool=false)
    rt.download(dataset, path, quite, subdir, debug, use_cache)
end

"""
```julia

    install_csv(dataset; table_name::String="", compile::Bool=false,
        data_dir=pwd(), debug::Bool=false, use_cache::Bool=true)
```

Install Retriever scripts in csv format.
"""
function install_csv(dataset; table_name::String="{db}_{table}",
        data_dir=pwd(), debug::Bool=false, use_cache::Bool=true)
    rt.install_csv(dataset, table_name, data_dir, debug, use_cache)
end

"""
```julia
    install_mysql(dataset; user::String="root",
                password::String="", host::String="localhost",
                port::Int=3306, database_name::String="", table_name::String="",
                compile::Bool=false, debug::Bool=false, quite::Bool=false,
                use_cache::Bool=true)
```

Install Retriever scripts in mysql database.
"""
function install_mysql(dataset; user::String="root",
                password::String="", host::String="localhost",
                port::Int=3306, database_name::String="{db}", table_name::String="{db}.{table}",
                debug::Bool=false, use_cache::Bool=true)
    rt.install_mysql(dataset, user, password, host, port, database_name,
                     table_name, debug, use_cache)
end

"""
```julia
    install_postgres(dataset; user::String="postgres",
                password::String="", host::String="localhost",
                port::Int=5432, database::String="postgres",
                database_name::String="", table_name::String="", bbox::Any=[],
                debug::Bool=false, use_cache::Bool=true)
```

Install Retriever scripts in database.
"""
function install_postgres(dataset; user::String="postgres",
                password::String="", host::String="localhost",
                port::Int=5432, database::String="postgres",
                database_name::String="{db}", table_name::String="{db}.{table}", bbox::Any=[],
                debug::Bool=false, use_cache::Bool=true)

    rt.install_postgres(dataset, user, password, host, port, database,
                        database_name, table_name, bbox, debug, use_cache)
end

"""
```julia
    install_sqlite(dataset; file::String="", table_name::String="",
                data_dir=pwd(), debug::Bool=false,
                use_cache::Bool=true)
```

Install Retriever scripts in database.
"""
function install_sqlite(dataset; file::String="", table_name::String="{db}.{table}",
                data_dir=pwd(), debug::Bool=false, use_cache::Bool=true)
    return rt.install_sqlite(dataset, file, table_name, data_dir, debug, use_cache)
end

"""
```julia
    install_msaccess(dataset; file::String="", table_name::String="",
                data_dir=pwd(), debug::Bool=false, use_cache::Bool=true)
```

Install Retriever scripts in msacces.
"""
function install_msaccess(dataset; file::String="", table_name::String="",
                data_dir=pwd(), debug::Bool=false, use_cache::Bool=true)
    rt.install_msaccess(dataset, file, table_name, data_dir, debug, quite,
                        use_cache)
end

"""
```julia
    install_json(dataset; table_name::String="", data_dir=pwd(),
    debug::Bool=false, use_cache::Bool=true)
```

Install Retriever scripts in json format.
"""
function install_json(dataset; table_name::String="{db}_{table}.json",
                data_dir=pwd(), debug::Bool=false, use_cache::Bool=true)
    rt.install_json(dataset, table_name, data_dir, debug, use_cache)

end

"""
```julia
    install_xml(dataset; table_name::String="", compile::Bool=false, data_dir=pwd(), 
            debug::Bool=false, use_cache::Bool=true)
```

Install Retriever scripts in xml format.
"""
function install_xml(dataset; table_name::String="{db}_{table}.xml",
                data_dir=pwd(), debug::Bool=false, use_cache::Bool=true)
    rt.install_xml(dataset, table_name, data_dir, debug, use_cache)

end

"""
```julia
    reset_retriever(; scope::String="all")
```

Remove stored information on scripts, data, and connection
"""
function reset_retriever(; scope::String="all")
    rt.reset_retriever(scope)
end

end # module
