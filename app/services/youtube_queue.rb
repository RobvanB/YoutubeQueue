class YoutubeQueue

  require 'rubygems'
  require 'google/apis'
  require 'google/apis/youtube_v3'
  require 'googleauth'
  require 'googleauth/stores/file_token_store'
  require 'fileutils'
  require 'json'

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
    time = Time.now.utc 
    @new_lastcheck_date = time.year.to_s + "-" + time.month.to_s + "-" + time.day.to_s + "T" + time.hour.to_s + ":" +
      time.min.to_s + ":00Z" #Format: '2018-08-10T00:00:00Z'
    @vid_counter = 0
    @sub_counter = 0
  end

  def get_videos(credentials)
    @service.authorization = credentials
    # Get the last time the videos were pulled
    ytq_param = YtqParam.first  # There will be/should be only 1 record
    if ytq_param.nil? || ytq_param.last_date.nil?
      last_check_date = '2018-08-10T00:00:00Z'  #'2018-08-10T00:00:00Z' Initial start date
    else
      last_check_date = ytq_param.last_date
    end
    #byebug
    #Do the seach for each channel I'm subscribed to
    
    resp = get_subscriptions

    if resp.is_a?(Hash) && !resp[:type].nil? && (resp[:type] == "error")
      raise  resp
    end

    @my_subscriptions.items.each do | sub |
      sub_channel_id    = sub.snippet.resource_id.channel_id
      sub_channel_title = sub.snippet.title
      
      #puts sub_channel_title
      #puts sub_channel_id
      @sub_counter += 1
      new_videos = search_list_by_keyword(@service, 
        'snippet',
        max_results: 50,
        channel_id: sub_channel_id,
        published_after: last_check_date)
      
      # @new_videos.items[0].snippet.title 
      unless new_videos.nil?
        new_videos.items.each do | item |
            @channel_id     = item.snippet.channel_id
            @channel_title  = item.snippet.channel_title
            @video_desc     = item.snippet.description
            @published_at   = item.snippet.published_at
            @title          = item.snippet.title
            @video_id       = item.id.video_id
            @kind           = item.id.kind

            #puts @channel_id
            #puts @channel_title
            
            if @kind.eql? 'youtube#video'
              @video            = Video.new
              @video.channel    = @channel_title
              @video.title      = @title
              @video.url        = "https://www.youtube.com/watch?v="+ @video_id
              @video.published  = @published_at
              begin
                @video.save
                @vid_counter += 1
              rescue ActiveRecord::StatementInvalid => e
                # Handle duplicates (i.e. ignore)
                raise e unless e = ActiveRecord::RecordNotUnique
              end
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

    counts = Hash["vid_count" => @vid_counter, "sub_count" => @sub_counter]
    return counts

    rescue Exception => ex
      return resp
  end

  def get_subscriptions
    #@my_channel_id = 'UCvQQkj0g7xL21tf5Fo6Ogvg'
    @my_subscriptions = @service.list_subscriptions('snippet,contentDetails', mine: true, max_results: 50)
    
    rescue Exception => ex
      return {:type => "error", :msg => "Error with Google API: #{ex.message}"}
  end

  def init_authorize
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

    if (!File.exists?(CLIENT_SECRETS_PATH))
        File.open(CLIENT_SECRETS_PATH,"w") do |f|
      f.write(tempHash2.to_json)
      end
    end

    # If we don't have the local .credentials/YoutubeQueue.yaml file (USER_TOKEN_FILE),
    # get the tokens and create the USER_TOKEN_FILE (this one is stored in the DB) 
    # 
    if (!File.exists?(USER_TOKEN_FILE))
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
  def search_list_by_keyword(service, part, channel_id:, max_results:, published_after:)
    #byebug
    service.list_searches(part, channel_id: channel_id, max_results: max_results, 
                        published_after: published_after)
   

  rescue Exception => ex
    return {:type => "error", :msg => "Error with Google API: #{ex.message}"}

  end   

end