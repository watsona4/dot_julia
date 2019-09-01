using Distributed
using ArgParse
procs_id = addprocs(8)
@everywhere using Distributions
@everywhere using Cumulants
@everywhere using SymmetricTensors
using JLD2
using FileIO
using Random

@everywhere import CumulantsFeatures: reduceband
@everywhere using DatagenCopulaBased
@everywhere using CumulantsFeatures
@everywhere cut_order(x) = (x->x[3]).(x)


function main(args)
  s = ArgParseSettings("description")
  @add_arg_table s begin
    "--nu", "-u"
    default = 5
    help = "the number of degrees of freedom for the t-Student copula"
    arg_type = Int
  end
  parsed_args = parse_args(s)
  ν = parsed_args["nu"]

  println(ν)
  @everywhere t = 100_000
  @everywhere n = 50
  @everywhere malf_size = 10
  data_dir = "jkfsdata_select"
  test_number = 25
  filename = "tstudent_$(ν)-t_size-$(n)_malfsize-$malf_size-t_$t.jld2"

  data = Dict{String, Any}("variables_no" => n,
                         "sample_number" => t,
                         "ν" => ν,
                         "test_number" => test_number,
                         "malf_size" => malf_size,
                         "data" => Dict{String, Dict{String,Any}}())


  known_data_size = 0
  if isfile("$data_dir/$filename")
   data["data"] = load("$data_dir/$filename")["data"]
   known_data_size += length(data["data"])
   println("Already have $known_data_size samples \n Will generate $(test_number-known_data_size) more")
  end

  #true calculations
  println("Calculation started")
  for m=(known_data_size+1):test_number
    @time begin
      println(" > $m ($ν)")
      malf = randperm(n)[1:malf_size]
      Σ = cormatgen_rand(n)
      samples_orig = Array(rand(MvNormal(Σ), t)')

      versions = [(x->x, "original"),
                  (x->gcop2tstudent(x, malf, ν), "malf")]

      cur_dict = Dict{String, Any}("malf" => malf,
                                   "cor_source" => Σ)

      data_dict = @distributed (merge) for (sampler, label)=versions
        println(label)
        samples = Array(sampler(samples_orig))
        Σ_malf = SymmetricTensor(cov(samples))
        cum = cumulants(samples, 4)
        bands2 = cut_order(cumfsel(Σ_malf))
        bands3 = cut_order(cumfsel(cum[2], cum[3], "hosvd"))
        bands4 = cut_order(cumfsel(cum[2], cum[4], "hosvd"))
        bands4n = cut_order(cumfsel(cum[2], cum[4], "norm", n-1))
        bands4n = vcat(bands4n, setdiff(collect(1:n), bands4n))
        Dict("cor_$label" => Σ_malf,
             "bands_MEV_$label" => bands2,
             "bands_JSBS_$label" => bands3,
             "bands_JKFS_$label" => bands4,
             "bands_JKN_$label" => bands4n)
      end

      data["data"]["$m"] = merge(cur_dict, data_dict)
      save("$data_dir/$filename", data)
    end
  end
end

main(ARGS)
