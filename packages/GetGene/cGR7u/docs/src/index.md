
# GetGene.jl

GetGene.jl is a Julia package that queries the NIH NCBI's dbSNP API to retrieve gene information based on an input RefSNP ID (rsid). The package can currently get loci names for an array of rsids and retrieve other gene information for a single inputted rsid.

# Installation
This package requires Julia v0.7.0 or later. Start julia and use the `]` key to switch to the package manager REPL and proceed as follows:
```julia
(v1.0) pkg> add GetGene
```


```julia
# machine information for this tutorial
versioninfo()
```

    Julia Version 1.1.0
    Commit 80516ca202 (2019-01-21 21:24 UTC)
    Platform Info:
      OS: macOS (x86_64-apple-darwin14.5.0)
      CPU: Intel(R) Core(TM) i7-4850HQ CPU @ 2.30GHz
      WORD_SIZE: 64
      LIBM: libopenlibm
      LLVM: libLLVM-6.0.1 (ORCJIT, haswell)


In the tutorial we will use the following packages:


```julia
using DataFrames, GetGene
```

## Basic usage

The following commands can be used to create the test dataset. We will use the following rsids. 


```julia
rsids = ["rs113980419", "rs17367504", 
"rs13107325", "rs2392929", "rs11824864",
"78067132", "rs4909945", "Affx-4150211",
"rs2270993"]
df = DataFrame(rsids = rsids)
9×1 DataFrame
│ Row │ rsids        │
│     │ String       │
├─────┼──────────────┤
│ 1   │ rs113980419  │
│ 2   │ rs17367504   │
│ 3   │ rs13107325   │
│ 4   │ rs2392929    │
│ 5   │ rs11824864   │
│ 6   │ 78067132     │
│ 7   │ rs4909945    │
│ 8   │ Affx-4150211 │
│ 9   │ rs2270993    │
```




The basic commands for MendelPlots.jl are   
```julia
getgenes()
getgeneinfo()
``` 

## getgenes()

`getgenes()` gets the gene loci information from NCBI's dbSNP API. 

### Inputs
`getgenes()` takes either an array of RefSNP IDs or a dataframe where one column has the rsids. The variable name by default is assumed to be named `snpid`. The variable name can be specified using the `idvar` keyword argument. 

### Output
`getgenes()` outputs an array with the corresponding gene loci names of the inputted rsids. If the rsid is not in dbSNP, it will say the rsid was not in the database for that entry. If there was no gene associated with the rsid, it will say there is no gene listed for that entry.

For documentation of the `getgenes` function, type `?getgenes` in Julia REPL.
```@docs
getgenes
```


```julia
getgenes(rsids)
```




    9-element Array{String,1}:
     "C1orf167"             
     "MTHFR"                
     "SLC39A8"              
     "No gene listed"       
     "SPI1"                 
     "No gene listed"       
     "MRVI1"                
     "snpid not in database"
     "PTPRJ"                



the rsid should start with the prefix `rs`, but if you omit the `rs` it will also work.


```julia
getgenes("13107325")
```




    "SLC39A8"



## getgeneinfo()

`getgeneinfo()` gets the gene information of the inputted rsid from NCBI's dbSNP API. 

### Inputs
`getgenes()` takes either an array of RefSNP IDs or a dataframe where one column has the rsids. The variable name by default is assumed to be named `snpid`. The variable name can be specified using the `idvar` keyword argument. 

### Output
`getgenes()` outputs a dictionary of the corresponding rsids. If the rsid is not in dbSNP, it will return an error. If there was no gene associated with the rsid, it will say there is no gene information listed for that entry. It returns a dictionary of gene information associated with the Ref SNP ID. The dictionary keys are `seq_id`, `annotation_release`, `gene_name`, `gene_id`, `gene_locus`, `gene_is_pseudo`, and `gene_orientation`.


```julia
getgeneinfo("rs13107325")
```




    Dict{String,AbstractString} with 7 entries:
      "annotation_release" => "Homo sapiens Annotation Release 109"
      "gene_name"          => "solute carrier family 39 member 8"
      "gene_locus"         => "SLC39A8"
      "gene_id"            => "64116"
      "seq_id"             => "NC_000004.12"
      "gene_is_pseudo"     => "0"
      "gene_orientation"   => "1"


