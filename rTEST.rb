  require 'rubygems'
  require 'google/apis'
  require 'google/apis/youtube_v3'
  require 'googleauth'
  require 'googleauth/stores/file_token_store'
  require 'fileutils'
  require 'json'


  tmpHash = { :type => "error" }

  type = tmpHash[:type]

  if type == 'ff'
    print "nope"
  elsif type == 'error'
    print "ok"
  end

  print "END"
