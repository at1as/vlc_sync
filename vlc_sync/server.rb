require 'em-websocket'

require_relative 'lock'
require_relative 'vlc_client'


EventMachine.run do
  @lock = Lock.new
  
  @vlc_client = VLCClient.new
  @vlc_client.play(ENV['FILENAME'])
  @vlc_client.pause

  # Track local VLC Player state changes in order to push them to clients
  @vlc_client_status = @vlc_client.status

  @clients = []

  EM::WebSocket.start(:host => '0.0.0.0', :port => '4567') do |ws|
    
    ws.onopen do |handshake|
      puts "Connected to client..."
      @clients << ws
      ws.send "Now connected to #{handshake.path}"
    end

    ws.onmessage do |msg|
      puts "received message #{msg}"
      case msg
        when "playing"
          @lock.acquire
          @vlc_client.resume
          @vlc_client_status = @vlc_client.status
          @lock.release
        when "paused"
          @lock.acquire
          @vlc_client.pause
          @vlc_client_status = @vlc_client.status
          @lock.release
        when "stopped"
          @lock.acquire
          @vlc_client.stop
          @vlc_client_status = @vlc_client.status
          @lock.release
      end
    end
  
    ws.onclose do
      ws.send "Closed."
      puts "Connection closed"
      @clients.delete ws
    end

    EventMachine::PeriodicTimer.new(0.01) do
      if ((old_status = @vlc_client_status) != (new_status = @vlc_client.status)) && @lock.unlocked?
        puts "Updating remote client to status: #{new_status}"
        ws.send "#{new_status}"
        @vlc_client_status = new_status
      end
    end

  end
end

