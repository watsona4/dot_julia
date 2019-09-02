"""
    reference(d::MangalDataset)

Returns the `MangalReference` associated to a `MangalDataset`. This is a
convenience function that returns the `reference` field of the dataset.
"""
function reference(d::MangalDataset)
    return d.reference
end
