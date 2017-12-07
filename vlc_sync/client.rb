require 'net/http'
require_relative 'vlc_client'

class Client

  def initialize(ngrok_id, filename, platform = :macOS)
    @server_url     = "http://#{ngrok_id}.ngrok.io"
    @filename       = filename
    @platform       = platform

    @ping_interval  = 3
    @check_interval = 1
    @vlc_client     = VLCClient.new
    @lock           = false

    @current_status = @vlc_client.status
    start_vlc
    keep_in_sync_with_server
  end


  def start_vlc
    @vlc_client.play(@filename)
    @vlc_client.pause
    @vlc_client.status
  end

  
  def update_local_client(action)
    case action
      when "playing"
        @vlc_client.resume
      when "paused"
        @vlc_client.pause
      when "stopped"
        @vlc_client.stop
    end

    @current_status = @vlc_client.status
  end

  
  def keep_in_sync_with_server
    threads = []
    
    # check_server_status
    threads << Thread.new {
      loop do
        unless @lock
          res = Net::HTTP.get(URI(@server_url + "/Status"))
          
          if (server_status = res) != @current_status
            update_local_client(server_status)
          end
        end

        sleep(@ping_interval)
      end
    }
    
    # If local state changed, send updates to server
    threads << Thread.new {
      loop do
        if @current_status != @vlc_client.status
          @lock = true
          @current_status = @vlc_client.status
          update_server_status
          @lock = false
        end

        sleep(@check_interval)
      end
    }

    threads.each { |t| t.join }
  end

  def update_server_status
    Net::HTTP::post_form(URI(@server_url + "/Status"), {"status" => @current_status})
  end

end
