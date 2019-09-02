module OnlinePackage

import Base: Generator
import HTTP
import JSON
import JSON: json
import LibGit2
import Base64: base64encode

abstract type Remote end
const user_agent = "OnlinePackage/0.0.1"

include("talk_to.jl")
include("github.jl")
include("travis.jl")
include("travis_token.jl")
include("ssh_keygen.jl")
include("configure.jl")
include("copy.jl")
include("generate.jl")

end
