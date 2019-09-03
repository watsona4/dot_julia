<!-- Beginning of file -->

# Contributing to PredictMDExtra

This document provides information on contributing to the
PredictMDExtra source code. For information on installing and using
PredictMDExtra, please see [README.md](README.md).

<table>
    <thead>
        <tr>
            <th>Table of Contents</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td align="left">
                <a href="#1-prerequisites">1. Prerequisites
                </a>
            </td>
        </tr>
        <tr>
            <td align="left">
                <a href="#2-setting-up-the-predictmdextra-repo">
                    2. Setting up the PredictMDExtra repo
                </a>
            </td>
        </tr>
        <tr>
            <td align="left">
                <a href="#appendix-a-information-for-package-maintainers">
                    Appendix A: Information for package maintainers
                </a>
            </td>
        </tr>
    </tbody>
</table>

## 1. Prerequisites

You need to have a GitHub account (with two-factor authentication enabled).
You also need to have the following tools installed and configured:
- git (with SSH public key authentication)
- git-flow
- GPG

### 1.1 GitHub account

#### Step 1:
If you already have a GitHub account, go to
[https://github.com/login](https://github.com/login) and log in.
If you do not already have a GitHub account, go to
[https://github.com/join](https://github.com/join) and create an account.

#### Step 2:
Go to [https://help.github.com/articles/configuring-two-factor-authentication-via-a-totp-mobile-app/](https://help.github.com/articles/configuring-two-factor-authentication-via-a-totp-mobile-app/)
and follow the instructions to enable two-factor
authentication for your GitHub account.

### 1.2 git

#### Step 1:
Open a terminal window and run the following command:
```bash
git --version
```

You should see a message that looks something like this:
```
git version 2.16.1
```

If you do, proceed to Step 2. If you instead receive an error message,
download and install Git:

- macOS: [https://git-scm.com/download/mac](https://git-scm.com/download/mac)
- GNU/Linux: [https://git-scm.com/download/linux](https://git-scm.com/download/linux)

#### Step 2:
```bash
git config --global user.name "Myfirstname Mylastname"
```

#### Step 3:
```bash
git config user.email "myemailaddress@example.com"
```

#### Step 4:

```bash
git config --global github.user mygithubusername
```

#### Step 5:
Follow the steps on each of the following pages in order to
generate an SSH key and associate it with your GitHub account:
1. [https://help.github.com/articles/checking-for-existing-ssh-keys/](https://help.github.com/articles/checking-for-existing-ssh-keys/)
2. [https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)
3. [https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/)
4. [https://help.github.com/articles/testing-your-ssh-connection/](https://help.github.com/articles/testing-your-ssh-connection/)
5. [https://help.github.com/articles/working-with-ssh-key-passphrases/](https://help.github.com/articles/working-with-ssh-key-passphrases/)

### 1.3 git-flow

#### Step 1:
Open a terminal window and run the following command:
```bash
git flow
```

You should see a message that looks something like this:
```
usage: git flow <subcommand>

Available subcommands are:
   init      Initialize a new git repo with support for the branching model.
   feature   Manage your feature branches.
   release   Manage your release branches.
   hotfix    Manage your hotfix branches.
   support   Manage your support branches.
   version   Shows version information.

Try 'git flow <subcommand> help' for details.
```
If you do, then you are good to go. If you instead receive the
message ```git: 'flow' is not a git command```, download and
install git-flow:

- macOS: [https://github.com/nvie/gitflow/wiki/Mac-OS-X](https://github.com/nvie/gitflow/wiki/Mac-OS-X)
- GNU/Linux: [https://github.com/nvie/gitflow/wiki/Linux](https://github.com/nvie/gitflow/wiki/Linux)


### 1.4 GPG

#### Step 1:
Open a terminal window and run the following command:
```bash
gpg --version
```

You should see a message that looks something like this:
```
gpg (GnuPG/MacGPG2) 2.2.3
libgcrypt 1.8.1
Copyright (C) 2017 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Home: /Users/dilum/.gnupg
Supported algorithms:
Pubkey: RSA, ELG, DSA, ECDH, ECDSA, EDDSA
Cipher: IDEA, 3DES, CAST5, BLOWFISH, AES, AES192, AES256, TWOFISH,
        CAMELLIA128, CAMELLIA192, CAMELLIA256
Hash: SHA1, RIPEMD160, SHA256, SHA384, SHA512, SHA224
Compression: Uncompressed, ZIP, ZLIB, BZIP2
```
If you do, then go to Step 2. If you instead see an error,
download and install GPG:
- macOS: [https://gpgtools.org/](https://gpgtools.org/)
- GNU/Linux: [https://gnupg.org/download/#sec-1-2](https://gnupg.org/download/#sec-1-2)

#### Step 2:
Follow the steps on each of the following pages in order to
generate a GPG key and associate it with your GitHub account:
1. [https://help.github.com/articles/checking-for-existing-gpg-keys/](https://help.github.com/articles/checking-for-existing-gpg-keys/)
2. [https://help.github.com/articles/generating-a-new-gpg-key/](https://help.github.com/articles/generating-a-new-gpg-key/)
3. [https://help.github.com/articles/adding-a-new-gpg-key-to-your-github-account/](https://help.github.com/articles/adding-a-new-gpg-key-to-your-github-account/)
4. [https://help.github.com/articles/telling-git-about-your-gpg-key/](https://help.github.com/articles/telling-git-about-your-gpg-key/)
5. [https://help.github.com/articles/associating-an-email-with-your-gpg-key/](https://help.github.com/articles/associating-an-email-with-your-gpg-key/)

## 2. Setting up the PredictMDExtra repo

#### Step 1:
Make sure that you have followed all of the instructions
in [Section 1 (Prerequisites)](#1-prerequisites).

#### Step 2:
Open Julia and run the following lines:
```julia
import Pkg
p = Pkg.PackageSpec(
	name="PredictMDExtra",
	url="https://github.com/bcbi/PredictMDExtra.jl",
	uuid="d14d998a-9e6b-11e8-16d3-6f2879ea456d",
	)
Pkg.develop(p)
```

#### Step 3:
Open a terminal window and `cd` to the directory
containing the PredictMDExtra source code:

```bash
cd ~/.julia/dev/PredictMDExtra
```

#### Step 4:
Run the following lines:

```bash
git config commit.gpgsign true &&
git remote set-url origin https://github.com/bcbi/PredictMDExtra.jl.git &&
git remote set-url --push origin git@github.com:bcbi/PredictMDExtra.jl.git &&
git checkout master &&
git checkout develop &&
git flow init -fd &&
git checkout develop &&
git fetch --all --prune
```

## Appendix A: Information for package maintainers

### A.1. How to tag a new release using git-flow

**IMPORTANT: Before you tag a new release, make sure that
your GPG set-up is working.
Release tags MUST be signed with your GPG key.**

#### Step 1:
Open a terminal window and `cd` to the directory containing the PredictMDExtra source code:

```bash
cd ~/.julia/dev/PredictMDExtra
```

#### Step 2:
Fetch the latest versions of all branches:

```bash
git fetch --all --prune
```

#### Step 3:
Checkout the `master` branch:

```bash
git checkout master
```

#### Step 4:
Pull the latest version of `master`.

```bash
git pull
```

#### Step 5:
Checkout the `develop` branch:

```bash
git checkout develop
```

#### Step 6:
Pull the latest version of `develop`.

```bash
git pull
```

#### Step 7:
Determine the version number that you are going to
release. We use the Semantic Versioning
system: [https://semver.org](https://semver.org). In Semantic
Versioning, version numbers take the form `vMAJOR.MINOR.PATCH`.
We increment the `MAJOR` version when we make incompatible
(non-backwards-compatible) API changes. We increment the `MINOR`
version when we add functionality in a backwards-compatible manner.
We increment the `PATCH` version when we make
backwards-compatible bug fixes.

For this example, let's pretend that the current version
is `v3.5.12` and that we are adding functionality in a
backwards-compatible manner. So we increment the `MINOR` version,
which means the new version that we are tagging is `v3.6.0`.

#### Step 8:
Start a new release branch.

```bash
git flow release start v3.6.0
```

**You MUST begin the name of the release with the letter "v".**

*If you subsequently forget what you named your release branch,
you can list all of the release branches by running the following
command:* `git flow release list`

#### Step 9:
Open the file `Project.toml` and change the version number
on line 4. For example, if line 4 of `Project.toml` looks
like this:

```julia
version = "THE OLD VERSION NUMBER WILL BE HERE"
```

Then you would edit line 4 to look like this:

```julia
version = "3.6.0"
```

**Only change line 4 of `Project.toml`
(the line that begins with `version =`.
Do not change any of the other lines.**

#### Step 10:
Commit your changes:

```bash
git add Project.toml

git commit
```
An commit message editor will open. Type an appropriate commit
message (e.g. "Bump version number"), save the file, and quit the
editor.

#### Step 11:

Run the PredictMDExtra test suite on your local machine:

```bash
julia --project -e 'import Pkg; Pkg.instantiate(); Pkg.build("PredictMDExtra"); Pkg.test("PredictMDExtra");'
```

If you receive the message "Testing PredictMDExtra tests passed", then the
tests passed.

If you do not receive that message, then one or more of the tests failed.

**You may not proceed to the next step until all of the tests pass on your
local machine.**

#### Step 12:
Push the release branch to GitHub.

```bash
git push origin release/v3.6.0
```

#### Step 13:
Wait for all of the continuous integration (CI) tests to pass. You can
check on the status of the CI tests by going to
[https://github.com/bcbi/PredictMDExtra.jl/branches/yours](https://github.com/bcbi/PredictMDExtra.jl/branches/yours)
and scrolling down to find your release branch.

* A yellow dot indicates that the CI tests are still running. Click on the
yellow dot to see which tests are still running.
* A red "X" indicates that one or more of the CI tests failed. Click on the
red "X" to see which tests failed.
* A green check mark indicates that all of the CI tests passed.

**You must wait for all of the CI tests to pass (green check mark) before
you can continue.**

*Sometimes, one of the CI tests will fail because a download timed out.
This is especially common with Travis CI on Mac. You can usually
resolve this error by restarting the failed build.*

#### Step 14:
Once all of the tests have passed, you can finish
tagging your release using the git-flow tools:


```bash
git flow release finish -s v3.6.0
```

*You MUST include the `-s` flag, because this is how you tell git-flow
to sign the release tag with your GPG key. The "s" is lowercase.*

Several commit message editors will open, one after the other. Some of
them will have the correct commit message already filled in, e.g.
"Merge branch ... into branch ...". In those cases, simply save the
file, and quit the editor. One of the editors, however, will ask you
to enter the message for the tag `v3.6.0`. In this editor, enter a
reasonable release message (e.g. "PredictMDExtra version 3.6.0"), save
the file, and close the editor.

Once you have finished all of the commits and tags, you must verify
that you have correctly signed the release tag:

#### Step 15:
Verify that you have correctly signed the release tag:
```bash
git tag -v v3.6.0
```

If you see a message similar to this:
```
gpg: Signature made Thu May 24 13:56:48 2018 EDT
gpg:                using RSA key 36666C5CF81D90773604A1208CF0AA45DD38E4A0
gpg: Good signature from "Dilum Aluthge <dilum@aluthge.com>" [ultimate]
```

then you have successfully signed the release, and you may proceed
to the next step. However, if you see a different message, then you have
not signed the tag successfully, and you may NOT proceed. At this
point, you should
[open a new issue](https://github.com/bcbi/PredictMD.jl/issues/new)
and mention [@DilumAluthge](https://github.com/DilumAluthge) in the
issue body.

#### Step 16:
Temporarily modify the branch protections for
the `master` and `develop` branches:

First, the `master` branch: go to
[https://github.com/bcbi/PredictMDExtra.jl/settings/branches](https://github.com/bcbi/PredictMDExtra.jl/settings/branches), scroll down, click the "Edit" button in the `master` row, scroll down, UNCHECK the box next to "Include administrators", scroll
to the bottom of the page, and click the green "Save changes" button.
You may be asked to enter your GitHub password.

Now do the same thing for the `develop` branch: go to
[https://github.com/bcbi/PredictMDExtra.jl/settings/branches](https://github.com/bcbi/PredictMDExtra.jl/settings/branches), scroll down, click the "Edit" button in the `develop` row, scroll down, UNCHECK the box next to "Include administrators", scroll
to the bottom of the page, and click the green "Save changes" button.
You may be asked to enter your GitHub password.

#### Step 17:
Push the new release to GitHub:

```bash
git push origin master # push the updated "master" branch
git push origin develop # push the updated "develop" branch
git push origin --tags # push the newly created tag
```

#### Step 18:
Create a release on GitHub using the tag you just
created, signed, and pushed. First, go to
[https://github.com/bcbi/PredictMDExtra.jl/releases/new](https://github.com/bcbi/PredictMDExtra.jl/releases/new).
In the text box that reads "Tag version", type the name of the tag you
just released. For our example, you would type "v3.6.0". Next, in the
text box that reads "Release title", type an appropriate title, such
as "PredictMDExtra version 3.6.0". Finally, click the green
"Publish release" button.

#### Step 19:
Update the version number in the `develop` branch:

First, use Semantic Versioning ([https://semver.org](https://semver.org))
determine what the next version number will be. In our example, we have
just released `v3.6.0`. If we are planning on our next release being be
backwards compatible, then the next version number will be `v3.7.0`. In
contrast, if we are planning that the next release will be breaking
(non-backwards-compatible), then the next version number will
be `v4.0.0`.

Second, append "-DEV" to the end of the version number. So if the
next version number will be `v3.7.0`, then you should set the
current version number to `v3.7.0-DEV`. In contrast, if the next
version number will be `v4.0.0`, the you should set the current
version number to `v4.0.0-DEV`.

Third, checkout and pull the `develop` branch:
```bash
git checkout develop
git pull
```

Fourth, open the `Project.toml` file and edit line 4
accordingly. For example, to set the version number
to `v3.7.0-DEV`, edit line 4 to be the following:
```julia
version = "3.7.0-DEV"
```

On the other hand, to set the version number to `v4.0.0-DEV`,
edit line 4 of `Project.toml` to be the following:
```julia
version = "4.0.0-DEV"
```

**As before, only change line 4 of `Project.toml`
(the line that begins with `version =`.
Do not change any of the other lines.**

#### Step 20:
Commit your changes:

```bash
git add Project.toml

git commit
```
An commit message editor will open. Type an appropriate commit
message (e.g. "Bump version number"), save the file, and quit
the editor.

#### Step 21:
Push the updated develop branch:
```bash
git push origin develop
```

#### Step 22:
Re-enable the branch protection settings:

`master` branch: go to
[https://github.com/bcbi/PredictMDExtra.jl/settings/branches](https://github.com/bcbi/PredictMDExtra.jl/settings/branches), scroll down, click the "Edit" button in the `master` row, scroll down, CHECK the box next to "Include administrators", scroll
to the bottom of the page, and click the green "Save changes" button.
You may be asked to enter your GitHub password.

`develop` branch: go to
[https://github.com/bcbi/PredictMDExtra.jl/settings/branches](https://github.com/bcbi/PredictMDExtra.jl/settings/branches), scroll down, click the "Edit" button in the `develop` row, scroll down, CHECK the box next to "Include administrators", scroll
to the bottom of the page, and click the green "Save changes" button.
You may be asked to enter your GitHub password.

#### Step 23:
Delete the release branch, which is no longer needed. To do
this, go to
[https://github.com/bcbi/PredictMDExtra.jl/branches/yours](https://github.com/bcbi/PredictMDExtra.jl/branches/yours),
scroll down to find the release branch, and then click the
trash can icon to delete the branch.

#### Step 24:

Tag the new release with [BCBIRegistry](https://github.com/bcbi/BCBIRegistry). Instructions are available here: [https://github.com/bcbi/BCBIRegistry/blob/master/CONTRIBUTING.md](https://github.com/bcbi/BCBIRegistry/blob/master/CONTRIBUTING.md)

TODO: Add instructions for registering in the General registry with Registrator.jl.

Congratulations, you are finished!

<!-- End of file -->
