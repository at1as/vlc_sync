require_relative 'vlc_sync/client'

Client.new(ENV['NGROK'], ENV['FILENAME'])
