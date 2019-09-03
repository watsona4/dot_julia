
# Reddit.jl
[![Build Status](https://travis-ci.org/kennethberry/Reddit.jl.svg?branch=master)](https://travis-ci.org/kennethberry/Reddit.jl)

Reddit API wrapper for Julia.

## Prerequisites
**Reddit account** - A Reddit account is required to access Reddit's API.  Create one at [reddit.com](https://reddit.com).

**Client ID** & **Client Secret** - These two values are needed to access Reddit's API as a [script application](https://github.com/reddit-archive/reddit/wiki/oauth2-app-types#script), which is currently the only aplication type supported by this package. If you don’t already have a client ID and client secret, follow Reddit’s [First Steps Guide](https://github.com/reddit/reddit/wiki/OAuth2-Quick-Start-Example#first-steps) to create them.

**User Agent** - A user agent is a unique identifier that helps Reddit determine the source of network requests. To use Reddit’s API, you need a unique and descriptive user agent.
<br>
The recommended format is:
<br>
`<platform>:<app ID>:<version string> (by /u/<Reddit username>)`.
<br>
For example:
<br>
`android:com.example.myredditapp:v1.2.3 (by /u/kemitche)`.
<br>
Read more about user-agents at [Reddit’s API wiki page](https://github.com/reddit/reddit/wiki/API).


## Installation
This package can be installed using Pkg:
```julia
using Pkg
Pkg.add("Reddit")
```

## Project Status
This package is new and most of the planned functionality is yet to be implemented.

## Usage
The `Reddit` module contains a `Credentials` type:
```julia
struct Credentials <: AbstractCredentials
    id::String
    secret::String
    useragent::String
    username::String
    password::String
end
```

The `id`, `secret`, and `useragent` fields correspond to the client ID, client secret, and user agent mentioned above in the prerequisites section. The `username` and `password` fields correspond to the username and password of the user associated with the script application.

Credentials can be manually created with Strings entered into the fields:
```julia
creds = Credentials("CLIENT_ID", "CLIENT_SECRET", "USER_AGENT", "USER_NAME", "PASSWORD")
```
The information required to create `Credentials` can be stored in an ini file. The default config file contains two clients named client1 and client2, with placeholders for each client's information.
```
[client1]
client_id=CLIENT_ID_1
client_secret=CLIENT_SECRET_1
user_agent=USER_AGENT_1
password=PASSWORD_1
username=USER_NAME_1

[client2]
client_id=CLIENT_ID_2
client_secret=CLIENT_SECRET_2
user_agent=USER_AGENT_2
password=PASSWORD_2
username=USER_NAME_2
```
The `credentials()` function can be used to generate `Credentials` from an ini file.
```julia
# read credentials from default config.ini
creds = credentials("client")

# read credentials from an alternate ini
creds = credentials("CLIENT_NAME", "PATH/TO/ALTERNATE.ini")
```

In order to access Reddit's API, the `Credentials` need to be authorized to receive an access token.  The `authorize()` function can be used with `Credentials` to get an `AuthorizedCredentials` type, which contains the same fields as `Credentials` with the addition of a `token` field.
```julia
struct AuthorizedCredentials <: AbstractCredentials
    id::String
    secret::String
    useragent::String
    username::String
    password::String
    token::String
end
```
```julia
authcreds = authorize(creds)
```
The `token()` function can also be called with `Credentials` to get the access token without creating an `AuthorizedCredentials` type.
```julia
accesstoken = token(creds)
```
The `AuthorizedCredentials` can then be used in the various API call functions:
```julia
# get current user identity information
myinfo = me(authcreds)

# get karma breakdown for current user
mykarma = karma(authcreds)

# get number of subscribers for /r/julia
subcount = subscribers("Julia", authcreds)

# get Array of user's friends
f = friends(authcreds)

```
A set of `AuthorizedCredentials` can also be set as the default credentials using the `default!()` function.  When the default credentials are set, the same API call functions can be used without specifying the credentials to use.
```julia
# get current user identity information
myinfo = me()

# get karma breakdown for current user
mykarma = karma()

# get number of subscribers for /r/julia
subcount = subscribers("Julia")

# get Array of user's friends
f = friends()
```
