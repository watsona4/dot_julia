function _print_welcome_message()::Nothing
    predictmdextra_version::VersionNumber = version()
    predictmdextra_pkgdir::String = package_directory()
    @info(string("This is PredictMDExtra, version ",predictmdextra_version,),)
    @info(string("For help, please visit https://predictmd.net",),)
    @debug(string("PredictMDExtra package directory: ",predictmdextra_pkgdir,),)
    return nothing
end
