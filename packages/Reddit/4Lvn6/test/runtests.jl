using Reddit
using Test

creds = Credentials("id", "secret", "agent", "name", "password")

@testset "Credentials" begin
    @test creds.id == "id"
    @test creds.secret == "secret"
    @test creds.useragent == "agent"
    @test creds.username == "name"
    @test creds.password == "password"
end
