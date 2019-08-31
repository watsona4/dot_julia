using Compat
using Compat.Test: @test, @test_broken, @testset

makepath = joinpath(dirname(@__FILE__), "..", "deps")

if !isfile(joinpath(makepath, "Makefile"))
    start = pwd()
    cd(makepath)
    if Compat.Sys.iswindows()
        run(`cmake -DCMAKE_IGNORE_PATH="C:/Program Files/Git/usr/bin" -G "MinGW Makefiles" .`)
    elseif Compat.Sys.isapple() || Compat.Sys.islinux()
        run(`cmake .`)
    else
        error("This system is not supported by AndersonMoore")
    end
    
    run(`make`)
    cd(start)
end

const AndersonMooreModule = joinpath(dirname(@__FILE__), "..", "src", "AndersonMoore.jl")
include(AndersonMooreModule)

# test_path = joinpath(dirname(@__FILE__), "defineShiftRightTestFuncs.jl")
include(joinpath(dirname(@__FILE__), "defineShiftRightTestFuncs.jl"))
@testset "outer"  begin# an outer so that it does't quit on first fail
@testset "test shiftRight" begin
@test ShiftRightTests.firmvalue()
@test ShiftRightTests.firmvalue3Leads2Lags()
@test ShiftRightTests.example7()
@test ShiftRightTests.oneEquationNoLead()
@test ShiftRightTests.reliablePaperExmpl()
@test ShiftRightTests.athan()
@test ShiftRightTests.habitmod()
end

# test_path = joinpath(dirname(@__FILE__), "defineExactShiftTestFuncs.jl")
include(joinpath(dirname(@__FILE__), "defineExactShiftTestFuncs.jl"))  
@testset "test exactShift" begin
@test ExactShiftTests.firmvalue()
@test ExactShiftTests.firmvalue3Leads2Lags()
@test ExactShiftTests.example7()
@test ExactShiftTests.oneEquationNoLead()
@test ExactShiftTests.reliablePaperExmpl()
@test ExactShiftTests.athan()
@test ExactShiftTests.habitmod()
end

# test_path = joinpath(dirname(@__FILE__), "defineNumericShiftTestFuncs.jl")
include(joinpath(dirname(@__FILE__), "defineNumericShiftTestFuncs.jl"))
@testset "test numericShift" begin
@test NumericShiftTests.firmvalueTrue()
@test NumericShiftTests.firmvalue3Leads2LagsTrue()
@test NumericShiftTests.example7True()
@test NumericShiftTests.oneEquationNoLeadTrue()
@test NumericShiftTests.reliablePaperExmplTrue()
@test NumericShiftTests.athanTrue()
@test NumericShiftTests.habitmodTrue()
    
@test NumericShiftTests.firmvalueFalse()
@test NumericShiftTests.firmvalue3Leads2LagsFalse()
@test NumericShiftTests.example7False()
@test NumericShiftTests.oneEquationNoLeadFalse()
@test NumericShiftTests.reliablePaperExmplFalse()
@test NumericShiftTests.athanFalse()
@test NumericShiftTests.habitmodFalse()
end

# test_path = joinpath(dirname(@__FILE__), "defineBuildATestFuncs.jl")
include(joinpath(dirname(@__FILE__), "defineBuildATestFuncs.jl"))
@testset "test buildA" begin
@test BuildATests.firmvalueFalse()
@test BuildATests.firmvalue3Leads2LagsFalse()
@test BuildATests.example7False()
@test BuildATests.oneEquationNoLeadFalse()
@test BuildATests.reliablePaperExmplFalse()
@test BuildATests.athanFalse()
@test BuildATests.habitmodFalse()
        
@test BuildATests.firmvalueTrue()
@test BuildATests.firmvalue3Leads2LagsTrue()
@test BuildATests.example7True()
@test BuildATests.oneEquationNoLeadTrue()
@test BuildATests.reliablePaperExmplTrue()
@test BuildATests.athanTrue()
@test BuildATests.habitmodTrue()
end

# test_path = joinpath(dirname(@__FILE__), "defineEigenSysTestFuncs.jl")
include(joinpath(dirname(@__FILE__), "defineEigenSysTestFuncs.jl"))
@testset "test eigenSys" begin
@test EigenSysTests.firmvalue()
@test EigenSysTests.firmvalue3Leads2Lags()
@test EigenSysTests.example7()
@test EigenSysTests.oneEquationNoLead()
@test EigenSysTests.reliablePaperExmpl()
@test EigenSysTests.athan()
@test EigenSysTests.habitmod()
end

# test_path = joinpath(dirname(@__FILE__), "defineAugmentQTestFuncs.jl")
include(joinpath(dirname(@__FILE__), "defineAugmentQTestFuncs.jl"))
@testset "test augmentQ" begin
@test AugmentQTests.firmvalue()
@test AugmentQTests.firmvalue3Leads2Lags()
@test AugmentQTests.example7()
@test AugmentQTests.oneEquationNoLead()
@test AugmentQTests.reliablePaperExmpl()
@test AugmentQTests.athan()
@test AugmentQTests.habitmod()
end

# test_path = joinpath(dirname(@__FILE__), "defineReducedFormTestFuncs.jl")
include(joinpath(dirname(@__FILE__), "defineReducedFormTestFuncs.jl"))
@testset "test reducedForm" begin
@test ReducedFormTests.firmvalueFalse()
@test ReducedFormTests.firmvalue3Leads2LagsFalse()
@test ReducedFormTests.example7False()
@test ReducedFormTests.oneEquationNoLeadFalse()
@test ReducedFormTests.reliablePaperExmplFalse()
@test ReducedFormTests.athanFalse()
@test ReducedFormTests.habitmodFalse()
                
@test ReducedFormTests.firmvalueTrue()
@test ReducedFormTests.firmvalue3Leads2LagsTrue()
@test ReducedFormTests.example7True()
@test ReducedFormTests.oneEquationNoLeadTrue()
@test ReducedFormTests.reliablePaperExmplTrue()
@test ReducedFormTests.athanTrue()
@test ReducedFormTests.habitmodTrue()
end
    
# test_path = joinpath(dirname(@__FILE__), "defineAndersonMooreAlgTestFuncs.jl")
include(joinpath(dirname(@__FILE__), "defineAndersonMooreAlgTestFuncs.jl"))
@testset "test AndersonMooreAlg" begin
    
    @test AndersonMooreAlgTests.firmvalueFalse()
    @test AndersonMooreAlgTests.firmvalue3Leads2LagsFalse()
    @test AndersonMooreAlgTests.example7False()
    @test AndersonMooreAlgTests.oneEquationNoLeadFalse()
    @test AndersonMooreAlgTests.reliablePaperExmplFalse()
    @test AndersonMooreAlgTests.athanFalse()
    @test AndersonMooreAlgTests.habitmodFalse()

    @test AndersonMooreAlgTests.firmvalueTrue()
    @test AndersonMooreAlgTests.firmvalue3Leads2LagsTrue()
    @test AndersonMooreAlgTests.example7True()
    @test AndersonMooreAlgTests.oneEquationNoLeadTrue()
    @test AndersonMooreAlgTests.reliablePaperExmplTrue()
    @test AndersonMooreAlgTests.athanTrue()
    @test AndersonMooreAlgTests.habitmodTrue()
    
end

# test_path = joinpath(dirname(@__FILE__), "defineCcallTestFuncs.jl")
include(joinpath(dirname(@__FILE__), "defineCcallTestFuncs.jl"))
@testset "test ccall" begin
    
    @test CcallTests.firmvalueFalse()
    @test CcallTests.firmvalue3Leads2LagsFalse()
    @test CcallTests.example7False()
    @test CcallTests.oneEquationNoLeadFalse()
    @test CcallTests.reliablePaperExmplFalse()
    @test CcallTests.athanFalse()
    @test CcallTests.habitmodFalse()

    @test CcallTests.firmvalueTrue()
    @test CcallTests.firmvalue3Leads2LagsTrue()
    @test CcallTests.example7True()
    @test CcallTests.oneEquationNoLeadTrue()
    @test CcallTests.reliablePaperExmplTrue()
    @test CcallTests.athanTrue()
    @test CcallTests.habitmodTrue()
    
end
    
# test_path = joinpath(dirname(@__FILE__), "defineErrTestFuncs.jl")
include(joinpath(dirname(@__FILE__), "defineErrTestFuncs.jl"))  
@testset "test err" begin
    @test ErrTests.noErrors()
    @test ErrTests.tooManyRoots()
    @test ErrTests.tooFewRoots()
    #@test ErrTests.tooManyExactShifts()
    #@test ErrTests.tooManyNumericShifts()
    @test ErrTests.spurious()
end

# test_path = joinpath(dirname(@__FILE__), "defineGensysTestFuncs.jl")
include(joinpath(dirname(@__FILE__), "defineGensysTestFuncs.jl"))
@testset "test gensysToAMA" begin
    @test GensysTests.example0()
    @test GensysTests.example1()
    @test GensysTests.example2()
    @test GensysTests.example3()
    @test GensysTests.example4()
    @test GensysTests.example5()
    #@test GensysTests.example6()
    @test GensysTests.example7()
end

end #outer


