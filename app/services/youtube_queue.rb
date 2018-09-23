class YoutubeQueue
  # Sample Ruby code for user authorization

  require 'rubygems'
  #gem 'google-api-client', '>0.7'
  require 'google/apis'
  require 'google/apis/youtube_v3'
  require 'googleauth'
  require 'googleauth/stores/file_token_store'

  require 'fileutils'
  
  # REPLACE WITH VALID REDIRECT_URI FOR YOUR CLIENT
  REDIRECT_URI = 'http://localhost'
  APPLICATION_NAME = 'YouTube Data API Ruby Tests'

  # REPLACE WITH NAME/LOCATION OF YOUR client_secrets.json FILE
  CLIENT_SECRETS_PATH = 'client_secret_Oauth2_Ruby.json'

  # REPLACE FINAL ARGUMENT WITH FILE WHERE CREDENTIALS WILL BE STORED
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                               "youtube-ruby-snippet-tests.yaml")

  # SCOPE FOR WHICH THIS SCRIPT REQUESTS AUTHORIZATION
  SCOPE = Google::Apis::YoutubeV3::AUTH_YOUTUBE_FORCE_SSL


  def initialize
    # Initialize the API
    @service = Google::Apis::YoutubeV3::YouTubeService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
    time = Time.now.utc 
    @new_lastcheck_date = time.year.to_s + "-" + time.month.to_s + "-" + time.day.to_s + "T" + time.hour.to_s + ":" +
      time.min.to_s + ":00Z" #Format: '2018-08-10T00:00:00Z'
    @vid_counter = 0
    @sub_counter = 0
  end


  def get_videos
    #Get the last time the videos were pulled
    ytq_param = YtqParam.first  # There will be/should be only 1 record
    if ytq_param.nil? || ytq_param.last_date.nil?
      last_check_date = '2018-08-10T00:00:00Z'  #'2018-08-10T00:00:00Z' Initial start date
    else
      last_check_date = ytq_param.last_date
    end

    #Do the seach for each channel I'm subscribed to
    get_subscriptions

    @my_subscriptions.items.each do | sub |
      sub_channel_id    = sub.snippet.resource_id.channel_id
      sub_channel_title = sub.snippet.title
      
      #puts sub_channel_title
      #byebug
      @sub_counter += 1
      new_videos = search_list_by_keyword(@service, 'snippet',
        max_results: 50,
        channel_id: sub_channel_id,
        published_after: last_check_date, 
        type: '')

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

            if @kind.eql? 'youtube#video'
              @video            = Video.new
              @video.channel    = @channel_title
              @video.title      = @title
              @video.url        = "https://www.youtube.com/watch?v="+ @video_id
              @video.published  = @published_at
              @video.save
              @vid_counter += 1
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
  end

  def get_subscriptions
    #@my_channel_id = 'UCvQQkj0g7xL21tf5Fo6Ogvg'
    @my_subscriptions = @service.list_subscriptions('snippet,contentDetails', mine: true, max_results: 50)
  end

  def authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id   = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer  = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id     = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil? || credentials.expires_at < Time.now
      #byebug
      url = authorizer.get_authorization_url(base_url: REDIRECT_URI)
      puts "Open the following URL in the browser and enter the " +
           "resulting code after authorization"
      puts url
      code = gets
      puts "CODE: " + code
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: REDIRECT_URI)
    end
    credentials
  end

  def search_list_by_keyword(service, part, **params)
    service.list_searches(part, params)
  end
end