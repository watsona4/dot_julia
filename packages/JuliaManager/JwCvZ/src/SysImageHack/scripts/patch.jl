# Monkey patch `Base.package_slug`
#
# See also:
# * Suggestion: Use different precompilation cache path for different
#   system image -- https://github.com/JuliaLang/julia/pull/29914
#
Base.eval(Base, quote
    function package_slug(uuid::UUID, p::Int=5)
        crc = _crc32c(uuid)
        crc = _crc32c(unsafe_string(JLOptions().image_file), crc)
        crc = _crc32c(get(ENV, "JLM_PRECOMPILE_KEY", ""), crc)
        return slug(crc, p)
    end
end)
