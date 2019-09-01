using GenomicFeatures
using GenomicVectors
using BioAlignments
using DataFrames
using CSV
using RLEVectors
using Dates
using Profile

macro timeit(ex)
# like @time, but returning the timing rather than the computed value
  return quote
    #gc_disable()
    local val = $ex # compile
    local t0 = time()
    for i in 1:1e2 val = $ex end
    local t1 = time()
    #gc_enable()
    t1-t0
  end
end

#bam_file = "GSE25840_GSM424320_GM06985_gencode_spliced.head.bam"
#bam_path = joinpath(dirname(pathof(GenomicVectors)),"BAM", bam_file)
#bam_path = "/Users/phaverty/R1039_LIB3086_SAM636333_L4_NXG2275.analyzed.bam"
bam_path = "/Users/phaverty/GSE25840_GSM424320_GM06985_gencode_spliced.head.bam"
reader = open(BAM.Reader, bam_path)
#Profile.init(n=10000); Profile.clear(); @profile gr = GenomicRanges("hg19", reader); Profile.print()
gr = GenomicRanges("hg19", reader)

timings = DataFrame()
timings[:language] = "julia"
timings[:language_version] = VERSION
timings[:date] = string(Dates.today())
timings[:length] = @timeit length(gr)
timings[:start] = @timeit starts(gr)
timings[:width] = @timeit widths(gr)
timings[:ends] = @timeit ends(gr)
timings[:strand] = @timeit strands(gr)
timings[:chromosomes] = @timeit chromosomes(gr)
timings[:indexing] = @timeit gr[100]
timings[:range_indexing] = @timeit gr[801:900]
timings[:coverage] = @timeit coverage(gr)
timings[:gaps] = @timeit gaps(gr)
timings[:disjoin] = @timeit disjoin(gr)
timings[:collapse] = @timeit collapse(gr)
timings[:setting] = @timeit gr[2] = Interval("hg19", 40123, 40456, STRAND_POS)
timings[:genostarts] = @timeit genostarts(gr)
timings[:issorted] = @timeit issorted(gr)
timings[:sort] = @timeit sort(gr)
timings[:as_df] = @timeit convert(DataFrame,gr)

bdf = CSV.read("/Users/phaverty/.julia/dev/GenomicVectors/benchmark/timings.csv",header=true);

for n in names(timings)
  if !(n in names(bdf))
    bdf[n] = NaN
  end
end

bdf = vcat(bdf,timings)

CSV.write( "/Users/phaverty/.julia/dev/GenomicVectors/benchmark/timings.csv", bdf)

jdf = timings
rdf = bdf[ bdf[:language] .== "R",:];
rdf = rdf[end,:]

for n in names(bdf)[4:end]
       println(n)
       println( rdf[1,n] / jdf[1,n])
end
r_over_julia = zeros(ncol(bdf)-3)

for (i in 1:length(r_over_julia))
  r_over_julia[i] = log2(rdf[1,i+3] / jdf[1,i+3])
end

### Plotting
using Gadfly

## Performance Relative to R
bench_plot = plot(x=names(bdf)[4:end],y=r_over_julia, Geom.bar, Guide.ylabel("Elapsed Time: log2(R/julia)"),
     Guide.xticks(orientation=:vertical),Scale.color_continuous(minvalue=-15,maxvalue=15),color=r_over_julia,
     Guide.title("Relative Performance of R and Julia GenomicRanges"),Geom.hline(color="black"),yintercept=[0],Guide.xlabel(""))

date = jdf[1,:date]
relative_perf_file = "/Users/phaverty/.julia/v0.6/GenomicVectors/benchmark/plots/benchmark.$(date).png"
draw(PNG(relative_perf_file,8inch,5inch),bench_plot )
current_relative_perf_file = "/Users/phaverty/.julia/v0.6/GenomicVectors/benchmark/plots/benchmark.png"
cp(relative_perf_file, current_relative_perf_file, remove_destination=true)

## Performance over time
jdf = bdf[ bdf[:,:language] .== "julia", 3:end ]
melted_bdf = melt(jdf, :date)
timeline_plot = plot(melted_bdf, x="date", y="value", color="variable", Guide.xlabel("Date"), Geom.line,
                     Scale.y_log10, Guide.ylabel("log2 elapsed seconds (1e4 runs)"))
timeline_file = "/Users/phaverty/.julia/v0.6/GenomicVectors/benchmark/plots/benchmark.$(date).timeline.png"
draw(PNG(timeline_file,10inch,6inch),timeline_plot )
current_timeline_file = "/Users/phaverty/.julia/v0.6/GenomicVectors/benchmark/plots/benchmark.timeline.png"
cp(timeline_file, current_timeline_file, remove_destination=true)

## Profiling
using ProfileView
foo + foo; Profile.clear(); @profile for i in 1:1e6 foo + foo end; ProfileView.view()
foo .< 3; Profile.clear(); @profile for i in 1:1e4 foo .< 3 end; ProfileView.view()
foo .+ 3; Profile.clear(); @profile for i in 1:1e4 foo .+ 3 end; ProfileView.view()
sum(foo); Profile.clear(); @profile for i in 1:1e4 sum(foo) end; ProfileView.view()
findin(foo,[800,300,357]); Profile.clear(); @profile for i in 1:1e5 findin(foo,[800,300,357]) end; ProfileView.view()
median(foo); Profile.clear(); @profile for i in 1:1e4 median(foo) end; ProfileView.view()
rfirst(foo); Profile.clear(); @profile for i in 1:1e6 rfirst(foo) end; ProfileView.view()
rwidth(foo); Profile.clear(); @profile for i in 1:1e6 rwidth(foo) end; ProfileView.view()
foo[800] = 5; Profile.clear(); @profile for i in 1:1e6 foo[800] = 5 end; ProfileView.view()
foo[802] = 5; Profile.clear(); @profile for i in 1:1e6 foo[802] = 5 end; ProfileView.view()
foo[801:900] = 1:100; Profile.clear(); @profile for i in 1:1e5 foo[801:900] = 1:100 end; ProfileView.view()

x = collect(2:6:5000)
y = collect(6:4:5000)

foo = disjoin(x, y)
goo = disjoin2(x, y)
goo = goo[1:1667]
foo == goo

@time for i in 1:1e6 disjoin(x, y) end
@time for i in 1:1e6 disjoin2(x, y) end
Profile.clear(); @profile for i in 1:1e6 disjoin2(x, y) end; ProfileView.view()
