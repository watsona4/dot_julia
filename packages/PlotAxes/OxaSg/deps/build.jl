using Pkg

if lowercase(get(ENV, "CI", "false")) == "true"
  ENV["R_HOME"]="*"
  # the latest Conda master simplifies the specification of conda channels
  pkg"add Conda RCall "
  pkg"build RCall"
  using Conda
  Conda.add_channel("r")
  Conda.add("r-ggplot2")
end
