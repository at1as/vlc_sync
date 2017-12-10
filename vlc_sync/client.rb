require 'byebug'
require 'em-eventsource'
require 'net/http'
require_relative 'lock'
require_relative 'vlc_client'


class Client

  def initialize(ngrok_id, filename, platform = :macOS)
    @server_url     = "http://#{ngrok_id}.ngrok.io"
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
    sync_local_with_server_changes
    sync_server_with_local_changes
  end

  def sync_local_with_server_changes
    Thread.new {
      EM.run do  
        source = EventMachine::EventSource.new(@server_url + "/StatusStream")

        source.message do |msg|
          if msg != @vlc_client.status && !@lock.locked?

            acquired = @lock.acquire
            puts "Updating local status to #{msg} to match remote player"
            update_local_client(msg) if acquired
            @lock.release
          end
        end

        source.start
      end
    }
  end

  def sync_server_with_local_changes
    # If local state changed, send updates to server
    threads = []
    
    threads << Thread.new {
      loop do
        if ((from = @current_status) != (to = @vlc_client.status)) && !@lock.locked?
          puts "Status changed from #{from} to #{to}"

          @lock.acquire
          @current_status = @vlc_client.status
          update_server_status #unless @current_status 

          wait_for_remote_vlc(Net::HTTP, :get, URI(@server_url + "/Status"), @vlc_client.status, 5)
          @lock.release
        end

      end
    }

    threads.each { |t| t.join }
  end

  
  def update_server_status
    puts "Updating Remote Player Status to : #{@current_status}"
    Net::HTTP::post_form(URI(@server_url + "/Status"), {"status" => @current_status})
  end


  def wait_for_remote_vlc(http_client, method, args, result, timeout = 5)
    start_time = Time.now

    loop do
      return if (res = http_client.send(method, args)) == result || (Time.now - start_time) > timeout
      sleep(1)
    end

    raise "TimeoutException"
  end


  def wait_for_local_vlc(status, timeout = 2)
    start_time = Time.now

    loop do
      return if @vlc_client.status == status || (Time.now - start_time) > timeout
      sleep(1)
    end

    raise "TimeoutException"
  end

end
