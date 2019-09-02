module Tests

include("../src/Tokenizer.jl")
include("../src/Markovify.jl")
using .Tokenizer, .Markovify, Test

#=

Tests for the module Tokenizer

=#

text = "ABC.DAB.\n ACDA"

@test tokenize(text; on=letters) == [
    ["A", "B", "C", "."],
    ["D", "A", "B", "."],
    ["A", "C", "D", "A"],
]

@test tokenize(text; on=lines) == [
    ["A", "B", "C", ".", "D", "A", "B", "."],
    [" ", "A", "C", "D", "A"]
]

#=

Tests for the module Markovify

=#

tokens = tokenize(text; on=letters)
model = Model(tokens; order=1)

@test model.nodes ==
    Dict(
        ["A"] =>    Dict("B" => 2, "C" => 1, :end => 1),
        ["B"] =>    Dict("C" => 1, "." => 1),
        ["C"] =>    Dict("D" => 1,"." => 1),
        ["D"] =>    Dict("A" => 2),
        [:begin] => Dict("A" => 2,"D" => 1),
        ["."] =>    Dict(:end => 2)
    )

@test walk(model, ["A"])[1] == "A"

@test_throws KeyError walk(model, ["E"])

model2 = Model(tokens; order=2)

@test Markovify.states_with_suffix(model2, ["."]) == [
    ["B", "."],
    ["C", "."]
]

@test Markovify.state_with_prefix(model2, ["B"]) in [
    ["B", "."],
    ["B", "C"]
]

@test Markovify.indexin(collect(-1:12), 10) == 12
end
