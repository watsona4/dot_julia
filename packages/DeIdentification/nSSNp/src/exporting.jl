
"""
    write_dicts(deid_dicts)

Writes DeIdDicts structure to file. The dictionaries are written to josn. The
files are written to the  `output_path` specified in the configuration YAML.
"""
function write_dicts(deid::DeIdDicts, logger, outdir)

    currentdate = getcurrentdate()

    idfile = joinpath(outdir, "id_dicts_" * currentdate * ".json")
    Memento.info(logger, "$(Dates.now()) Writing ID dictionaries to $(idfile)")
    write(idfile, JSON.Writer.json(deid.id, 4))

    dateshift_file = joinpath(outdir, "dateshifts_" * currentdate * ".json")
    Memento.info(logger, "$(Dates.now()) Writing dateshift values to $(dateshift_file)")
    write(dateshift_file, JSON.Writer.json(deid.dateshift, 4))

    saltfile = joinpath(outdir, "salts_" * currentdate * ".json")
    Memento.info(logger, "$(Dates.now()) Writing salt values to $(saltfile)")
    write(saltfile, JSON.Writer.json(deid.salt, 4))

    return nothing
end
