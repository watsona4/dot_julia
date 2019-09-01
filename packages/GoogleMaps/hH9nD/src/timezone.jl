
function timezone(location::Tuple{Float64,Float64}, timestamp::DateTime=now())
    lat, lng = location
    timestamp = convert(BigInt, trunc(datetime2unix(timestamp))*big(1))
    url = "https://maps.googleapis.com/maps/api/timezone/json?location=$lat,$lng&timestamp=$timestamp&key=$(ENV["GOOGLE_MAPS_KEY"])"
    response = HTTP.get(url)
    return(JSON.parse(String(response.body)))
end
