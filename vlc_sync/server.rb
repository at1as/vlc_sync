require 'byebug'
require 'sinatra'
require_relative 'vlc_client'

configure do
  $vlc_client = VLCClient.new
  $vlc_client.play(ENV['FILENAME'])
  $vlc_client.pause
end


get '/Status' do
  "#{$vlc_client.status}"
end


post '/Status' do
  updated_status = params['status'].upcase

  case updated_status
    when "PLAYING"
      $vlc_client.resume
    when "PAUSED"
      $vlc_client.pause
    when "STOPPED"
      $vlc_client.stop
  end

  201
end

