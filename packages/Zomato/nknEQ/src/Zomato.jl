__precompile__(true)

module Zomato

# External Imports
using HTTP
using JSON
import Base: show, @info

# Module Exports
export authenticate, get
export Auth, APIError

# see https://developers.zomato.com/documentation
export CategoriesAPI, CitiesAPI, CollectionsAPI, CuisinesAPI, EstablishmentsAPI, GeocodeAPI
export LocationDetailsAPI, LocationsAPI
export DailymenuAPI, RestaurantAPI, ReviewsAPI, SearchAPI

# ZomatoAPI 
abstract type ZomatoAPI end

# Subtypes for ZomatoAPI
struct CategoriesAPI      <: ZomatoAPI end
struct CitiesAPI          <: ZomatoAPI end
struct CollectionsAPI     <: ZomatoAPI end
struct CuisinesAPI        <: ZomatoAPI end
struct EstablishmentsAPI  <: ZomatoAPI end
struct GeocodeAPI         <: ZomatoAPI end
struct LocationDetailsAPI <: ZomatoAPI end
struct LocationsAPI       <: ZomatoAPI end
struct DailymenuAPI       <: ZomatoAPI end
struct RestaurantAPI      <: ZomatoAPI end
struct ReviewsAPI         <: ZomatoAPI end
struct SearchAPI          <: ZomatoAPI end

# Routes for specific Subtypes
route(::Type{CategoriesAPI})      = "categories"
route(::Type{CitiesAPI})          = "cities"
route(::Type{CollectionsAPI})     = "collections"
route(::Type{CuisinesAPI})        = "cuisines"
route(::Type{EstablishmentsAPI})  = "establishments"
route(::Type{GeocodeAPI})         = "geocode"
route(::Type{LocationDetailsAPI}) = "location_details"
route(::Type{LocationsAPI})       = "locations"
route(::Type{DailymenuAPI})       = "dailymenu"
route(::Type{RestaurantAPI})      = "restaurant"
route(::Type{ReviewsAPI})         = "reviews"
route(::Type{SearchAPI})          = "search"


"""
Zomato Auth
"""
struct Auth
	base_url::String
	header::Dict{String, String}
end

Base.show(io::IO, z::Auth) = print(io, "Zomato(", z.base_url, ')')


"""
Authenticate
-----------
Takes a valid Zomato API Key
"""
function authenticate(api_key::String)
	Auth("https://developers.zomato.com/api/v2.1/", Dict("Accept" => "application/json", "user-key"=> api_key))
end


"""
Zomato API Error
"""
struct APIError <: Exception
	code::Int16
	response::HTTP.Response
end


"""
Get list of categories
---------------------
List of all restaurants categorized under a particular restaurant type can be obtained using /Search API with Category ID as inputs

	See https://developers.zomato.com/documentation#!/common/categories

"""
function get(z::Auth, ::Type{CategoriesAPI})
	@info "fetching categories..."
	helper(z, route(CategoriesAPI), Dict())
end


"""
Get city details
----------------
Find the Zomato ID and other details for a city . You can obtain the Zomato City ID in one of the following ways:

- City Name in the Search Query - Returns list of cities matching the query
- Using coordinates - Identifies the city details based on the coordinates of any location inside a city

If you already know the Zomato City ID, this API can be used to get other details of the city.

	See https://developers.zomato.com/documentation#!/common/cities

Arguments
---------

| Parameter | Description                      | Parameter Type | Data Type |
|:----------|:---------------------------------|:---------------|:----------|
| q         | query by city name               | query          | String    |
| lat       | latitude                         | query          | Float     |
| lon       | longitude                        | query          | Float     |
| city_ids  | comma separated city_id values   | query          | String    |
| count     | number of max results to display | query          | Int       |
"""
function get(z::Auth, ::Type{CitiesAPI}; kwargs...)
	@info "fetching city details..."
	helper(z, route(CitiesAPI), Dict(kwargs))
end


"""
Get zomato collections in a city
--------------------------------
Returns Zomato Restaurant Collections in a City. The location/City input can be provided in the following ways -

- Using Zomato City ID
- Using coordinates of any location within a city

List of all restaurants listed in any particular Zomato Collection can be obtained using the '/search' API with Collection ID and Zomato City ID as the input

	See https://developers.zomato.com/documentation#!/common/collections

Arguments
---------

| Parameter | Description                                     | Parameter Type | Data Type |
|:----------|:------------------------------------------------|:---------------|:----------|
| city_id   | id of the city for which collections are needed | query          | Int       |
| lat       | latitude                                        | query          | Float     |
| lon       | longitude                                       | query          | Float     |
| count     | number of max results to display                | query          | Int       |
"""
function get(z::Auth, ::Type{CollectionsAPI}; kwargs...)
	@info "fetching collections..."
	helper(z, route(CollectionsAPI), Dict(kwargs))
end


"""
Get list of all cuisines in a city
----------------------------------
The location/city input can be provided in the following ways -

- Using Zomato City ID
- Using coordinates of any location within a city

List of all restaurants serving a particular cuisine can be obtained using '/search' API with cuisine ID and location details

	See https://developers.zomato.com/documentation#!/common/cuisines


Arguments
---------

| Parameter | Description                                     | Parameter Type | Data Type |
|:----------|:------------------------------------------------|:---------------|:----------|
| city_id   | id of the city for which cuisines are needed    | query          | Int       |
| lat       | latitude                                        | query          | Float     |
| lon       | longitude                                       | query          | Float     |
"""
function get(z::Auth, ::Type{CuisinesAPI};kwargs...)
	@info "fetching cuisines... "
	helper(z, route(CuisinesAPI), Dict(kwargs))
end


"""
Get list of restaurant types in a city
---------------------------------------

The location/City input can be provided in the following ways -

- Using Zomato City ID
- Using coordinates of any location within a city

List of all restaurants categorized under a particular restaurant type can obtained using /Search API with Establishment ID and location details as inputs

	See https://developers.zomato.com/documentation#!/common/establishments


Arguments
---------

| Parameter | Description                                     | Parameter Type | Data Type |
|:----------|:------------------------------------------------|:---------------|:----------|
| city_id   | id of the city 															    | query          | Int       |
| lat       | latitude                                        | query          | Float     |
| lon       | longitude                                       | query          | Float     |
"""
function get(z::Auth, ::Type{EstablishmentsAPI}; kwargs...)
	@info "fetching establishments..."
	helper(z, route(EstablishmentsAPI), Dict(kwargs))
end


"""
Get location details based on coordinates
-----------------------------------------
Get Foodie and Nightlife Index, list of popular cuisines and nearby restaurants around the given coordinates

	See https://developers.zomato.com/documentation#!/common/geocode

Arguments
---------

| Parameter | Description                                     | Required | Parameter Type | Data Type |
|:----------|:------------------------------------------------|:---------|:---------------|:----------|
| lat       | latitude                                        | yes      | query          | Float     |
| lon       | longitude                                       | yes      | query          | Float     |

"""
function get(z::Auth, ::Type{GeocodeAPI}; kwargs...)
	@info "fetching geocode..."
	helper(z, route(GeocodeAPI), Dict(kwargs))
end


"""
Get zomato location details
---------------------------
Get Foodie Index, Nightlife Index, Top Cuisines and Best rated restaurants in a given location

	See https://developers.zomato.com/documentation#!/location/location_details

Arguments
---------

| Parameter   | Description                                     | Required | Parameter Type | Data Type |
|:------------|:------------------------------------------------|:---------|:---------------|:----------|
| entity_id   | location id obtained from locations api         | yes      | query          | Int       |
| entity_type | location type obtained from locations api       | yes      | query          | String    |
"""
function get(z::Auth, ::Type{LocationDetailsAPI}; kwargs...)
	@info "fetching location details..."
	helper(z, route(LocationDetailsAPI), Dict(kwargs))
end


"""
Search for locations
--------------------
Search for Zomato locations by keyword. Provide coordinates to get better search results

	See https://developers.zomato.com/documentation#!/location/locations

Arguments
---------

| Parameter   | Description                               | Required | Parameter Type | Data Type |
|:------------|:------------------------------------------|:---------|:---------------|:----------|
| query       | suggestion for location name              |          | query          | String    |
| lat         | latitude                                  | yes      | query          | Float     |
| lon         | longitude                                 | yes      | query          | Float     |
| count       | number of max results to display          |          | query          | Int       |
"""
function get(z::Auth, ::Type{LocationsAPI}; kwargs...)
	@info "fetching locations..."
	helper(z, route(LocationsAPI), Dict(kwargs))
end


"""
Get daily menu of a restaurant
------------------------------
Get daily menu using Zomato restaurant ID.

	See https://developers.zomato.com/documentation#!/restaurant/restaurant

Arguments
---------

| Parameter   | Description                                  | Required | Parameter Type | Data Type |
|:------------|:---------------------------------------------|:---------|:---------------|:----------|
| res_id      | id of restaurant whose details are requested | yes      | query          | Int       |
"""
function get(z::Auth, ::Type{DailymenuAPI}; kwargs...)
	@info "fetching dailymenu..."
	helper(z, route(DailymenuAPI), Dict(kwargs))
end


"""
Get restaurant details
----------------------
Get detailed restaurant information using Zomato restaurant ID. Partner Access is required to access photos and reviews.

	See https://developers.zomato.com/documentation#!/restaurant/restaurant_0

Arguments
---------

| Parameter   | Description                                  | Required | Parameter Type | Data Type |
|:------------|:---------------------------------------------|:---------|:---------------|:----------|
| res_id      | id of restaurant whose details are requested | yes      | query          | Int       |
"""
function get(z::Auth, ::Type{RestaurantAPI}; kwargs...)
	@info "fetching restaurant details..."
	helper(z, route(RestaurantAPI), Dict(kwargs))
end


"""
Get restaurant reviews
----------------------
Get restaurant reviews using the Zomato restaurant ID. Only 5 latest reviews are available under the Basic API plan.

	See https://developers.zomato.com/documentation#!/restaurant/reviews

Arguments
---------

| Parameter   | Description                                  | Required | Parameter Type | Data Type |
|:------------|:---------------------------------------------|:---------|:---------------|:----------|
| res_id      | id of restaurant whose details are requested | yes      | query          | Int       |
| start       | fetch results after this offset              | yes      | query          | Int       |
| count       | number of max results to display             |          | query          | Int       |
"""
function get(z::Auth, ::Type{ReviewsAPI}; kwargs...)
	@info "fetching restaurant reviews..."
	helper(z, route(ReviewsAPI), Dict(kwargs))
end


"""
Search Zomato Restaurants
-------------------------
The location input can be specified using Zomato location ID or coordinates. Cuisine / Establishment / Collection IDs can be obtained from respective api calls. Get up to 100 restaurants by changing the 'start' and 'count' parameters with the maximum value of count being 20. Partner Access is required to access photos and reviews.
Examples:

- To search for 'Italian' restaurants in 'Manhattan, New York City', set cuisines = 55, entity_id = 94741 and entity_type = zone
- To search for 'cafes' in 'Manhattan, New York City', set establishment_type = 1, entity_type = zone and entity_id = 94741
- Get list of all restaurants in 'Trending this Week' collection in 'New York City' by using entity_id = 280, entity_type = city and collection_id = 1

	See https://developers.zomato.com/documentation#!/restaurant/search

"""
function get(z::Auth, ::Type{SearchAPI}; kwargs...)
	@info "searching restaurants..."
	helper(z, route(SearchAPI), Dict(kwargs))
end


"""
HTTP Helper
"""
function helper(z::Auth, path::String, d::Dict)
	try
		query = query_builder(d)
		response = HTTP.get(z.base_url * "$path?" * query, z.header)
		return JSON.parse(String(response.body))
	catch error_response
		throw(APIError(error_response.status, error_response.response))
	end
end


"""
Query Builder
"""
function query_builder(kwargs::Dict)
	query = ""
	for item in kwargs
		query *= "&$(item[1])=" * string(item[2])
	end
	return query
end


end # module
