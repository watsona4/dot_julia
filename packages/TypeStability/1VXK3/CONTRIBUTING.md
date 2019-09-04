# Contributing to TypeStability.jl

Thank you for your interest in contributing to TypeStability.jl.

## Create a Issue

Use the [Github Issues page](https://github.com/Collegeville/TypeStability.jl/issues) to create issues.  Issues can be created for reporting bugs, suggesting enhancements, ect.  Please provide as much relavant information as you can, included expected behavior, current behavior, a reproducable example, your version of Julia, ect.

## Making Changes

See the [Julia manual](https://docs.julialang.org/en/v0.6.4/manual/packages/#Making-changes-to-an-existing-package-1) for detailed instructions on making changes.  The overall process, from the Julia prompt, should be

```Julia
Pkg.checkout("TypeStability")    # check out the master branch
<make sure the issue hasn't been resolved>
cd(Pkg.dir("TypeStability"))
;git checkout -b <branchname>    # create a branch for your changes
<edit code>                      # be sure to add a test for your bug
Pkg.test("TypeStability")        # make sure everything works now
;git commit -a                   # Commit the changes
using PkgDev
PkgDev.submit("TypeStability")
```

This will bring up a prompt to describe the pull request, please describe the changes made and link any relavant issues or other information.  Feel free to break large changes into multiple, logical commits.  If modifications are needed once the pull request is created, use the following process from the Julia prompt:

```Julia
Pkg.checkout("TypeStability", "<branchname>")  # check out the feature branch
<make modifications>
Pkg.test("TypeStability")                      # make sure there wasn't a bug introduced
;git commit -a                                 # commit the additional changes
;git push                                      # push the modifications to your fork
```

The traditional Github fork, clone, pull request process can also be used instead of the Julia interface.
