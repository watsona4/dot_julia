# By Reuben Hill 2019, Gowerlabs Ltd, reuben@gowerlabs.co.uk
#
# Copyright (c) Gowerlabs Ltd.

module TestUtil

using Test
using LibFTD2XX.Util

@testset "util" begin
  @test "hello" == ntuple2string(Cchar.(('h','e','l','l','o')))
  @test "hello" == ntuple2string(Cchar.(('h','e','l','l','o','\0','x')))

  @test v"0.0.0" == versionnumber(0)
  @test v"99.99.99" == versionnumber(0x00999999)
  @test v"2.12.28" == versionnumber(0x00021228)
  @test_throws DomainError versionnumber(0x00999999 + 1)
  @test_throws DomainError versionnumber(0x000000AA)
  @test_throws DomainError versionnumber(0x0000AA00)
  @test_throws DomainError versionnumber(0x00AA0000)
end

end