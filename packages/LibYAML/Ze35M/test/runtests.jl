using LibYAML
using Test

@test LibYAML.get_version_string() === "0.2.1"
@test LibYAML.get_version() === (0, 2, 1)
