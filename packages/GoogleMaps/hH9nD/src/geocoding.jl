
function geocode(address::String)
    url = "https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$(ENV["GOOGLE_MAPS_KEY"])"
    response = HTTP.get(url)
    return(JSON.parse(String(response.body)))
end
