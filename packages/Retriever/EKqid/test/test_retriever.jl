#!/usr/bin/env julia

using PyCall
using SQLite
using MySQL

@pyimport os

Retriever.check_for_updates()


# datasets to test
test_datasets = ["bird-size", "Iris"]

# Service host names
# Use service names on travis as host names else localhost
# Set in Docker compose
pgdb = mysqldb = "localhost"
os_password = ""
if haskey(ENV, "TRAVIS_OR_DOCKER") == true
    pgdb = "pgdb"
    mysqldb = "mysqldb"
    os_password = "Password12!"
end


sqlite_opts = Dict("engine" => "sqlite",
                    "file" => "dbfile",
                    "table_name" => "{db}.{table}")
postgres_opts =  Dict("engine" =>  "postgres",
                        "user" =>  "postgres",
                        "host" =>  pgdb,
                        "password" => os_password,
                        "port" =>  5432,
                        "database" =>  "testdb",
                        "database_name" =>  "testschema2",
                        "table_name" => "{db}.{table}")
csv_opts = Dict("engine" =>  "csv",
                "table_name" => "{db}_{table}.csv")
mysql_opt = Dict("engine" =>  "mysql",
                "user" => "travis",
                "password"=> os_password,
                "host"=> mysqldb,
                "port"=>3306,
                "database_name"=>"testdb",
                "table_name"=>"{db}.{table}")
json_opt = Dict("engine" =>  "json",
                "table_name" => "{db}_{table}.json")
xml_opt = Dict("engine" =>  "xml",
                "table_name" => "{db}_{table}.xml")

function setup()
    # result
end

function teardown()
end

function reset_reload_scripts()
  # Test reset and reload_scripts
  dataset = test_datasets[0]
  Retriever.reset_retriever(dataset)
  Retriever.reload_scripts()
  @test dataset in rdataretriever::datasets() == FALSE
  Retriever.get_updates()
  Retriever.reload_scripts()
  @test dataset in rdataretriever::datasets() == TRUE
end

function empty_files(path, ext)
    for (root, dirs, files) in walkdir(path)
        for file in files
            relative_path = joinpath(root, file)
            if endswith(relative_path, ext)
                println(relative_path)
                @test filesize(relative_path) > 10
            end
        end
    end
end

function install_csv_engine(data_arg)
    try
        mktempdir() do dir_tmp
            cd(dir_tmp) do
                    # Install dataset into Json database
                    Retriever.install_csv(data_arg,
                        table_name = csv_opts["table_name"])
                    empty_files(dir_tmp, ".csv")
            end
        end
      return true
    catch
        return false
    end
end

my_tempdir = tempdir()
@test isdir(my_tempdir) == true

function install_json_engine(data_arg)
    try
        mktempdir() do dir_tmp
            cd(dir_tmp) do
                    # Install dataset into Json database
                    Retriever.install_json(data_arg,
                        table_name = json_opt["table_name"])
                    empty_files(dir_tmp, ".json")
            end
        end
      return true
    catch
        return false
    end
end

function install_xml_engine(data_arg)
    try
        mktempdir() do dir_tmp
            cd(dir_tmp) do
                    # Install dataset into Json database
                    Retriever.install_xml(data_arg,
                        table_name = xml_opt["table_name"])
                    empty_files(dir_tmp, ".xml")
            end
        end
      return true
    catch
        return false
    end
end

function install_mysql_engine(data_arg)
    try
      # Drop database
      conn = MySQL.connect(mysql_opt["host"], mysql_opt["user"],
          mysql_opt["password"], db = mysql_opt["database_name"])
      db = mysql_opt["database_name"]
      command = "DROP TABLE IF EXISTS $db"
      MySQL.Stmt(conn, command)
      # dframe = mysql_execute(con, command)
      MySQL.disconnect(conn)
      # Install dataset into mysql database
      Retriever.install_mysql(data_arg,
          user = mysql_opt["user"],
          password = mysql_opt["password"],
          host = mysql_opt["host"],
          port = mysql_opt["port"],
          database_name = mysql_opt["database_name"],
          table_name = mysql_opt["table_name"])
      return true
    catch
        return false
    end
end


function install_postgres_engine(data_arg::String)
    try
      # Use python to drop table.
      usr = postgres_opts["user"]
      prt = postgres_opts["port"]
      cmd = "psql -U $usr -d testdb -h $pgdb -p $prt -w -c"
      drop_sql = "\"DROP SCHEMA IF EXISTS testschema CASCADE\""
      query_stm = "$cmd $drop_sql"
      os.system(query_stm)

      # Install dataset into mysql database
      Retriever.install_postgres(data_arg,
          user = postgres_opts["user"],
          password = postgres_opts["password"],
          host = postgres_opts["host"],
          port = postgres_opts["port"],
          database_name = postgres_opts["database_name"],
          table_name = postgres_opts["table_name"])
      return true
    catch
        return false
    end
end


function install_sqlite_engine(data_arg)
    try
        mktempdir() do dir_tmp
            cd(dir_tmp) do
                # Install dataset into SQLite database
                Retriever.install_sqlite(data_arg,
                    file = sqlite_opts["file"],
                    table_name = sqlite_opts["table_name"])
                return true
            end
        end
    catch
        return false
    end
end


@testset "Regression" begin
    @test true
    work_dir = pwd()
    for datset_n in test_datasets

        # Data DB test
        @test true == install_mysql_engine(datset_n)

        # Postgres is currently unstable, December 2018
        @test true == install_postgres_engine(datset_n)
        @test true == install_sqlite_engine(datset_n)

        # File engines use a temporary directory for tests
        @test true == install_csv_engine(datset_n)
        @test true == install_json_engine(datset_n)
        @test true == install_xml_engine(datset_n)
    end

end # @testset Regression
