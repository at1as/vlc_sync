require 'net/http'
require_relative 'vlc_client'

class Client

  def initialize(ngrok_url, filename, platform = :macOS)
    @server_url     = ngrok_url
    @filename       = filename
    @platform       = platform

    # There can likely be a race condition here if ping_interval and check_interval are the same
    @ping_interval  = 3
    @check_interval = 1
    @vlc_client     = VLCClient.new

    @current_status = @vlc_client.status
    start_vlc
  end


  def start_vlc
    @vlc_client.play(@filename)
    @vlc_client.pause
    @vlc_client.status
  end

  
  def update_local_client(action)
    case action
      when :PLAYING
        @vlc_client.resume
      when :PAUSED
        @vlc_client.stop
      when :STOPPED
        @vlc_client.stop
    end

    @current_status = @vlc_client.status
  end

  
  def check_server_status
    Thread.new {
      res = NET::HTTP.get(@server_url, 'Status')

      if (server_status = res.body) != @current_status
        update_local_client(server_status)
      end

      sleep(@ping_interval)
    }
  end

  
  def check_local_status
    # If local state changed, send updates to server
    Thread.new {
      if @current_status != @vlc_client.status
        @current_status = @vlc_client.status
        update_server_status
      end

      sleep(@check_interval)
    }
  end

  def update_server_status
    req = Net::HTTP::Post.new(@server_url, 'Status')
    req.set_form_data('status' => @vlc_client.status)
    res = http.start { |http| http.request(req) }
  end

end
