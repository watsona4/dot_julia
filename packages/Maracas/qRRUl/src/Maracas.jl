module Maracas
include("test.jl")
export @test, @test_throws, @test_broken, @test_skip, @test_warn, @test_nowarn
export @testset
export @describe, @it, @unit, @skip, MARACAS_SETTING
export MaracasTestSet, DescribeTestSet, SpecTestSet, TestTestSet
export set_test_style, set_title_style, set_spec_style, set_error_color, set_warn_color, set_pass_color, set_info_color
const MARACAS_SETTING = Dict(
    :error => Symbol(get(ENV, "MARACAS_ERROR", :red)),
    :warn =>  Symbol(get(ENV, "MARACAS_WARN", :yellow)),
    :pass =>  Symbol(get(ENV, "MARACAS_PASS", :green)),
    :info =>  Symbol(get(ENV, "MARACAS_INFO", :blue)),
    :default => Base.text_colors[:normal],
    :bold => Base.text_colors[Symbol(get(ENV, "MARACAS_BOLD", :bold))],
    :title_length => 80,
    :test =>  "",
    :title =>  "",
    :spec =>  "",
)
MARACAS_SETTING[:test] =  get(ENV, "MARACAS_TEST", string(Base.text_colors[:blue], MARACAS_SETTING[:bold]))
MARACAS_SETTING[:title] =  get(ENV, "MARACAS_TITLE", string(Base.text_colors[:magenta], MARACAS_SETTING[:bold]))
MARACAS_SETTING[:spec] =  get(ENV, "MARACAS_SPEC", string(Base.text_colors[:cyan], MARACAS_SETTING[:bold]))

function set_text_style(key::Symbol, color::Symbol, style::Symbol=:bold)
    MARACAS_SETTING[key] = string(Base.text_colors[style], Base.text_colors[color])
end

const TextColor = Union{Symbol, UInt8}

set_test_style(color::TextColor, bold::Bool=true) = set_text_style(:test, color, bold ? :bold : :normal)
set_title_style(color::TextColor, bold::Bool=true) = set_text_style(:title, color, bold ? :bold : :normal)
set_spec_style(color::TextColor, bold::Bool=true) = set_text_style(:spec, color, bold ? :bold : :normal)
set_error_color(color::TextColor) = (MARACAS_SETTING[:error] = color)
set_warn_color(color::TextColor) = (MARACAS_SETTING[:warn] = color)
set_pass_color(color::TextColor) = (MARACAS_SETTING[:pass] = color)
set_info_color(color::TextColor) = (MARACAS_SETTING[:info] = color)

const MACRO_TYPES = Dict(
    "@describe" => DescribeTestSet,
    "@it" => SpecTestSet,
    "@unit" => TestTestSet,
)

function _check_args(macro_name, desc, tests)
    if !isa(desc, AbstractString) && !(isa(desc, Expr) && desc.head == :string)
        error("Unexpected argument $desc to $macro_name")
    end
    if !isa(tests, Expr) || tests.head != :block
        error("Expected begin/end block as argument to $macro_name")
    end
    return desc, tests
end
function genexpr(macro_name, desc, tests, source)
    _check_args(macro_name, desc, tests)
    ex = quote
        ts = $(MACRO_TYPES[string(macro_name)])($desc)
        while false; end
        Test.push_testset(ts)
        try
            $(esc(tests))
        catch err
            record(ts, Error(:nontest_error, :(), err, catch_backtrace(), $(QuoteNode(source))))
        end
        Test.pop_testset()
        finish(ts)
    end
    if !isempty(tests.args) &&  isa(tests.args[1], LineNumberNode)
        ex = Expr(:block, tests.args[1], ex)
    end
    return ex
end
macro describe(desc, tests)
    genexpr("@describe", desc, tests, __source__)
end

macro it(desc, tests)
    genexpr("@it", desc, tests, __source__)
end

macro unit(desc, tests)
    genexpr("@unit", desc, tests, __source__)
end

function extract_test_title(args)
    for arg in args
        if isa(arg, AbstractString) return arg end
    end
    return ""
end

macro skip(tests)
    if tests.head != :macrocall
        error("@skip must be followed by a testing macro (@describe, @it, @unit, @test)")
    end
    macro_name = string(first(tests.args))
    if startswith(macro_name, "@test")
        orig_ex = Expr(:inert, tests.args[2:end])
        testres = :(Broken(:skipped, $orig_ex))
        return :(record(get_testset(), $testres))
    end
    desc = extract_test_title(tests.args)
    ex = quote
        ts = $(MACRO_TYPES[macro_name])($desc)
        record(ts, Broken(:skipped, ts))
        finish(ts)
    end
    return ex
end

end
