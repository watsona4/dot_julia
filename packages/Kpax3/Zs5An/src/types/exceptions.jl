# This file is part of Kpax3. License is MIT.

"""
# Kpax3 Exception

## Description

Provides a message explaining the reason of the DomainError exception.

## Fields

* `msg` Optional argument with a descriptive error string
"""
mutable struct KDomainError <: Exception
  msg::String
end
KDomainError() = KDomainError("")

"""
# Kpax3 Exception

## Description

Exception for a wrong formatted FASTA file.

## Fields

* `msg` Optional argument with a descriptive error string
"""
mutable struct KFASTAError <: Exception
  msg::String
end
KFASTAError() = KFASTAError("")

"""
# Kpax3 Exception

## Description

Exception for a wrong formatted CSV file.

## Fields

* `msg` Optional argument with a descriptive error string
"""
mutable struct KCSVError <: Exception
  msg::String
end
KCSVError() = KCSVError("")

"""
# Kpax3 Exception

## Description

Exception for wrong data read from a source.

## Fields

* `msg` Optional argument with a descriptive error string
"""
mutable struct KInputError <: Exception
  msg::String
end
KInputError() = KInputError("")
