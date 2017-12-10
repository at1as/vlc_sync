require 'eventmachine'
require 'faye/websocket'
require 'net/http'
require_relative 'lock'
require_relative 'vlc_client'


class Client

  def initialize(ngrok_id, filename, platform = :macOS)
    @server_url     = "http://#{ngrok_id}.ngrok.io"
    @socket_url     = "ws://#{ngrok_id}.ngrok.io"
    @filename       = filename
    @platform       = platform

    @vlc_client     = VLCClient.new
    @lock           = Lock.new

    @current_status = @vlc_client.status
    start_vlc
    keep_in_sync_with_server
  end


  private

  def start_vlc
    @vlc_client.play(@filename)
    
    # Note [1]
    # Remove this `@vlc_client.status` line and this often fails
    # VLC http server will return back a given status before it is actually in that status
    # It will then drop subsequent reqesuts. `wait_for_local_vlc` is not enough
    # proof that it's safe to continue. The following `@vlc_client.status` line
    # which once again fetches the status from the VLC webserver seems to slow things 
    # down just enough that vlc will reliably transfer from `player` to `paused`
    wait_for_local_vlc("playing")
    @vlc_client.status
    
    @vlc_client.pause
    @current_status = @vlc_client.status
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
  
    wait_for_local_vlc(action) if %w(playing paused stopped).include?(action)
    
    @current_status = @vlc_client.status

    # Don't remove this line. Same reasoning as Note [1] above
    puts "Local player is now in state: #{@vlc_client.status}"
  end

  
	def keep_in_sync_with_server
    Thread.new {
      EM.run do
        ws = Faye::WebSocket::Client.new(@socket_url)

        ws.on :open do
          puts "Connected!"
          ws.send("Now Connected")
        end

        ws.on :message do |msg|
          puts "Received message #{msg.data}"
          next unless %w(paused playing stopped).include? msg.data
          
          if msg != @vlc_client.status && @lock.unlocked?
            @lock.acquire
            update_local_client(msg.data)
            @lock.release
          end
        end

        ws.on :close do
          ws = nil
          Thread.exit
        end

        EventMachine::PeriodicTimer.new(0.01) do
          if (new_status = @vlc_client.status) != @current_status
            @lock.acquire
            puts "Sending update to remote client: #{new_status}"
            ws.send(new_status)
            @current_status = new_status
            @lock.release
          end
        end
      end
    }.join
  end

  
  def update_server_status
    puts "Updating remote player status to : #{@current_status}"
    Net::HTTP::post_form(URI(@server_url + "/Status"), {"status" => @current_status})
  end


  def wait_for_local_vlc(status, timeout = 2)
    start_time = Time.now

    loop do
      return if @vlc_client.status == status || (Time.now - start_time) > timeout
      sleep(0.5)
    end

    raise "TimeoutException"
  end

end
