module UAParser

export parsedevice, parseuseragent, parseos, DeviceResult, OSResult, UAResult, DataFrame


##############################################################################
##
## Dependencies
##
##############################################################################

using YAML, DataFrames
import DataFrames.DataFrame, DataFrames.names!

##############################################################################
##
## Load YAML file
##
##############################################################################

const REGEXES = YAML.load(open(joinpath(dirname(@__FILE__), "..", "regexes.yaml")));

##############################################################################
##
## Create custom types to hold parsed YAML output
##
##############################################################################

# helper function used by constructors
_check_missing_string(s::AbstractString) = String(s)
_check_missing_string(::Missing) = missing
_check_missing_string(::Nothing) = missing
_check_missing_string(x) = ArgumentError("Invalid string or missing passed: $x")

struct UserAgentParser
    user_agent_re::Regex
    family_replacement::Union{String, Missing}
    v1_replacement::Union{String, Missing}
    v2_replacement::Union{String, Missing}

    function UserAgentParser(user_agent_re::Regex, family_replacement, v1_replacement,
                             v2_replacement)
        new(user_agent_re, _check_missing_string(family_replacement),
            _check_missing_string(v1_replacement), _check_missing_string(v2_replacement))
    end
end

struct OSParser
    user_agent_re::Regex
    os_replacement::Union{String, Missing}
    os_v1_replacement::Union{String, Missing}
    os_v2_replacement::Union{String, Missing}

    function OSParser(user_agent_re::Regex, os_replacement, os_v1_replacement, os_v2_replacement)
        new(user_agent_re, _check_missing_string(os_replacement), _check_missing_string(os_v1_replacement),
            _check_missing_string(os_v2_replacement))
    end
end

struct DeviceParser
    user_agent_re::Regex
    device_replacement::Union{String, Missing}
    brand_replacement::Union{String, Missing}
    model_replacement::Union{String, Missing}

    function DeviceParser(user_agent_re::Regex, device_replacement, brand_replacement,
                          model_replacement)
        new(user_agent_re, _check_missing_string(device_replacement),
            _check_missing_string(brand_replacement), _check_missing_string(model_replacement))
    end
end

##############################################################################
##
## Create custom types to hold function results
##
##############################################################################

struct DeviceResult
    family::String
    brand::Union{String, Missing}
    model::Union{String, Missing}

    function DeviceResult(family::AbstractString, brand, model)
        new(string(family), _check_missing_string(brand), _check_missing_string(model))
    end
end

struct UAResult
    family::String
    major::Union{String, Missing}
    minor::Union{String, Missing}
    patch::Union{String, Missing}

    function UAResult(family::AbstractString, major, minor, patch)
        new(string(family), _check_missing_string(major), _check_missing_string(minor),
            _check_missing_string(patch))
    end
end

struct OSResult
    family::String
    major::Union{String, Missing}
    minor::Union{String, Missing}
    patch::Union{String, Missing}
    patch_minor::Union{String, Missing}

    function OSResult(family::AbstractString, major, minor, patch, patch_minor)
        new(string(family), _check_missing_string(major), _check_missing_string(minor),
            _check_missing_string(patch), _check_missing_string(patch_minor))
    end
end

##############################################################################
##
## Create USER_AGENT_PARSERS, OS_PARSERS, and DEVICE_PARSERS arrays
##
##############################################################################

function loadua()
  #Create empty array to hold user-agent information
  temp = []

  #Loop over entire set of user_agent_parsers, add to USER_AGENT_PARSERS
  for _ua_parser in REGEXES["user_agent_parsers"]
      _user_agent_re = Regex(_ua_parser["regex"])
      _family_replacement = get(_ua_parser, "family_replacement", missing)
      _v1_replacement = get(_ua_parser, "v1_replacement", missing)
      _v2_replacement = get(_ua_parser, "v2_replacement", missing)

    #Add values to array
      push!(temp, UserAgentParser(_user_agent_re,
                                  _family_replacement,
                                  _v1_replacement,
                                  _v2_replacement
                                  ))
  end
  return temp
end #End loadua

const USER_AGENT_PARSERS = loadua()

function loados()
  #Create empty array to hold os information
  temp = []

  #Loop over entire set of os_parsers, add to OS_PARSERS
  for _os_parser in REGEXES["os_parsers"]
    _user_agent_re = Regex(_os_parser["regex"])
    _os_replacement = get(_os_parser, "os_replacement", missing)
    _os_v1_replacement = get(_os_parser, "os_v1_replacement", missing)
    _os_v2_replacement = get(_os_parser, "os_v2_replacement", missing)

    #Add values to array
    push!(temp, OSParser(_user_agent_re,
                         _os_replacement,
                         _os_v1_replacement,
                         _os_v2_replacement
                         ))

  end
  return temp
end #End loados

const OS_PARSERS = loados()

function loaddevice()
  #Create empty array to hold device information
  temp = []

  #Loop over entire set of device_parsers, add to DEVICE_PARSERS
  for _device_parser in REGEXES["device_parsers"]
      _user_agent_re = Regex(_device_parser["regex"])
      _device_replacement = get(_device_parser, "device_replacement", missing)
      _brand_replacement = get(_device_parser, "brand_replacement", missing)
      _model_replacement = get(_device_parser, "model_replacement", missing)

    #Add values to array
      push!(temp, DeviceParser(_user_agent_re, _device_replacement, _brand_replacement,
                               _model_replacement))
  end
  return temp
end #End loaddevice

const DEVICE_PARSERS = loaddevice()

##############################################################################
##
## Functions for parsing user agent strings
##
##############################################################################

# helper function for parsedevice
function _inner_replace(str::AbstractString, group)
    # TODO this rather dangerously assumes that strings are $ followed by ints
    idx = parse(Int, str[2:end])
    if idx ≤ length(group) && group[idx] ≠ nothing
        group[idx]
    else
        ""
    end
end

# helper function for parsedevice
function _multireplace(str::AbstractString, mtch::RegexMatch)
    _str = replace(str, r"\$(\d)" => m -> _inner_replace(m, mtch.captures))
    _str = replace(_str, r"^\s+|\s+$" => "")
    length(_str) == 0 ? missing : _str
end


function parsedevice(user_agent_string::AbstractString)
    for value in DEVICE_PARSERS
        if occursin(value.user_agent_re, user_agent_string)

            # TODO, this is probably really inefficient, should be one call with occursin
            _match = match(value.user_agent_re, user_agent_string)

            # family
            if !ismissing(value.device_replacement)
                device = _multireplace(value.device_replacement, _match)
            else
                device = _match.captures[1]
            end

            # brand
            if !ismissing(value.brand_replacement)
                brand = _multireplace(value.brand_replacement, _match)
            elseif length(_match.captures) > 1
                brand = match_vals[2]
            else
                brand = missing
            end

            # model
            if !ismissing(value.model_replacement)
                model = _multireplace(value.model_replacement, _match)
            elseif length(_match.captures) > 2
                model = match_vals[3]
            else
                model = missing
            end

            return DeviceResult(device, brand, model)
        end
    end
    DeviceResult("Other",missing,missing)  #Fail-safe for no match
end # parsedevice
parsedevice(::Missing) = missing


function parseuseragent(user_agent_string::AbstractString)
  for value in USER_AGENT_PARSERS
    if occursin(value.user_agent_re, user_agent_string)

      match_vals = match(value.user_agent_re, user_agent_string).captures

      #family
      if !ismissing(value.family_replacement)
        if occursin(r"\$1", value.family_replacement)
          family = replace(value.family_replacement, "\$1", match_vals[1])
        else
          family = value.family_replacement
        end
      else
        family = match_vals[1]
      end

      #major
      if !ismissing(value.v1_replacement)
        v1 = value.v1_replacement
      elseif length(match_vals) > 1
        v1 = match_vals[2]
      else
        v1 = missing
      end

      #minor
      if !ismissing(value.v2_replacement)
        v2 = value.v2_replacement
      elseif length(match_vals) > 2
        v2 = match_vals[3]
      else
        v2 = missing
      end

      #patch
      if length(match_vals) > 3
        v3 = match_vals[4]
      else
        v3 = missing
      end

      return UAResult(family, v1, v2, v3)

    end
  end

return UAResult("Other", missing, missing, missing) #Fail-safe for no match
end #End parseuseragent
parseuseragent(::Missing) = missing


function parseos(user_agent_string::AbstractString)
    for value in OS_PARSERS
        if occursin(value.user_agent_re, user_agent_string)
            match_vals = match(value.user_agent_re, user_agent_string).captures

            #os
            if !ismissing(value.os_replacement)
                os = value.os_replacement
            else
                os = match_vals[1]
            end

            #os_v1
            if !ismissing(value.os_v1_replacement)
                os_v1 = value.os_v1_replacement
            elseif length(match_vals) > 1
                os_v1 = match_vals[2]
            else
                os_v1 = missing
            end

            #os_v2
            if !ismissing(value.os_v2_replacement)
                os_v2 = value.os_v2_replacement
            elseif length(match_vals) > 2
                os_v2 = match_vals[3]
            else
                os_v2 = missing
            end

            #os_v3
            if length(match_vals) > 3
                os_v3 = match_vals[4]
            else
                os_v3 = missing
            end

            #os_v4
            if length(match_vals) > 4
                os_v4 = match_vals[5]
            else
                os_v4 = missing
            end

            return OSResult(os, os_v1, os_v2, os_v3, os_v4)

        end
    end

return OSResult("Other", missing, missing, missing, missing) #Fail-safe if no match
end #End parseos
parseos(::Missing) = missing


##############################################################################
##
## Extend DataFrames to include UAParser methods
##
##############################################################################

#DeviceResult to DataFrame method
function DataFrame(x::AbstractVector{DeviceResult})
    temp = DataFrame()

    temp["device"] = String[element.family for element in x]

    temp["brand"] = Union{String,Missing}[element.brand for element in x]

    temp["model"] = Union{String,Missing}[element.model for element in x]

    temp
end

#OSResult to DataFrame method
function DataFrame(x::AbstractVector{OSResult})
    temp = DataFrame()

    #Family - Can use comprehension since family always String
    temp["os_family"] = String[element.family for element in x]

    #Major
    temp["os_major"] = Union{String,Missing}[element.major for element in x]

    #Minor
    temp["os_minor"] = Union{String,Missing}[element.minor for element in x]

    #Patch
    temp["os_patch"] = Union{String,Missing}[element.patch for element in x]

    #Patch_Minor
    temp["os_patch_minor"] = Union{String,Missing}[element.patch_minor for element in x]

    temp
end

#UAResult to DataFrame method
function DataFrame(x::AbstractVector{UAResult})
  #Pre-allocate size of DataFrame based on array passed in
  temp = DataFrame()

  #Family - Can use comprehension since family always String
  temp["browser_family"] = String[element.family for element in x]

  #Major
  temp["browser_major"] = Union{String,Missing}[element.major for element in x]

  #Minor
  temp["browser_minor"] = Union{String,Missing}[element.minor for element in x]

  #Patch
  temp["browser_patch"] = Union{String,Missing}[element.patch for element in x]

  temp
end

end # module
