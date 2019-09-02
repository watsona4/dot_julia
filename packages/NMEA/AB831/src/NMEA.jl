module NMEA

export NMEAData, parse_msg!, GGA,
       RMC, GSA, GSV, SVData,
       GBS, VTG, GLL, ZDA,
       DTM, parse

@static if VERSION < v"0.7.0-DEV.2005"
    occursin = ismatch
end

"""
    parse(line::AbstractString)

Parses an NMEA sentence, returning a corresponding type.
"""
function parse(line::AbstractString)
    
    message = split(line, '*')[1]
    items = split(message, ',')

    system = get_system(items[1])

    if (occursin(r"DTM$", items[1]))
        return parse_DTM(items, system)
    elseif (occursin(r"GBS$", items[1]))
        return parse_GBS(items, system)
    elseif (occursin(r"GGA$", items[1]))
        return parse_GGA(items, system)
    elseif (occursin(r"GLL$", items[1]))
        return parse_GLL(items, system)
    elseif (occursin(r"GSA$", items[1]))
        return parse_GSA(items, system)
    elseif (occursin(r"GSV$", items[1]))
        return parse_GSV(items, system)
    elseif (occursin(r"RMC$", items[1]))
        return parse_RMC(items, system)
    elseif (occursin(r"VTG$", items[1]))
        return parse_VTG(items, system)
    elseif (occursin(r"ZDA$", items[1]))
        return parse_ZDA(items, system)
    end

    throw(ArgumentError("NMEA string not supported"))
   
end

#----------
# type for GGA message - Global Positioning System Fix Data
#----------
mutable struct GGA
    system # GPS, GLONASS, GALILEO, or Combined
    time # in seconds
    latitude # decimal degrees
    longitude # decimal degrees
    fix_quality
    num_sats
    HDOP
    altitude # MSL in meters
    geoidal_seperation # meters
    age_of_differential # seconds since last SC104
    diff_reference_id # differential reference station id
    valid

    function GGA(sys::AbstractString)
        system              = sys
        time                = 0.0
        latitude            = 0.0
        longitude           = 0.0
        fix_quality         = "UNKNOWN"
        num_sats            = 0
        HDOP                = 0.0
        altitude            = 0.0
        geoidal_seperation  = 0.0
        age_of_differential = 0.0
        diff_reference_id   = 0
        valid               = false
        new(system, time, latitude,
            longitude, fix_quality, num_sats,
            HDOP, altitude, geoidal_seperation,
            age_of_differential, diff_reference_id,
            valid)
    end # constructor GGA

end # type GGA

#----------
# GSA message type - GNSS DOP and Active Satellites
#----------
mutable struct GSA
    system
    mode
    current_mode
    sat_ids
    PDOP
    HDOP
    VDOP
    valid

    function GSA(sys::AbstractString)
        system       = sys
        mode         = 'M'
        current_mode = 0
        sat_ids      = []
        PDOP         = 0.0
        HDOP         = 0.0
        VDOP         = 0.0
        valid        = false
        new(system, mode, current_mode,
            sat_ids, PDOP, HDOP,
            VDOP, valid)
    end # constructor GSA
end # type GSA

#----------
# ZDA message type - Time and Date
#----------
mutable struct ZDA
    system
    time
    day
    month
    year
    zone_hrs
    zone_mins
    valid

    function ZDA(sys::AbstractString)
        system    = sys
        time      = 0.0
        day       = 0
        month     = 0
        year      = 0
        zone_hrs  = 0
        zone_mins = 0
        valid     = false
        new(system, time, day,
            month, year, zone_hrs,
            zone_mins, valid)
    end # constructor ZDA

end # type ZDA

#----------
# GBS message type - RAIM GNSS Satellite Fault Detection
#----------
mutable struct GBS
    system
    time
    lat_error
    long_error
    alt_error
    failed_PRN
    prob_of_missed
    excluded_meas_err
    standard_deviation
    valid

    function GBS(sys::AbstractString)
        system             = sys
        time               = 0.0
        lat_error          = 0.0
        long_error         = 0.0
        alt_error          = 0.0
        failed_PRN         = 0
        prob_of_missed     = 0.0
        excluded_meas_err  = 0.0
        standard_deviation = 0.0
        valid              = false
        new(system, time, lat_error,
            long_error, alt_error, failed_PRN,
            prob_of_missed, excluded_meas_err, standard_deviation,
            valid)
    end # constructor GBS
end # type GBS

#----------
# GLL message type - Geographic Position –
# Latitude/Longitude
#----------
mutable struct GLL
    system
    latitude
    longitude
    time
    status
    mode
    valid

    function GLL(sys::AbstractString)
        system    = sys
        latitude  = 0.0
        longitude = 0.0
        time      = 0.0
        status    = false
        mode      = 'N'
        valid     = false
        new(system, latitude, longitude,
            time, status, mode,
            valid)
    end # constructor GLL
end # type GLL

#----------
# type to store SV data fields in GSV
#----------
mutable struct SVData
    PRN
    elevation
    azimuth
    SNR

    function SVData()
        PRN       = 0
        elevation = 0
        azimuth   = 0
        SNR       = 0
        new(PRN, elevation, azimuth,
            SNR)
    end # constructor SVData
end # type SVData

#-----------
# type for GSV messages - GNSS Satellites In View
#-----------
mutable struct GSV
    system
    msg_total
    msg_num
    sat_total
    SV_data
    valid

    function GSV(sys::AbstractString)
        system    = sys
        msg_total = 0
        msg_num   = 0
        sat_total = 0
        SV_data   = []
        valid     = false
        new(system, msg_total, msg_num,
            sat_total, SV_data, valid)
    end # constructor GSV
end # type GSV

#----------
# RMC message type - Recommended Minimum Specific GNSS Data
#----------
mutable struct RMC
    system
    time
    status
    latitude
    longitude
    sog
    cog
    date
    magvar
    mode
    valid

    function RMC(sys::AbstractString)
        system    = sys
        time      = 0.0
        status    = false
        latitude  = 0.0
        longitude = 0.0
        sog       = 0.0
        cog       = 0.0
        date      = ""
        magvar    = 0.0
        mode      = 'N'
        valid     = false
        new(system, time, status,
            latitude, longitude, sog,
            cog, date, magvar,
            mode, valid)
    end # constructor RMC
end # type RMC

#----------
# VTG message type - Course over Ground & Ground Speed
#----------
mutable struct VTG
    CoG_true
    CoG_mag
    SoG_knots
    SoG_kmhr
    mode
    valid

    function VTG(sys::AbstractString)
        CoG_true  = 0.0
        CoG_mag   = 0.0
        SoG_knots = 0.0
        SoG_kmhr  = 0.0
        mode      = 'N'
        valid     = false
        new(CoG_true, CoG_mag, SoG_knots,
            SoG_kmhr, mode, valid)
    end # constructor VTG

end # type VTG

#----------
# DTM message type - Datum
#----------
mutable struct DTM
    system
    local_datum_code
    local_datum_subcode
    lat_offset
    long_offset
    alt_offset
    ref_datum
    valid

    function DTM(sys::AbstractString)
        system              = sys 
        local_datum_code    = ""
        local_datum_subcode = ""
        lat_offset          = 0.0
        long_offset         = 0.0
        alt_offset          = 0.0
        ref_datum           = ""
        valid               = false
        
        new(system, local_datum_code, local_datum_subcode,
            lat_offset, long_offset, alt_offset,
            ref_datum, valid)
    end # constructor DTM
end # type DTM

#----------
# module handler
#----------
mutable struct NMEAData
    last_GGA::GGA
    last_RMC::RMC
    last_GSA::GSA
    last_GSV::GSV
    last_GBS::GBS
    last_VTG::VTG
    last_GLL::GLL
    last_ZDA::ZDA
    last_DTM::DTM

    function NMEAData()
        last_GGA = GGA("UNKNOWN")
        last_RMC = RMC("UNKNOWN")
        last_GSA = GSA("UNKNOWN")
        last_GSV = GSV("UNKNOWN")
        last_GBS = GBS("UNKNOWN")
        last_VTG = VTG("UNKNOWN")
        last_GLL = GLL("UNKNOWN")
        last_ZDA = ZDA("UNKNOWN")
        last_DTM = DTM("UNKNOWN")
        new(last_GGA, last_RMC, last_GSA,
            last_GSV, last_GBS, last_VTG,
            last_GLL, last_ZDA, last_DTM)
    end # constructor NMEAData
end # type NMEAData

#----------
# open serial port and start reading NMEAData messages
#----------
function parse_msg!(s::NMEAData, line::AbstractString)
    message = split(line, '*')[1]
    items = split(message, ',')

    # get system name
    system = get_system(items[1])

    mtype = ""
    if (occursin(r"DTM$", items[1]))
        s.last_DTM = parse_DTM(items, system)
        mtype = "DTM"
   
    elseif (occursin(r"GBS$", items[1]))
        s.last_GBS = parse_GBS(items, system)
        mtype = "GBS"
    
    elseif (occursin(r"GGA$", items[1]))
        s.last_GGA = parse_GGA(items, system)
        mtype = "GGA"
    
    elseif (occursin(r"GLL$", items[1]))
        s.last_GLL = parse_GLL(items, system)
        mtype = "GLL"
    
    elseif (occursin(r"GNS$", items[1]))
        mtype = "GNS"
    
    elseif (occursin(r"GSA$", items[1]))
        s.last_GSA = parse_GSA(items, system)
        mtype = "GSA"
    
    elseif (occursin(r"GSV$", items[1]))
        s.last_GSV = parse_GSV(items, system)
        mtype = "GSV"
    
    elseif (occursin(r"RMC$", items[1]))
        s.last_RMC = parse_RMC(items, system)
        mtype = "RMC"
    
    elseif (occursin(r"VTG$", items[1]))
        s.last_VTG = parse_VTG(items, system)
        mtype = "VTG"
    
    elseif (occursin(r"ZDA$", items[1]))
        s.last_ZDA = parse_ZDA(items, system)
        mtype = "ZDA"
    else
        mtype = "PROPRIETARY"
    end
    mtype
end # function parse_msg!

#----------
# determines system from message type string
#----------
function get_system(mtype::SubString)
    system = ""

    # GPS
    if (occursin(r"^\$GP", mtype))
        system = "GPS"

    # GLONASS
    elseif (occursin(r"^\$GL", mtype))
        system = "GLONASS"

    # GALILEO
    elseif (occursin(r"^\$GA", mtype))
        system = "GALILEO"

    # Combined
    elseif (occursin(r"^\$GN", mtype))
        system = "COMBINED"

    # Proprietary (non-NMEA standard) message
    else
        system = "UNKNOWN"
    end

    system
end # function get_system

#----------
# parses GGA messages and returns populated GGA type
#----------
function parse_GGA(items::Array{T}, system::AbstractString) where T <: SubString
    GGA_data = GGA(system)
    GGA_data.time = _hms_to_secs(items[2])
    GGA_data.latitude = _dms_to_dd(items[3], items[4])
    GGA_data.longitude = _dms_to_dd(items[5], items[6])
    
    fix_flag = tryparse(Int, items[7])
    if (fix_flag == 0)
        GGA_data.fix_quality = "INVALID"
    elseif (fix_flag == 1)
        GGA_data.fix_quality = "GPS (SPS)"
    elseif (fix_flag == 2)
        GGA_data.fix_quality = "DGPS"
    elseif (fix_flag == 3)
        GGA_data.fix_quality = "PPS"
    elseif (fix_flag == 4)
        GGA_data.fix_quality = "REAL TIME KINEMATIC"
    elseif (fix_flag == 5)
        GGA_data.fix_quality = "FLOAT RTK"
    elseif (fix_flag == 6)
        GGA_data.fix_quality = "DEAD RECKONING"
    elseif (fix_flag == 7)
        GGA_data.fix_quality = "MANUAL INPUT"
    elseif (fix_flag == 8)
        GGA_data.fix_quality = "SIMULATION"
    else
        GGA_data.fix_quality = "UNKNOWN"
    end

    GGA_data.num_sats            = tryparse(Int, items[8])
    GGA_data.HDOP                = tryparse(Float64, items[9])
    GGA_data.altitude            = tryparse(Float64, items[10])
    GGA_data.geoidal_seperation  = tryparse(Float64, items[12])
    GGA_data.age_of_differential = tryparse(Float64, items[14])
    GGA_data.diff_reference_id   = tryparse(Int, items[15])
    GGA_data.valid               = true
    GGA_data
end # function parse_GGA

#----------
# parse GSA messages
#----------
function parse_GSA(items::Array{T}, system::AbstractString)  where T <: SubString
    GSA_data = GSA(system)
    GSA_data.mode = items[2][1]
    GSA_data.current_mode = tryparse(Int, items[3])

    for i = 4:length(items) - 3
        if (items[i] == "")
            break
        end
        push!(GSA_data.sat_ids, tryparse(Int, items[i]))
    end
    
    GSA_data.PDOP  = tryparse(Float64, items[end - 2])
    GSA_data.HDOP  = tryparse(Float64, items[end - 1])
    GSA_data.VDOP  = tryparse(Float64, items[end])
    GSA_data.valid = true
    GSA_data
end # function parse_GSA

#----------
# parse ZDA message
#----------
function parse_ZDA(items::Array{T}, system::AbstractString) where T <: SubString
    ZDA_data = ZDA(system)
    ZDA_data.time      = _hms_to_secs(items[2])
    ZDA_data.day       = tryparse(Int, items[3])
    ZDA_data.month     = tryparse(Int, items[4])
    ZDA_data.year      = tryparse(Int, items[5])
    ZDA_data.zone_hrs  = tryparse(Int, items[6])
    ZDA_data.zone_mins = tryparse(Int, items[7])
    ZDA_data.valid     = true
    ZDA_data
end # function parse_ZDA

#----------
# parse GBS messages
#----------
function parse_GBS(items::Array{T}, system::AbstractString) where T <: SubString
    GBS_data                    = GBS(system)
    GBS_data.time               = _hms_to_secs(items[2])
    GBS_data.lat_error          = tryparse(Float64, items[3])
    GBS_data.long_error         = tryparse(Float64, items[4])
    GBS_data.alt_error          = tryparse(Float64, items[5])
    GBS_data.failed_PRN         = tryparse(Int, items[6])
    GBS_data.prob_of_missed     = tryparse(Float64, items[7])
    GBS_data.excluded_meas_err  = tryparse(Float64, items[8])
    GBS_data.standard_deviation = tryparse(Float64, items[9])
    GBS_data.valid              = true
    GBS_data
end # function parse_GBS

#----------
# parse GLL message
#----------
function parse_GLL(items::Array{T}, system::AbstractString) where T <: SubString
    GLL_data           = GLL(system)
    GLL_data.latitude  = _dms_to_dd(items[2], items[3])
    GLL_data.longitude = _dms_to_dd(items[4], items[5])
    GLL_data.time      = _hms_to_secs(items[6])

    if (items[7] == "A")
        GLL_data.status = true
    else
        GLL_data.status = false
    end

    if (items[8] != "")
        GLL_data.mode = items[8][1]
    end

    GLL_data.valid = true
    GLL_data
end # function parse_GLL

#----------
# parse GSV messages
#----------
function parse_GSV(items::Array{T}, system::AbstractString) where T <: SubString
    GSV_data           = GSV(system)
    GSV_data.msg_total = tryparse(Int, items[2])
    GSV_data.msg_num   = tryparse(Int, items[3])
    GSV_data.sat_total = tryparse(Int, items[4])

    i = 5
    while i < length(items)
        svd           = SVData()
        svd.PRN       = tryparse(Int, items[i])
        svd.elevation = tryparse(Int, items[i + 1])
        svd.azimuth   = tryparse(Int, items[i + 2])
        svd.SNR       = tryparse(Int, items[i + 3])
        push!(GSV_data.SV_data, svd)
        i += 4
    end
    
    GSV_data.valid = true
    GSV_data
end # function parse_GSV

#----------
# parse RMC messages
#----------
function parse_RMC(items::Array{T}, system::AbstractString) where T <: SubString
    RMC_data = RMC(system)
    RMC_data.time = _hms_to_secs(items[2])

    if (items[3] == "A")
        RMC_data.status = true
    else
        RMC_data.status = false
    end

    RMC_data.latitude  = _dms_to_dd(items[4], items[5])
    RMC_data.longitude = _dms_to_dd(items[6], items[7])
    RMC_data.sog       = tryparse(Float64, items[8])
    RMC_data.cog       = tryparse(Float64, items[9])
    RMC_data.date      = string(items[10][3:4], '/', items[10][1:2], '/', items[10][5:6])

    if (items[12] == "W" || items[12] == "S")
        RMC_data.magvar = tryparse(Float64, items[11]) * -1
    else
        RMC_data.magvar = tryparse(Float64, items[11])
    end
    RMC_data.mode = items[13][1]
    RMC_data.valid = true
    RMC_data
end # function parse_RMC

#----------
# parses VTG messages
#----------
function parse_VTG(items::Array{T}, system::AbstractString) where T <: SubString
    VTG_data = VTG(system)
    VTG_data.CoG_true  = tryparse(Float64, items[2])
    VTG_data.CoG_mag   = tryparse(Float64, items[4])
    VTG_data.SoG_knots = tryparse(Float64, items[6])
    VTG_data.SoG_kmhr  = tryparse(Float64, items[8])
    VTG_data.mode      = items[10][1]
    VTG_data.valid     = true
    VTG_data
end # function parse_VTG

#----------
# parse DTM messages
#----------
function parse_DTM(items::Array{T}, system::AbstractString) where T <: SubString
    DTM_data = DTM(system)
    DTM_data.local_datum_code = items[2]
    DTM_data.local_datum_subcode = items[3]
    lat_offset = tryparse(Float64, items[4])
    if (items[5] == "S")
        DTM_data.lat_offset = lat_offset * -1
    else
        DTM_data.lat_offset = lat_offset
    end

    long_offset = tryparse(Float64, items[6])
    if (items[7] == "W")
        DTM_data.long_offset = long_offset * -1
    else
        DTM_data.long_offset = long_offset
    end

    DTM_data.alt_offset = tryparse(Float64, items[8])
    DTM_data.ref_datum  = items[9]
    DTM_data.valid      = true
    DTM_data
end # function parse_DTM

#----------
# convert degrees minutes seconds to decimal degrees
#----------
function _dms_to_dd(dms::SubString, hemi::SubString)
    if (dms[1:1] == "0")
        dms = dms[2:end]
    end

    degrees = Base.parse(Float64, dms[1:2])
    minutes = Base.parse(Float64, dms[3:end])
    dec_degrees = degrees + (minutes / 60)

    if (hemi == "S" || hemi == "W")
        dec_degrees *= -1
    end

    dec_degrees
end # function _dms_to_dd

#----------
# hhmmss.s-s to time of day in seconds
#----------
function _hms_to_secs(hms::SubString)
    hours   = Base.parse(Float64, hms[1:2])
    minutes = Base.parse(Float64, hms[3:4])
    seconds = Base.parse(Float64, hms[5:end])
    (hours * 3600) + (minutes * 60) + seconds
end # function _hms_to_secs

end # module NMEA
