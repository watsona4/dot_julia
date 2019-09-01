"""
T Macrina
160310

Change to directory with the following files:
* segmentation.h5
* classification.csv
* class_description.csv

Run
`julia semantic.jl`
"""

using HDF5

"""
`CREATE_SEMANTIC_MASK` - create indexed image for semantic class of every voxel

Args:

* indexed_matrix: matrix indexed with segment IDs
* segment_class: dictionary, keys are segment IDs, values are the class 
* uncertain_id: class index for a segment ID that was not classified

Returns:

* semantic_mask: matrix indexed with class IDs
"""
function create_semantic_mask(indexed_matrix, segment_class, uncertain_id=0)
	semantic_mask = ones(UInt8, size(indexed_matrix)...)
	for i in 1:length(indexed_matrix)
		k = indexed_matrix[i]
		if haskey(segment_class, k)
			semantic_mask[i] = UInt8(segment_class[k])
		else
			semantic_mask[i] = uncertain_id
		end
	end
	return semantic_mask
end

"""
`CHECK_SEGMENT_IDS` - Check that all segments have been classified
"""
function check_segment_ids(indexed_matrix, segment_class)
	segments_marked = Set(unique(indexed_matrix))
	segments_classified = Set(keys(segment_class))
	println("Marked but not classified: ", length(setdiff(segments_marked, 
														segments_classified)))
	println("Classified but not marked: ", length(setdiff(segments_classified, 
															segments_marked)))
	return assert(Set(segment_ids) == Set(keys(segment_class)))
end

"""
`WRITE_SEMANTIC_MASK` - create indexed image for semantic class of every voxel

Args:

* dir: path to the folder containing the following files
** segmentation.h5: the segment indexed volume with attribute "main"
** classification.csv: 2 column table - segment id, class id
** class_description.csv: 2 column table - class id, class description

Returns:

Writes out H5 file, semantic_mask - class id indexed image
* "main": matrix indexed with class ids &
* "class_id": table of class ids
* "class_description": table of class descriptions (match class ids)
"""
function write_semantic_mask(dir)
	segmentation_fn = joinpath(dir, "segmentation.h5")
	classification_fn = joinpath(dir, "classification.csv")
	class_description_fn = joinpath(dir, "class_description.csv")
	semantic_mask_fn = joinpath(dir, "semantic_mask.h5")

	indexed_matrix = h5read(segmentation_fn, "main")
	segment_class = convert_table_to_dict(readdlm(classification_fn, Int))
	semantic_mask = create_semantic_mask(indexed_matrix, segment_class)
	classes = readdlm(class_description_fn)
	class_id = map(UInt8, classes[:,1])
	class_description = map(String, classes[:,2])

    f = h5open(semantic_mask_fn, "w")
    f["main"] = semantic_mask
    f["class_id"] = class_id
    f["class_description"] = class_description
    close(f)
end

function convert_table_to_dict(table)
	d = Dict()
	for i in 1:size(table,1)
		d[table[i,1]] = table[i,2]
	end
	return d
end

if !isinteractive()
	write_semantic_mask(pwd())
end