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
  updated_status = params['status']
  puts params
  case updated_status
    when "playing"
      puts "HELLLLLLLo"
      $vlc_client.resume
    when "paused"
      $vlc_client.pause
    when "stopped"
      $vlc_client.stop
    else
      puts "DAMNNNNN"
  end

  201
end

