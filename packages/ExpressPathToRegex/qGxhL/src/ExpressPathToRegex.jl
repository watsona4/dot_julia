module ExpressPathToRegex

import Base.==
using URIParser

export path_to_regex

"The main path matching regexp utility."
path_regex = Regex(join([
  # Match escaped characters that would otherwise appear in future matches.
    # This allows the user to escape special characters that won't transform.
    "(\\\\.)",
  # Match Express-style parameters and un-named parameters with a prefix
  # and optional suffixes. Matches appear as:
  # "/:test(\\d+)?" => ["/", "test", "\d+", undefined, "?", undefined]
  # "/route(\\d+)"  => [undefined, undefined, undefined, "\d+", undefined, undefined]
  # "/*"            => ["/", undefined, undefined, undefined, undefined, "*"]
  "([\\/.])?(?:(?:\\:(\\w+)(?:\\(((?:\\\\.|[^()])+)\\))?|\\(((?:\\\\.|[^()])+)\\))([+*?])?|(\\*))"
], "|"))

struct Token
  name::AbstractString
  prefix::AbstractString
  delimiter::AbstractString
  optional::Bool
  repeat::Bool
  pattern::AbstractString
end

Token(name::AbstractString,
      prefix::Union{AbstractString, Nothing},
      delimiter::Union{AbstractString, Nothing},
      optional::Bool,
      repeat::Bool,
      pattern::Union{AbstractString, Nothing}) = Token(
        name,
        prefix==nothing ? "" : prefix,
        delimiter==nothing ? "" : delimiter,
        optional,
        repeat,
        pattern==nothing ? "" : pattern,
      )

function ==(a::Token, b::Token)
  @assert length(fieldnames(Token))==6
  a.name == b.name &&
  a.prefix == b.prefix &&
  a.delimiter == b.delimiter &&
  a.optional == b.optional &&
  a.repeat == b.repeat &&
  a.pattern == b.pattern
end

"Parse a string for the raw tokens."
function parse(str)
  tokens = []
  key = 0 # token key (starts at 1)
  index = 1 # julia indicies start at 1
  path = ""
  matches = eachmatch(path_regex, str)

  for res in matches
    m = res.match
    escaped = res[1] # index 1 is correct since in js res[1] is res.match
    offset = res.offset # this offset is one higher than in ref impl since julia indexing starts at 1
    path = path * str[index:offset-1]
    index = offset + length(m)

    if escaped != nothing
      path = string(path, escaped[2])
      continue
    end

    next = index <= length(str) ? str[index] : nothing
    prefix = res[2]
    name = res[3]
    capture = res[4]
    group = res[5]
    modifier = res[6]
    asterisk = res[7]

    # Only use the prefix when followed by another path segment.
    if prefix != nothing && next != nothing && next != prefix[1]
      path = path * prefix
      prefix = nothing
    end

    # Push the current path onto the tokens.
    if path != ""
      push!(tokens, path)
      path = ""
    end

    repeat = modifier == "+" || modifier == "*"
    optional = modifier == "?" || modifier == "*"
    delimiter = (res[2] != nothing) ? res[2] : "/"
    if capture != nothing
      pattern = capture
    elseif group != nothing
      pattern = group
    elseif asterisk != nothing
      pattern = ".*"
    else
      pattern = "[^" * delimiter * "]+?"
    end

    push!(tokens, Token(
      (name != nothing) ? name : string(key+=1),
      (prefix != nothing) ? prefix : "",
      delimiter,
      optional,
      repeat,
      escape_group(pattern)
    ))
  end

  # Match any characters still remaining.
  if index <= length(str)
    path = path * str[index:end]
  end

  # If the path exists, push it onto the end.
  if path!=""
    push!(tokens, path)
  end

  return tokens
end

"""
Compile a string to a template function for the path.
"""
compile(str) = tokens_to_function(parse(str))

"""
Expose a method for transforming tokens into the path function.
"""
function tokens_to_function(tokens)
  # Compile all the tokens into regexps.
  matches = map(tokens) do token
    if typeof(token) <: Token
      # Compile all the patterns before compilation.
      return Regex("^" * token.pattern * "\$")
    end
    nothing
  end

  return (obj::Union{Dict, Nothing}) -> begin
    path = ""
    data = typeof(obj) <: Dict ? obj : Dict()

    for i=1:length(tokens)
      token = tokens[i]
      if typeof(token) <: AbstractString
        path = path * token
        continue
      end

      if !haskey(data, token.name) || data[token.name] == nothing
        if token.optional
          continue
        end
        throw(ArgumentError(string("expected ", token.name, " to be defined")))
      end
      value = data[token.name]

      if typeof(value).name.name == :Array
        if !token.repeat
          throw(ArgumentError(string(
            "Expected \"", token.name, "\" to not repeat, but received \"",
            value, "\""
          )))
        end

        if length(value) == 0
          if token.optional
            continue
          else
            throw(ArgumentError(string(
              "Expected \"", token.name, "\" to not be empty"
            )))
          end
        end

        for j=1:length(value)
          segment = escape(string(value[j]))

          if match(matches[i], segment) == nothing
            throw(ArgumentError(string(
              "Expected all \"", token.name, "\" to match \"",
              token.pattern, "\", but received \"", segment, "\""
            )))
          end
          path = path * (j == 0 ? token.prefix : token.delimiter) * segment
        end

        continue
      end

      segment = escape(string(value))

      if match(matches[i], segment) == nothing
        throw(ArgumentError(string(
              "Expected \"", token.name, "\" to match \"",
              token.pattern, "\", but received \"", segment, "\""
            )))
      end

      path = path * token.prefix * segment
    end

    return path
  end # ret anon func
end

"""
Escape a regular expression string.
"""
escape_string(str) = replace(str, r"([.+*?=^!:${}()[\]|\/])" => s"\\\g<1>")

"""
Escape the capturing group by escaping special characters and meaning.
"""
escape_group(group) = replace(group, r"([=!:$\/()])" => s"\\\g<1>")

"""
Get the flags for a regexp from the options.
"""
flags(sensitive) = sensitive ? "" : "i"

"""
Pull out keys from a regexp.
"""
function path_to_regex(path::Regex, keys=[]) # former regexpToRegexp
  # Use a negative lookahead to match only capturing groups.
  groups = matchall(r"\((?!\?)", path.pattern)

  for i=1:length(groups)
    push!(keys, Token(
      i,
      "",
      "",
      false,
      false,
      ""
    ))
  end

  path, keys
end

"""
Normalize the given path array, returning a regular expression.

An empty array can be passed in for the keys, which will hold the
placeholder key descriptions. For example, using `/user/:id`, `keys` will
contain `[{ name: 'id', delimiter: '/', optional: false, repeat: false }]`.
"""
function path_to_regex(path::Array, keys=[]; strict=false,
                          match_end=true, sensitive=false) # former arrayToRegexp
  parts = []

  for i=1:length(path)
    push!(parts, path_to_regex(
        path[i],
        keys,
        strict=strict,
        match_end=match_end,
        sensitive=sensitive
      )[1].pattern
    )
  end

  Regex("(?:" * join(parts, '|') * ")", flags(sensitive)), keys
end

"""
Normalize the given path string, returning a regular expression.

An empty array can be passed in for the keys, which will hold the
placeholder key descriptions. For example, using `/user/:id`, `keys` will
contain `[{ name: 'id', delimiter: '/', optional: false, repeat: false }]`.
"""
function path_to_regex(path::AbstractString, keys=[]; strict=false,
                        match_end=true, sensitive=false) # former stringToRegexp
  tokens = parse(path)
  re = tokens_to_regex(tokens, strict=strict, match_end=match_end, sensitive=sensitive)

  # Attach keys back to the regexp.
  for token in tokens
    if !(typeof(token) <: AbstractString)
      push!(keys, token)
    end
  end
  re, keys
end

"""
Expose a function for taking tokens and returning a RegExp.
"""
function tokens_to_regex(tokens::Array; strict=false, match_end=true,
                          sensitive=false)
  route = ""
  if typeof(tokens[end]) <: AbstractString && match(r"\/$", tokens[end]) != nothing
    ends_with_slash = true
  else
    ends_with_slash = false
  end

  # Iterate over the tokens and create our regexp string.
  for token in tokens
    if typeof(token) <: AbstractString
      route = route * escape_string(token)
    else
      prefix = escape_string(token.prefix)
      capture = token.pattern

      if token.repeat
        capture = capture * "(?:" * prefix * capture * ")*"
      end

      if token.optional
        if prefix != nothing
          capture = "(?:" * prefix * "(" * capture * "))?"
        else
          capture = "(" * capture * ")?"
        end
      else
        capture = prefix * "(" * capture * ")"
       end

      route = route * capture
    end
  end

  # In non-strict mode we allow a slash at the end of match. If the path to
  # match already ends with a slash, we remove it for consistency. The slash
  # is valid at the end of a path match, not in the middle. This is important
  # in non-ending mode, where "/test/" shouldn't match "/test//route".
  if !strict
    route = (ends_with_slash ? route[1:end-2] : route) * "(?:\\/(?=\$))?"
  end

  if match_end
    route = route * "\$"
  else
    # In non-ending mode, we need the capturing groups to match as much as
    # possible by using a positive lookahead to the end or next path segment.
    route = route * ((strict && ends_with_slash) ? "" : "(?=\\/|\$)")
  end

  Regex("^" * route, flags(sensitive))
end

end # module
