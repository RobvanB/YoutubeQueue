class YoutubeQueue

  require 'rubygems'
  require 'google/apis'
  require 'google/apis/youtube_v3'
  require 'googleauth'
  require 'googleauth/stores/file_token_store'
  require 'fileutils'
  require 'json'
  # Copilot-authored: Begin timestamp and video sync changes.
  require 'time'

  # VALID REDIRECT_URI FOR YOUR CLIENT
  #REDIRECT_URI        = 'http://localhost:3000/set_token'

  APPLICATION_NAME    = 'YoutubeQueue'
  # NAME/LOCATION OF YOUR client_secrets.json FILE
  CLIENT_SECRETS_PATH = 'client_secret_Oauth2_Ruby.json'
  # WHERE CREDENTIALS WILL BE STORED
  USER_TOKEN_FILE    = File.join('.credentials',"YoutubeQueue.yaml")

  # SCOPE FOR WHICH THIS SCRIPT REQUESTS AUTHORIZATION
  SCOPE = Google::Apis::YoutubeV3::AUTH_YOUTUBE_FORCE_SSL

  def initialize
    # Initialize the API
    @service = Google::Apis::YoutubeV3::YouTubeService.new
    @service.client_options.application_name = APPLICATION_NAME
    #@service.authorization = authorize
    @new_lastcheck_date = Time.now.utc.strftime("%Y-%m-%dT%H:%M:00Z")
    @vid_counter = 0
    @found_counter = 0
    @duplicate_counter = 0
    @sub_counter = 0
  end

  def get_videos(credentials)
    @service.authorization = credentials
    # Get the last time the videos were pulled
    ytq_param = YtqParam.first  # There will be/should be only 1 record
    if ytq_param.nil? || ytq_param.last_date.blank?
      last_check_date = '2018-08-10T00:00:00Z'  #'2018-08-10T00:00:00Z' Initial start date
    else
      last_check_date = Time.parse(ytq_param.last_date).utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    end
    #byebug
    #Do the seach for each channel I'm subscribed to
    
    subscriptions = get_subscriptions

    if subscriptions.is_a?(Hash) && subscriptions[:type] == "error"
      return subscriptions
    end

    @sub_counter = subscriptions.length
    len_array = %w[medium long]
    len_array.each do |len|
      subscriptions.each do | sub |
        sub_channel_id    = sub.snippet.resource_id.channel_id
        #byebug
        # Ignore stupid ass shorts. videoType 'episode' does not work.
        # So we will just pull the 'medium' and 'long' videos
      	#new_videos = search_list_by_keyword(@service,
	#				'snippet',
	#				max_results:50,
	#				channel_id:sub_channel_id,
	#				published_after:last_check_date,
	#				type:'video',
	#				videoType:'episode')
      	new_videos = search_list_by_keyword(@service,
					'snippet',
					max_results:50,
					channel_id:sub_channel_id,
					published_after:last_check_date,
					type:'video',
					videoDuration:len)

    	#byebug
      	# @new_videos.items[0].snippet.title 
        if new_videos.is_a?(Hash) && new_videos[:type] == "error"
          return new_videos
        end

        Array(new_videos&.items).each do | item |
          next unless item.id&.kind == "youtube#video"

          @found_counter += 1
          video = Video.find_or_initialize_by(
            channel: item.snippet.channel_title,
            title: item.snippet.title
          )

          if video.persisted?
            @duplicate_counter += 1
            next
          end

          video.url = "https://www.youtube.com/watch?v=#{item.id.video_id}"
          video.published = item.snippet.published_at

          begin
            video.save!
            @vid_counter += 1
          rescue ActiveRecord::RecordNotUnique
            @duplicate_counter += 1
          end
        end
      end
    end

    # Update the last pulled date in the parameters
    if ytq_param.nil?
      ytq_param = YtqParam.new
      ytq_param.last_date = @new_lastcheck_date
      ytq_param.save
    else
      ytq_param.last_date = @new_lastcheck_date
      ytq_param.save
    end

    {
      "vid_count" => @vid_counter,
      "found_count" => @found_counter,
      "duplicate_count" => @duplicate_counter,
      "sub_count" => @sub_counter
    }

  rescue StandardError => ex
    Rails.logger.error("YoutubeQueue#get_videos failed: #{ex.class}: #{ex.message}")
    { type: "error", msg: "Unable to load videos from YouTube: #{ex.message}" }
  end
  # Copilot-authored: End timestamp and video sync changes.

  # Copilot-authored: Begin paginated subscription loading.
  def get_subscriptions
    subscriptions = []
    page_token = nil

    loop do
      response = @service.list_subscriptions(
        'snippet,contentDetails',
        mine: true,
        max_results: 50,
        page_token: page_token
      )
      subscriptions.concat(Array(response.items))
      page_token = response.next_page_token
      break if page_token.blank?
    end

    subscriptions
  rescue StandardError => ex
    { type: "error", msg: "Error with Google API: #{ex.message}" }
  end
  # Copilot-authored: End paginated subscription loading.

  def init_authorize
#byebug
    # Check if we have all required env vars
    @env_proj_id = ENV['GOOGLE_PROJECT_ID']
    @env_client_id = ENV['GOOGLE_CLIENT_ID']
    @env_client_secret = ENV['GOOGLE_CLIENT_SECRET']
    @env_redirect_uri = ENV['GOOGLE_REDIRECT_URI']

    if @env_proj_id.nil? || @env_client_secret.nil? || @env_client_id.nil? || @env_redirect_uri.nil?
        raise ArgumentError.new('Environment variables not set')
    end

    # Build the secrets file based on environment variables
    # We cannot save it as a file on Heroku as there is no persistent file storage
    # When executed locally (development), these are Linux env variables, Heroku has them in the Heroku setup (web)
    tempHash = {
    "client_id" => @env_client_id,
    "project_id" => @env_proj_id,
    "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
    "token_uri" => "https://www.googleapis.com/oauth2/v3/token",
    "auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs",
    "client_secret" => @env_client_secret,
    "redirect_uris" => ["urn:ietf:wg:oauth:2.0:oob", @env_redirect_uri]
    }

    tempHash2 = { "installed" => tempHash}
#byebug
    if (!File.exist?(CLIENT_SECRETS_PATH))
        File.open(CLIENT_SECRETS_PATH,"w") do |f|
      f.write(tempHash2.to_json)
      end
    end

    # If we don't have the local .credentials/YoutubeQueue.yaml file (USER_TOKEN_FILE),
    # get the tokens and create the USER_TOKEN_FILE (this one is stored in the DB) 
    # 
    if (!File.exist?(USER_TOKEN_FILE))
      FileUtils.mkdir_p(File.dirname(USER_TOKEN_FILE))
      ytq_param         = YtqParam.first
      if (!ytq_param.nil?)
        @newFileContents  = ytq_param.fileContents
        File.open(USER_TOKEN_FILE, "w") do |f|
          f.write(@newFileContents )
        end
      #else
      #  #"Token not stored in DB yet (ytq_params)" 
      #  raise "Token not stored in DB yet (ytq_params)"
      end
    end

    @token_store = Google::Auth::Stores::FileTokenStore.new(file: USER_TOKEN_FILE)
    @client_id   = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    @authorizer  = Google::Auth::UserAuthorizer.new(@client_id, SCOPE, @token_store)
    @user_id     = 'default'
    @credentials = @authorizer.get_credentials(@user_id)
  end

  def authorize
    init_authorize
#byebug
    if @credentials.nil? 
      #url = @authorizer.get_authorization_url(base_url: REDIRECT_URI)
      url = @authorizer.get_authorization_url(base_url: URI.join(@env_redirect_uri, "set_token").to_s)

      return {:type => "url", :url => url }
    else 
      if @credentials.expires_at < Time.now
        # Refresh the token
        @credentials.refresh!
      end
      
      store_token
      return {:type => "credentials", :credentials => @credentials }
    end

    rescue Exception => ex
      if File.exist?(CLIENT_SECRETS_PATH)
        File.delete(CLIENT_SECRETS_PATH)
      end
      return {:type => "error", :msg => "Something went wrong while authenticating: #{ex.message}"}
  end

  def store_token
    # Store the token file in the DB
    File.open(USER_TOKEN_FILE, "r") do |f|
      @fileContents =  f.read.force_encoding("BINARY")
    end

    ytq_param = YtqParam.first  # There will be/should be only 1 record
    if ytq_param.nil?
      ytq_param = YtqParam.new
      ytq_param.fileContents = @fileContents
      ytq_param.save
    else
      ytq_param.fileContents = @fileContents
      ytq_param.save
    end
  end

  def do_set_token token
    init_authorize
    @credentials = @authorizer.get_and_store_credentials_from_code(
        #user_id: @user_id, code: token, base_url: REDIRECT_URI)
        user_id: @user_id, code: token, base_url: URI.join(@env_redirect_uri, "set_token").to_s)
    store_token
  end

  #def search_list_by_keyword(service, part, **params)
  #def search_list_by_keyword(service, part, channel_id:, max_results:, published_after:)
  #def search_list_by_keyword(service, part, channel_id:, max_results:, published_after:, type:, videoType:)
  def search_list_by_keyword(service, part, channel_id:, max_results:, published_after:, type:, videoDuration:)
    #byebug
    #service.list_searches(part, channel_id: channel_id, max_results: max_results, 
    #                    published_after: published_after)
    service.list_searches(part, channel_id: channel_id, max_results: max_results, 
                        published_after: published_after, type: type, video_duration: videoDuration)
  # Copilot-authored: Begin API search error handling.
  rescue StandardError => ex
    return {:type => "error", :msg => "Error with Google API: #{ex.message}"}
  # Copilot-authored: End API search error handling.

  end   

end
