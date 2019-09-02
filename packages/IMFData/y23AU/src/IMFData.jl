module IMFData

using HTTP
using JSON
using Dates
using DataFrames
import Base.show

const API_URL = "http://dataservices.imf.org/REST/SDMX_JSON.svc"

export
    IMFSeries,
    get_imf_datasets,
    get_imf_datastructure,
    get_ifs_data


abstract type IMFSeries end

include("get_imf_datasets.jl")
include("get_imf_datastructure.jl")
include("get_ifs_data.jl")

end # module
