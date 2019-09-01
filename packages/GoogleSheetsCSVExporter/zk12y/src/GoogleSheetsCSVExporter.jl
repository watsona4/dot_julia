module GoogleSheetsCSVExporter

import HTTP

struct Sheet
	documentID
	gid
end

function parseURI(uri::HTTP.URI)
	documentID = split(uri.path, "/")[4]
	fragmentParams = uri.fragment |> HTTP.queryparams
	Sheet(documentID, fragmentParams["gid"])
end

function exportURI(sheet::Sheet)
	"https://docs.google.com/spreadsheets/d/$(sheet.documentID)/export?format=csv&gid=$(sheet.gid)"
end

function openURI(uri::String)
	let str
		HTTP.open("GET", uri) do http
			str = read(http, String)
		end
		str
	end
end

function fromURI(uri::String)
	HTTP.URI(uri) |> parseURI |> exportURI |> openURI |> IOBuffer
end

end # GoogleSheetsCSVExporter
