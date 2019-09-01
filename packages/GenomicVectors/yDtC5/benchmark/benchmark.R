library(rtracklayer)

#l = 1:1e4
l = 1
bam_file = "GSE25840_GSM424320_GM06985_gencode_spliced.head.bam"
bam_path = "/Users/phaverty/.julia/v0.6/GenomicVectors/BAM/GSE25840_GSM424320_GM06985_gencode_spliced.head.bam"
bam_path = "/Users/phaverty/R1039_LIB3086_SAM636333_L4_NXG2275.analyzed.bam"

gr = import(bam_path)
x = coverage(bam_path)

system.time(import(bam_path))
system.time(coverage(gr))
system.time(coverage(bam_path))

timings = data.frame(
    language = "R",
    language_version = "3.5.0",
    date = as.character(Sys.Date()),
    system.time( for(i in l) { coverage(gr) } )["elapsed"],
    stringsAsFactors=FALSE
)
