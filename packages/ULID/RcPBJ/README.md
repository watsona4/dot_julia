# ULID.jl

[![Build Status](https://travis-ci.org/ararslan/ULID.jl.svg?branch=master)](https://travis-ci.org/ararslan/ULID.jl)
[![Coverage Status](https://coveralls.io/repos/github/ararslan/ULID.jl/badge.svg)](https://coveralls.io/github/ararslan/ULID.jl)

This package provides the ability to generate Alizain Feerasta's Universally Unique Lexicographically
Sortable Identifiers (ULID) in Julia.
It's based on the original MIT-licensed [JavaScript implementation](https://github.com/alizain/ulid).
More information about ULIDs is available in the linked repository.

## Functions

One function is exported: `ulid`.
Calling `ulid()` will generate a random 26-character ULID as a `String`.
