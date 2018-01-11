require "rubygems"
require "json"
require "open-uri"
require "google/apis"
require "google/apis/youtube_v3"
require "googleauth"
require "googleauth/stores/file_token_store"

API_URL = "https://reddit.com/r/youtubehaiku/.json"
PAGES = 10

APPLICATION_NAME = "haikubot"
SECRETS_PATH = "./secrets.json"
CREDENTIALS_PATH = "haikubot_credentials"
REDIRECT_URI = "http://localhost"
SCOPE = Google::Apis::YoutubeV3::AUTH_YOUTUBE

def fetch_ids()
    ids = []

    cur_url = API_URL

    PAGES.times { |_|
        fetched = open(cur_url,
            "User-Agent" => "Ruby/#{RUBY_VERSION}",
        )

        hash = JSON.load(fetched)

        last = ""

        hash["data"]["children"].each { |child|
            next if child["data"]["stickied"]
            url = child["data"]["url"]
            last = child["data"]["name"]
            next unless url =~ /^https?:\/\/(?:(?:(?:www\.)?youtube\.com\/watch\?v\=)|(?:youtu\.be\/))([A-Za-z0-9_\-]{11})/
            ids.push $1
        }

        cur_url = API_URL + "?after=#{last}"
    }

    ids
end

def authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = ""
    credentials = authorizer.get_credentials(user_id)
    
    if credentials.nil?
        url = authorizer.get_authorization_url(base_url: REDIRECT_URI)
        puts "Open the following URL in the browser and enter the resulting code after authorization"
        puts url
        code = gets
        credentials = authorizer.get_and_store_credentials_from_code(
            user_id: user_id, code: code, base_url: REDIRECT_URI
        )
    end
    
    credentials
end

def create_service
    service = Google::Apis::YoutubeV3::YouTubeService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
    service
end

def create_resource(properties)
    resource = {}
    properties.each { |prop, value|
        ref = resource
        prop_array = prop.to_s.split(".")
        for p in 0..(prop_array.size - 1)
            is_array = false
            key = prop_array[p]
            # For properties that have array values, convert a name like
            # "snippet.tags[]" to snippet.tags, but set a flag to handle
            # the value as an array.
            if key[-2,2] == "[]"
                key = key[0...-2]
                is_array = true
            end
            if p == (prop_array.size - 1)
                if is_array
                    if value == ""
                    ref[key.to_sym] = []
                    else
                    ref[key.to_sym] = value.split(",")
                    end
                elsif value != ""
                    ref[key.to_sym] = value
                end
            elsif ref.include?(key.to_sym)
                ref = ref[key.to_sym]
            else
                ref[key.to_sym] = {}
                ref = ref[key.to_sym]
            end
        end
    }
    return resource
end

def create_playlist(service, title, description)
    resource = create_resource({
        "snippet.title": title,
        "snippet.description": description
    })
    service.insert_playlist("snippet", resource, {}).id
end

def add_to_playlist(service, playlist_id, video_id)
    resource = create_resource({
        "snippet.playlist_id": playlist_id,
        "snippet.resource_id.kind": "youtube#video",
        "snippet.resource_id.video_id": video_id
    })
    service.insert_playlist_item("snippet", resource, {})
end


puts "Fetching top #{PAGES} pages of content from /r/youtubehaiku..."
ids = fetch_ids

puts "Authenticating with YouTube API..."
service = create_service

timestamp = Time.now.strftime "%Y%m%d_%H%M%S"
playlist_name = "haikubot_#{timestamp}"

puts "Creating playlist #{playlist_name}"
playlist = create_playlist(service, "#{playlist_name}", "Auto-generated playlist of top videos from /r/youtubehaiku.")

puts "Adding videos to playlist..."
ids.each { |id |
    begin
        add_to_playlist(service, playlist, id)
    rescue => e
        puts "Failed to add video ID #{id} to playlist."
        puts e
    end
}

puts "Done!"
