"""
	REDCap.Config(url::String, key::String; ssl::Bool = true)

Struct to hold api url and key/superkey.
`APIConfigObj = Config("http...","ABCD...")`

This will be passed to all function calls to both orient and authorize the api_pusher() function. The REDCap API cannot
be accessed without this config object properly set-up. Always test your config object before automating a project. 

#### NOTE: SSL should always be on by default.
If for whatever reason, your project will not SSL verify AND you must use it, disable ssl verification with `ssl=false`
Leaving SSL verification disabled leaves you open for Man-in-the-Middle attacks and is generally just bad practice.

#### Parameters:
* `url` - The url of the REDCap instance.
* `key` - Either the standard or super API key.
* `ssl` - Flag to enable ssl verification
"""
struct Config
	url::String
	key::String
	ssl::Bool
	#basic validation - checks that the url starts and ends 'properly', and then checks the key length
	function Config(url::String, key::String; ssl::Bool = true)
		if isequal(url[end-4:end], "/api/") && (isequal(url[1:7], "http://") || isequal(url[1:8], "https://"))
			if (length(key)==32 || length(key)==64)
				new(url, key, ssl)
			else
				@error("Invalid Key: $key \nMust be 32 characters long for a standard key, or 64 characters long for a super key.")
			end
		else
			@error("Invalid URL: $url \nMust be in format of http(s)://<redcap-hosting-url>/api/")
		end
	end
end