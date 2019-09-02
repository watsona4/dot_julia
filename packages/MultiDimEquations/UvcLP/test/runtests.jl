using DataFrames
using Base.Test

include("$(Pkg.dir())/MultiDimEquations/src/MultiDimEquations.jl")

# TEST 1: Testing both defVars()and the @meq macro using a single IndexedTable
df = CSV.read(IOBuffer("""
reg	prod	var	value
us	banana	production	10
us	banana	transfCoef	0.6
us	banana	trValues	2
us	apples	production	7
us	apples	transfCoef	0.7
us	apples	trValues	5
us	juice	production	NA
us	juice	transfCoef	NA
us	juice	trValues	NA
eu	banana	production	5
eu	banana	transfCoef	0.7
eu	banana	trValues	1
eu	apples	production	8
eu	apples	transfCoef	0.8
eu	apples	trValues	4
eu	juice	production	NA
eu	juice	transfCoef	NA
eu	juice	trValues    NA
"""), delim=" ", ignorerepeated=true)
variables =  vcat(unique(DataFrames.dropmissing(df)[:var]),["consumption"])
#defVars(variables,df;dfName="df",varNameCol="var", valueCol="value")
data = defVars(variables, df, tableName="data", varNameCol="var", valueCol="value")
products = ["banana","apples","juice"]
primPr   = products[1:2]
secPr    = [products[3]]
reg      = ["us","eu"]
# equivalent to [production!(sum(trValues_(r,pp) * transfCoef_(r,pp)  for pp in primPr), r, sp) for r in reg, sp in secPr]
@meq production!(r in reg, sp in secPr)   = sum(trValues_(r,pp) * transfCoef_(r,pp)  for pp in primPr)
@meq consumption!(r in reg, pp in primPr) = production_(r,pp) - trValues_(r,pp)
@meq consumption!(r in reg, sp in secPr)  = production_(r, sp)
totalConsumption = sum(consumption_(r,p) for r in reg, p in products)

@test totalConsumption == 26.6

# # TEST 2: Testing both the "old" defVarsDf()and the @meq macro using a single DataFrame as base
# df2 = wsv"""
# reg	prod	var	value
# us	banana	production	10
# us	banana	transfCoef	0.6
# us	banana	trValues	2
# us	apples	production	7
# us	apples	transfCoef	0.7
# us	apples	trValues	5
# us	juice	production	NA
# us	juice	transfCoef	NA
# us	juice	trValues	NA
# eu	banana	production	5
# eu	banana	transfCoef	0.7
# eu	banana	trValues	1
# eu	apples	production	8
# eu	apples	transfCoef	0.8
# eu	apples	trValues	4
# eu	juice	production	NA
# eu	juice	transfCoef	NA
# eu	juice	trValues    NA
# """
# variables =  vcat(unique(dropna(df[:var])),["consumption"])
# defVarsDf(variables,df2;dfName="df2",varNameCol="var", valueCol="value")
# products = ["banana","apples","juice"]
# primPr   = products[1:2]
# secPr    = [products[3]]
# reg      = ["us","eu"]
# # equivalent to [production!(sum(trValues_(r,pp) * transfCoef_(r,pp)  for pp in primPr), r, sp) for r in reg, sp in secPr]
# @meq production!(r in reg, sp in secPr)   = sum(trValues_(r,pp) * transfCoef_(r,pp)  for pp in primPr)
# @meq consumption!(r in reg, pp in primPr) = production_(r,pp) - trValues_(r,pp)
# @meq consumption!(r in reg, sp in secPr)  = production_(r, sp)
# totalConsumption = sum(consumption_(r,p) for r in reg, p in products)
#
# @test totalConsumption == 26.6


# TEST : Testing the @meq macro with individual IndexedTables
a = IndexedTable([["a","a","b","b"],[1,2,1,2]]...,[1,2,3,4])
dim1 = ["a","b"]
dim2 = [1,2]

@meq a[d1 in dim1,2] = a[d1,1]+3
tot = sum(a[d1,d2] for d1 in dim1, d2 in dim2)
@test tot == 14

# Test n: Fake test, this should not pass
# @test 1 == 2
