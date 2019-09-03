module TestReaderWriter

using TSML
using TSMLextra
using Test

function test_csv()
    gcdims = (8761,2)
    ssum = 97564.0
    resdf=DataFrame()
    datapath=joinpath(dirname(pathof(TSMLextra)),"../data")
    outputfname = joinpath(tempdir(),"testdateval.csv")
    basefilename = "testdateval"
    fname = joinpath(datapath,basefilename*".csv")
    lcsv=DataReader(Dict(:filename=>fname))
    fit!(lcsv)
    dateval=transform!(lcsv)
    @test sum(size(dateval) .== gcdims ) == 2
    @test sum(dateval.Value) |> round == ssum
    csvname = replace(outputfname,"test"=>"out")
    wcsv = DataWriter(Dict(:filename=>csvname))
    fit!(wcsv)
    transform!(wcsv,dateval)
    pcsv = DataReader(Dict(:filename=>csvname))
    fit!(pcsv)
    resdf=transform!(pcsv)
    @test sum(size(resdf) .== gcdims) == 2
    @test sum(resdf.Value) |> round == ssum
    rm(csvname,force=true)
end
@testset "Data Readers/Writers: csv" begin
    test_csv()
end

function test_hdf5()
    gcdims = (8761,2)
    ssum = 97564.0
    resdf=DataFrame()
    datapath=joinpath(dirname(pathof(TSMLextra)),"../data")
    outputfname = joinpath(tempdir(),"testdateval.csv")
    basefilename = "testdateval"
    fname = joinpath(datapath,basefilename*".csv")
    lcsv=DataReader(Dict(:filename=>fname))
    fit!(lcsv)
    dateval=transform!(lcsv)
    # check hdf5
    hdf5name = replace(outputfname,"csv"=>"h5")
    lhdf5 = DataWriter(Dict(:filename=>hdf5name))
    fit!(lhdf5)
    transform!(lhdf5,dateval)
    whdf5 = DataReader(Dict(:filename=>hdf5name))
    fit!(whdf5)
    resdf = transform!(whdf5)
    @test sum(size(resdf) .== gcdims) == 2
    @test sum(resdf.Value) |> round == ssum
    rm(hdf5name,force=true)
end
@testset "Data Readers/Writers: hdf5" begin
    test_hdf5()
end

function test_feather()
    gcdims = (8761,2)
    ssum = 97564.0
    resdf=DataFrame()
    datapath=joinpath(dirname(pathof(TSMLextra)),"../data")
    outputfname = joinpath(tempdir(),"testdateval.csv")
    basefilename = "testdateval"
    fname = joinpath(datapath,basefilename*".csv")
    lcsv=DataReader(Dict(:filename=>fname))
    fit!(lcsv)
    dateval=transform!(lcsv)
    # check feather
    feathername = replace(outputfname,"csv"=>"feather")
    lfeather = DataWriter(Dict(:filename=>feathername))
    fit!(lfeather)
    transform!(lfeather,dateval)
    wfeather = DataReader(Dict(:filename=>feathername))
    fit!(wfeather)
    resdf = transform!(wfeather)
    @test sum(size(resdf) .== gcdims) == 2
    @test sum(resdf.Value) |> round == ssum
    rm(feathername,force=true)
end
@testset "Data Readers/Writers: feather" begin
    test_feather()
end

function test_jld()
    gcdims = (8761,2)
    ssum = 97564.0
    resdf=DataFrame()
    datapath=joinpath(dirname(pathof(TSMLextra)),"../data")
    outputfname = joinpath(tempdir(),"testdateval.csv")
    basefilename = "testdateval"
    fname = joinpath(datapath,basefilename*".csv")
    lcsv=DataReader(Dict(:filename=>fname))
    fit!(lcsv)
    dateval=transform!(lcsv)
    # check jld
    jldname = replace(outputfname,"csv"=>"jld")
    ljld = DataWriter(Dict(:filename=>jldname))
    fit!(ljld)
    transform!(ljld,dateval)
    wjld = DataReader(Dict(:filename=>jldname))
    fit!(wjld)
    resdf = transform!(wjld)
    @test sum(size(resdf) .== gcdims) == 2
    @test sum(resdf.Value) |> round == ssum
    rm(jldname,force=true)
end
@testset "Data Readers/Writers: jld" begin
    test_jld()
end


end
