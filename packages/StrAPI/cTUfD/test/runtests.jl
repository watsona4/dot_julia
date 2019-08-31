# This file is part of StrAPI, License is MIT: LICENSE.md

using ModuleInterfaceTools

@api test StrAPI

@static if V6_COMPAT # for now until v0.7 problems solved
    @test is_ascii     == isascii
    @test is_hex_digit == isxdigit
@static if V6_COMPAT
    @test uppercase_first == ucfirst
    @test is_lowercase == islower
else
    @test uppercase_first == uppercasefirst
    @test is_lowercase == islowercase
end
end
    
@test AbstractChar <: Any
@test Each <: FindOp
@test First <: FindOp
@test Fwd <: Direction
