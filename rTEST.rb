  require 'rubygems'
  require 'google/apis'
  require 'google/apis/youtube_v3'
  require 'googleauth'
  require 'googleauth/stores/file_token_store'
  require 'fileutils'
  require 'json'

byebug
 @uri = "https://localhost:3000"

 @uri2 = URI.join(@uri, "set_token").to_s

  print "END"
