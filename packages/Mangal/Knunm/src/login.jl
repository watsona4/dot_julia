"""
    login(token::AbstractString)

This function will store the token in the `MANGAL_BEARER_TOKEN` environmental
variable. To get the your token, please use `login` with no argument.
"""
function login(token::AbstractString)
    ENV["MANGAL_BEARER_TOKEN"] = token
    @info "Bearer token registered"
end

"""
    login()

Read the bearer token from the `MANGAL_BEARER_TOKEN` environment variable. If
not found, displays a login message with a login URL. Currently, being logged in
is only necessary to access private datasets.
"""
function login()
    if haskey(ENV, "MANGAL_BEARER_TOKEN")
        @info "Your bearer token is already registered"
    else
        Mangal.login_message()
    end
end

"""
    login_message()

Points user to the login URL, and explains how the bearer token can be saved
persistently.
"""
function login_message()
    @info "You need to login"

    msg = """ To login, please go to

    $(Mangal.web_root)auth/

    You will be prompted to login using ORCID - when this is done, you will be
    returned to your profile page, which contains the access_token. Copy and
    paste this value, and use it in the login function:

    julia> my_access_token = "12345654-1234-1234-4321-4343435353"
    julia> Mangal.login(my_access_token)

    If you want to save your bearer token, you can place it in an environmental
    variable named MANGAL_BEARER_TOKEN -- this will let you use

    julia> Mangal.login()
    """

    @info msg
end
