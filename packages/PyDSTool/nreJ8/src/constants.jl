PYDSTOOL_CURVE_CLASSES = Set(["EP-C","LP-C","H-C1","H-C2","FP-C","LC-C"])

CONT_BIF_POINTS = ["B", "SP"]
EQUILIBRIUM_BIF_POINTS = ["BP", "LP", "H"]
FOLD_BIF_POINTS = ["BT", "ZH", "CP"]
HOPF_BIF_POINTS = ["BT", "ZH", "GH", "DH"]
FIXEDPOINT_BIF_POINTS = ["BP", "PD", "LPC", "NS"]
FOLD_MAP_BIF_POINTS = ["CP"]
LIMITCYCLE_BIF_POINTS = ["PD", "LPC", "NS"]
OTHER_SPECIAL_POINTS = ["RG", "UZ", "P", "MX", "B"]

ALL_POINT_TYPES = union([CONT_BIF_POINTS;EQUILIBRIUM_BIF_POINTS;FOLD_BIF_POINTS;
                   HOPF_BIF_POINTS;FIXEDPOINT_BIF_POINTS;FOLD_MAP_BIF_POINTS;
                   LIMITCYCLE_BIF_POINTS;OTHER_SPECIAL_POINTS])

set_name(dsargs,name::String) = (dsargs[:name] = name; nothing)

set_ics(dsargs,icdict::PyDict) = (dsargs[:ics] = icdict; nothing)
set_ics(dsargs,icdict::Dict{String,T}) where {T} = set_ics(dsargs,PyDict(icdict))

set_pars(dsargs,pardict::PyDict) = (dsargs[:pars] = pardict; nothing)
set_pars(dsargs,pardict::Dict{String,T}) where {T} = set_pars(dsargs,PyDict(pardict))

set_vars(dsargs,vardict::PyDict) = (dsargs[:varspecs] = vardict; nothing)
set_vars(dsargs,vardict::Dict{String,T}) where {T} = set_vars(dsargs,PyDict(vardict))

set_fnspecs(dsargs,specsdict::PyDict) = (dsargs[:fnspecs] = specsdict; nothing)
set_fnspecs(dsargs,specsdict::Dict{String,T}) where {T} = set_vars(dsargs,PyDict(specsdict))

set_tdata(dsargs,tdata) = (dsargs[:tdata] = tdata; nothing)
set_tdomain(dsargs,tdomain) = (dsargs[:tdomain] = tdomain; nothing)
