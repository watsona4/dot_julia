import PkgBenchmark

# include("./utils/github/github_api_unauthenticated.jl")
# include("./utils/github/github_api_authenticated.jl")

function get_travis_git_commit_message(a::AbstractDict = ENV)::String
    result::String = strip(get(a, "TRAVIS_COMMIT_MESSAGE", ""))
    return result
end

_single_line_travis_allow_regressions(x::AbstractString) = _single_line_travis_allow_regressions(convert(String, x))

function _single_line_travis_allow_regressions(line::String)::Tuple{Bool, Bool}
    _line::String = strip(line)
    _regex_allow_onlytime_regressions = r"^\d*: \[ALLOW_TIME_REGRESSIONS\]"
    _regex_allow_onlymemory_regressions = r"^\d*: \[ALLOW_MEMORY_REGRESSIONS\]"
    _regex_allow_bothtimeandmemory_regressions = r"^\d*: \[ALLOW_TIME\+MEMORY_REGRESSIONS\]"
    _allow_onlytime_regressions::Bool = occursin(_regex_allow_onlytime_regressions, _line)
    _allow_onlymemory_regressions::Bool = occursin(_regex_allow_onlymemory_regressions, _line)
    _allow_bothtimeandmemory_regressions::Bool = occursin(_regex_allow_bothtimeandmemory_regressions, _line)
    allow_time_regressions::Bool = _allow_onlytime_regressions || _allow_bothtimeandmemory_regressions
    allow_memory_regressions::Bool = _allow_onlymemory_regressions || _allow_bothtimeandmemory_regressions
    return allow_time_regressions, allow_memory_regressions
end

travis_allow_regressions(x::AbstractString) = travis_allow_regressions(convert(String, x))

_all_and_notempty(x) = !isempty(x) && all(x)

function travis_allow_regressions(commit_message::String)::Tuple{Bool, Bool}
    lines::Vector{String} = split(strip(commit_message), "\n")
    vector_allow_time_regressions::Vector{Bool} = Vector{Bool}(undef, 0)
    vector_allow_memory_regressions::Vector{Bool} = Vector{Bool}(undef, 0)
    for line in lines
        _line = strip(line)
        if isempty(_line)
        elseif startswith(_line, "Merge #")
        elseif startswith(_line, "Try #")
        elseif startswith(_line, "Co-authored-by:")
        else
            line_allow_time_regressions, line_allow_memory_regressions = _single_line_travis_allow_regressions(_line)
            push!(vector_allow_time_regressions, line_allow_time_regressions)
            push!(vector_allow_memory_regressions, line_allow_memory_regressions)
        end
    end
    allow_time_regressions = _all_and_notempty(vector_allow_time_regressions)
    allow_memory_regressions = _all_and_notempty(vector_allow_memory_regressions)
    return allow_time_regressions, allow_memory_regressions
end

function run_benchmarks(
        ;
        target::Union{String, PkgBenchmark.BenchmarkConfig} = "HEAD",
        baseline::Union{String, PkgBenchmark.BenchmarkConfig} = "master",
        )
    # allow_time_regressions, allow_memory_regressions = travis_allow_regressions(get_github_pull_request_title_unauthenticated())
    # allow_time_regressions, allow_memory_regressions = travis_allow_regressions(get_github_pull_request_title_authenticated())

    allow_time_regressions, allow_memory_regressions = travis_allow_regressions(get_travis_git_commit_message())

    @info("Allow time regressions: $(allow_time_regressions)")
    @info("Allow memory regressions: $(allow_memory_regressions)")
    @info("Target: $(target)")
    @info("Baseline: $(baseline)")

    project_root = dirname(dirname(@__FILE__))

    proof_of_concept_dataframes = joinpath(project_root, "test", "integration-tests", "test-proof-of-concept-dataframes.jl")
    proof_of_concept_linearmodel = joinpath(project_root, "test", "integration-tests", "test-proof-of-concept-linearmodel.jl")
    proof_of_concept_mlj = joinpath(project_root, "test", "integration-tests", "test-proof-of-concept-mlj.jl")

    # run each of the scripts once to force compilation of the functions
    include(proof_of_concept_dataframes)
    include(proof_of_concept_linearmodel)
    include(proof_of_concept_mlj)

    judgement = PkgBenchmark.judge("ModelSanitizer", target, baseline)

    this_judgement_was_failed_for_time = false
    this_judgement_was_failed_for_memory = false

    for i in ["integration-tests"]
        for j in ["proof-of-concept-dataframes", "proof-of-concept-linearmodel", "proof-of-concept-mlj"]
            trial_judgement = PkgBenchmark.benchmarkgroup(judgement).data[i].data[j]
            if PkgBenchmark.time(trial_judgement) == :regression
                if allow_time_regressions
                    @error("Time regression (allowed) detected in $(i)/$(j)", trial_judgement)
                else
                    this_judgement_was_failed_for_time = true
                    @error("Time regression detected in $(i)/$(j)", trial_judgement)
                end
            end
            if PkgBenchmark.memory(trial_judgement) == :regression
                if allow_memory_regressions
                    @error("Memory regression (allowed) detected in $(i)/$(j)", trial_judgement)
                else
                    this_judgement_was_failed_for_memory = true
                    @error("Memory regression regression detected in $(i)/$(j)", trial_judgement)
                end
            end
        end
    end

    if this_judgement_was_failed_for_time || this_judgement_was_failed_for_memory
        error_message = string("FAILURE: ",
                               "One or more fatal performance ",
                               "performance regressions were detected.\n",
                               "To ignore only time regressions, ",
                               "begin your pull request title with ",
                               "\"",
                               "[ALLOW_TIME_REGRESSIONS]",
                               "\" (without the quotation marks).\n",
                               "To ignore only memory regressions, ",
                               "begin your pull request title with ",
                               "\"",
                               "[ALLOW_MEMORY_REGRESSIONS]",
                               "\".\n",
                               "To ignore both time and memory regressions, ",
                               "begin your pull request title with ",
                               "\"",
                               "[ALLOW_TIME+MEMORY_REGRESSIONS]",
                               "\".\n")
        travis_branch = lowercase(strip(get(ENV, "TRAVIS_BRANCH", "")))
        travis_pull_request = lowercase(strip(get(ENV, "TRAVIS_PULL_REQUEST", "")))
        if travis_branch == "trying" && travis_pull_request == "false"
            @error(error_message)
        else
            error(error_message)
        end
    else
        @info("SUCCESS: No fatal performance regressions were detected.")
    end
end

run_benchmarks()
