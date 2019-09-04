using PyCall


try
    pyimport("visualdl")
    # See if it works already
catch ee
    typeof(ee) <: PyCall.PyError || rethrow(ee)
    error("""
    Python VisualDL not installed.
    Please run `pip install visualdl` and try again.
    """)
end