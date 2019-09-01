# [DropboxSDK](https://github.com/eschnett/DropboxSDK.jl)

A Julia package to access Dropbox via its
[API](https://www.dropbox.com/developers/documentation/http). This
package can either be used as library for other packages, or as
command line client `dbftp`.

[![Build Status (Travis)](https://travis-ci.org/eschnett/DropboxSDK.jl.svg?branch=master)](https://travis-ci.org/eschnett/DropboxSDK.jl)
[![Build status (Appveyor)](https://ci.appveyor.com/api/projects/status/eo7ajcctw4666pxm?svg=true)](https://ci.appveyor.com/project/eschnett/dropboxsdk-jl)
[![Coverage Status (Coveralls)](https://coveralls.io/repos/github/eschnett/DropboxSDK.jl/badge.svg?branch=master)](https://coveralls.io/github/eschnett/DropboxSDK.jl?branch=master)
[![DOI](https://zenodo.org/badge/175658475.svg)](https://zenodo.org/badge/latestdoi/175658475)



## Installation

You install this package in the usual way via

```Julia
using Pkg
Pkg.add("DropboxSDK")
```



## Setup

Before you can using this package to access your Dropbox account, you
need to obtain an *authorization token*. This is essentially a
password that allows an application to access your Dropbox account on
your behalf. 

**Note:** A token is like a password; treat it accordingly -- make
sure it never ends up in a repository, on a command line, in log file,
etc.

To obtain an authorization token, go to [this
page](https://www.dropbox.com/developers/apps/create) and follow the
instructions there. You can call the app e.g. `Julia SDK`. You have
the option to "sandbox" the token by restricting it to an app-specific
subdirectory. This is a good idea for testing.

Save the token into a file `.dropboxsdk.http` in your home directory.
The file should look like

```
access_token:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

where the `xxx` are replaced by the authorization token that looks
like a random string of letters and numbers.

Make sure the file is owned by you, and that no one else can read it
(`chmod go-rwx ~/.dropboxsdk.http`). As a security precaution,
`DropboxSDK` will refuse to read the file otherwise.



## Command line client

```sh
julia bin/dbftp.jl help
```

The command line client works similar to `sftp`. (There is no REPL
yet.) These commands are implemented:

- `account`: Display account information
- `cmp`: Compare local and remote files (compare content hashes)
- `du`: Display space usage
- `get`: Download files
- `help`: Get help
- `ls`: List files
- `mkdir`: Create directory
- `put`: Upload files
- `rm`: Delete file or directory
- `version`: Show version number

Note that `rm` can delete non-empty directories. This is a convenient
way to delete large numbers of files in a very short time. Deleted
files can be restored (using e.g. the Dropbox web interface) for some
weeks or months.



## Programming interface

```Julia
using DropboxSDK
```

These API functions are currently supported; see their respective
documentation:

- `files_create_folder`: Create a directory
- `files_delete`: Delete a file or directory (recursively)
- `files_download`: Get a file
- `files_get_metadata`: Get metadata (size etc.) for a file or directory
- `files_list_folder`: List directory content
- `files_upload`: Upload one or more files
- `users_get_current_account`: Get information about the current account
- `users_get_space_usage`: Get used and available space

There are also a few local helper functions:

- `calc_content_hash`: Calculate content hash (fingerprint) of a local
  file
- `get_authorization`: Read credentials from a configuration file

The command line interface and the test cases also contain good
pointers for how to use this API.

Given how the Dropbox API is designed, it seems that Dropbox considers
metadata write operations to be particularly expensive. (These are
operations that modify how a directory looks.) Metadata write
operations are thus strongly rate limited.

For example, running two instances of `dbftp` simultaneously will
almost certainly result in temporary errors and retries. (`DropboxSDK`
detects temporary errors, and retries automatically. However, this
still slows things down.) Dropbox offers special functions to e.g.
upload many files simultaneously. `DropboxSDK` uses these, although
not yet in parallel.

Conversely, metadata read operations (e.g. reading a directory or
downloading a file) seem efficient, and these operations can
presumably run in parallel.
