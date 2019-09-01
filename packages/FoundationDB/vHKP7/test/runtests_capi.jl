using FoundationDB
using FoundationDB.CApi
using Test

const ADDRESS = "127.0.0.1:4500"

@testset "basic" begin
    @test fdb_get_max_api_version() >= FDB_API_VERSION
    @test "API version not valid" == unsafe_string(fdb_get_error(fdb_select_api_version(1024)))
    @test 0 == fdb_select_api_version(FDB_API_VERSION)
    @test "API version may be set only once" == unsafe_string(fdb_get_error(fdb_select_api_version(1024)))
end

@testset "start network" begin
    @test 0 == fdb_network_set_option(FDBNetworkOption.LOCAL_ADDRESS, ADDRESS, Cint(length(ADDRESS)))
    @test 0 == fdb_setup_network(ADDRESS)
    global network_task
    network_task = @async fdb_run_network_in_thread()
end

@testset "stop network" begin
    global network_task
    @test 0 == fdb_stop_network()
    sleep(5)
    @test istaskdone(network_task)
end
