
const stableGIDs = (UInt128, UInt64, UInt32, UInt16, UInt8, Int128, Int64, Int32, Int16, Int8)
const stablePIDs = (UInt128, UInt64, UInt32, UInt16, UInt8, Int128, Int64, Int32, Int16, Int8, Bool)
const stableLIDs = (UInt128, UInt64, UInt32, UInt16, UInt8, Int128, Int64, Int32, Int16, Int8)

const stableReals= (Float64, Float32, Float16, UInt128, UInt64, UInt32, UInt16, UInt8, Int128, Int64, Int32, Int16, Int8, Bool)
const stableDatas= union(stableReals, [Complex{r} for r in stableReals])
