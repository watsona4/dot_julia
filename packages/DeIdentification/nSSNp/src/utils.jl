"""
	getcurrentdate()

Returns the current date as a string conforming to ISO8601 _basic_ format.

This is used to generate filenames in a cross-platform compatible way.
"""
function getcurrentdate()
	return Dates.format(Dates.now(), "yyyymmddHHMMSS")
end
