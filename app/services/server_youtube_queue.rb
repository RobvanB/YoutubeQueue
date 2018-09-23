class YoutubeQueue < Sinatra::Base

  require 'google/apis/youtube_v3'
  require 'google/api_client/client_secrets'
  require 'json'
  require 'sinatra'


  client_secrets = Google::APIClient::ClientSecrets.load
  auth_client = client_secrets.to_authorization
  auth_client.update!(
  :scope => 'https://www.googleapis.com/auth/youtube.force-ssl',
  :redirect_uri => 'http://localhost:8080',
  :additional_parameters => {
    "access_type" => "offline",         # offline access
    "include_granted_scopes" => "true"  # incremental auth
    }
  )

  auth_uri = auth_client.authorization_uri.to_s

  puts "AUTH URI: " + auth_uri

  enable :sessions
  set :session_secret, 'setme'

 #byebug

  get '/' do
    unless session.has_key?(:credentials)
      redirect to('/oauth2callback')
    end
    client_opts = JSON.parse(session[:credentials])
    auth_client = Signet::OAuth2::Client.new(client_opts)
    youtube = Google::Apis::YoutubeV3::YouTubeService.new
    channel = youtube.list_channels(part, :mine => mine, options: { authorization: auth_client })
  
    "<pre>#{JSON.pretty_generate(channel.to_h)}</pre>"
    puts "JSON"
  end

  

  get '/oauth2callback' do
    client_secrets = Google::APIClient::ClientSecrets.load
    auth_client = client_secrets.to_authorization
    auth_client.update!(
      :scope => 'https://www.googleapis.com/auth/youtube.force-ssl',
      :redirect_uri => url('/oauth2callback'))
    if request['code'] == nil
      auth_uri = auth_client.authorization_uri.to_s
      redirect to(auth_uri)
    else
      auth_client.code = request['code']
      auth_client.fetch_access_token!
      auth_client.client_secret = nil
      session[:credentials] = auth_client.to_json
      redirect to('/')
    end
  end


end