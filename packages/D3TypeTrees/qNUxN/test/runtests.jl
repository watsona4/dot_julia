using D3TypeTrees
using Test


@test TypeTree(Number).children == Array{Int64,1}[[2, 26], [3, 18, 23, 25], [4, 5, 11], [], [6, 7, 8, 9, 10], [], [], [], [], [], [12, 13, 14, 15, 16, 17], [], [], [], [], [], [], [19, 20, 21, 22], [], [], [], [], [24], [], [], []]
@test TypeTree(Number).text == ["Number", "Real", "Integer", "Bool", "Unsigned", "UInt16", "UInt128", "UInt8", "UInt32", "UInt64", "Signed", "Int32", "Int128", "Int8", "BigInt", "Int64", "Int16", "AbstractFloat", "Float16", "Float64", "Float32", "BigFloat", "AbstractIrrational", "Irrational", "Rational", "Complex"]
@test TypeTree(Number).tooltip == ["Abstract", "Abstract", "Abstract", "", "Abstract", "", "", "", "", "", "Abstract", "", "", "", "alloc\nsize\nd", "", "", "Abstract", "", "", "", "prec\nsign\nexp\nd\n_d", "Abstract", "", "num\nden", "re\nim"]
