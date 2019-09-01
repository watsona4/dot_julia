using ExpressPathToRegex
using Test
using JSON

tests = JSON.parsefile(dirname(@__FILE__) * "/tests.json")

exec = (re::Regex, str) -> begin
  m = match(re, str)
  m==nothing ? nothing : [m.match; m.captures]
end

let test_path = "/user/:id",
    test_param = ExpressPathToRegex.Token(
      "id",
      "/",
      "/",
      false,
      false,
      "[^\\/]+?"
    )

    begin # arguments"
      begin # should accept an array of keys as the second argument"
        keys = []
        re, ret_keys = path_to_regex(test_path, keys, match_end=false)

        @test ret_keys == keys
        @test keys == Any[test_param]
        @test exec(re, "/user/123/show")==["/user/123", "123"]
      end

      begin # should work with keys as null"
        re, ret_keys = path_to_regex(test_path, match_end=false)

        @test ret_keys == [test_param]
        @test exec(re, "/user/123/show")==["/user/123", "123"]
      end
    end

    begin # tokens"
      tokens = ExpressPathToRegex.parse(test_path)

      begin # should expose method to compile tokens to regexp"
        re = ExpressPathToRegex.tokens_to_regex(tokens)

        @test exec(re, "/user/123")==["/user/123", "123"]
      end

      begin # should expose method to compile tokens to a path function"
        fn = ExpressPathToRegex.tokens_to_function(tokens)

        @test fn(Dict("id" => "123")) == "/user/123"
      end
    end
end

begin # rules"
  for test in tests
    path = test[1]
    opts = test[2]
    tokens = map(test[3]) do token
      if !(typeof(token) <: AbstractString)
        token = ExpressPathToRegex.Token(
          typeof(token["name"]) <: Integer ? string(token["name"]+1) : token["name"], # keys start at 1
          token["prefix"],
          token["delimiter"],
          token["optional"],
          token["repeat"],
          token["pattern"]
          )
      end
      token
    end
    matchCases = test[4]
    compileCases = length(test)>=5 ? test[5] : []
    opts_keyargs = []
    if opts != nothing
      for opt in opts
        push!(opts_keyargs, (Symbol(opt[1] == "end" ? "match_end" : opt[1]), opt[2]))
      end
    end

    keys = filter((token) -> !(typeof(token) <: AbstractString), tokens)

    # Parsing and compiling is only supported with string input.
    if typeof(path) <: AbstractString
      begin # should parse"
        @test ExpressPathToRegex.parse(path) == tokens
      end

      begin # compile"
        toPath = ExpressPathToRegex.compile(path)

        for io in compileCases
          input = io[1]
          output = io[2]

          # higher numeric token names aka keys by 1
          if input!=nothing
            parsed_input = Dict()
            for row in input
              try
                parsed_input[string(parse(Int, row[1])+1)]=row[2]
              catch
                parsed_input[row[1]] = row[2]
              end
            end
            input = parsed_input
          end

          if output != nothing
            begin # should compile using string(input)
              @test toPath(input) == output
            end
          else
            begin # should not compile using string(input)
              @test_throws ArgumentError toPath(input)
            end
          end
        end
      end

      begin # match (opts != nothing ? " using " * string(opts) : "")
        for io in matchCases
          input = io[1]
          output = io[2]
          begin "should" * (output != nothing ? " " : " not ") * "match " * string(input)
            re, ret_keys = path_to_regex(path; opts_keyargs...)

            @test ret_keys == keys
            @test exec(re, input) == output
          end
        end
      end
    end
  end
end

begin # compile errors"
  begin # should throw when a required param is undefined"
    toPath = ExpressPathToRegex.compile("/a/:b/c")

    # Expected "b" to be defined"
    @test_throws ArgumentError toPath(nothing)
  end

  begin # should throw when it does not match the pattern"
    toPath = ExpressPathToRegex.compile("/:foo(\\d+)")

    # Expected "foo" to match "\d+"
    @test_throws ArgumentError toPath(Dict("foo"=>"abc"))
  end

  begin # should throw when expecting a repeated value"
    toPath = ExpressPathToRegex.compile("/:foo+")

    # Expected "foo" to not be empty"
    @test_throws ArgumentError toPath(Dict("foo"=>[]))
  end

  begin # should throw when not expecting a repeated value"
    toPath = ExpressPathToRegex.compile("/:foo")

    # Expected "foo" to not repeat"
    @test_throws ArgumentError toPath(Dict("foo"=>[]))
  end

  begin # should throw when repeated value does not match"
    toPath = ExpressPathToRegex.compile("/:foo(\\d+)+")

    # Expected all "foo" to match "\d+"
    @test_throws ArgumentError toPath(Dict("foo"=>[1, 2, 3, 'a']))
  end
end
