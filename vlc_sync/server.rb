require 'byebug'
require 'eventmachine'
require 'sinatra'
require 'sinatra/streaming'
require_relative 'vlc_client'

configure do
  $vlc_client = VLCClient.new
  $vlc_client.play(ENV['FILENAME'])
  $vlc_client.pause
end


get '/Status' do
  "#{$vlc_client.status}"
end


get '/StatusStream', provides: 'text/event-stream' do
  stream :keep_open do |out|
    begin
      EM.run { 
        EventMachine::PeriodicTimer.new(0.25) do
          out << "data: #{$vlc_client.status}\n\n"
        end
      }
    rescue Errno::EIO
    ensure
      keep_alive.cancel rescue nil
      out.close unless out.closed?
    end
  end
end


post '/Status' do
  updated_status = params['status']

  case updated_status
    when "playing"
      $vlc_client.resume
    when "paused"
      $vlc_client.pause
    when "stopped"
      $vlc_client.stop
  end

  201
end

