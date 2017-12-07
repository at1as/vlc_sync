require 'json'
require_relative 'status'

class VLCClient

  def initialize(host = "127.0.0.1", port = 9000, password = "password", start_time = 0, platform = :macOS)
    @host       = host
    @port       = port
    @password   = password
    @start_time = start_time
    @platform   = platform.to_s.to_sym # no exception for nil
    @filename   = nil

    load_vlc
  end

  def load_vlc
    raise "Only 'macOS' platform is supported!" unless @platform == :macOS
    
    Thread.new do
      `/Applications/VLC.app/Contents/MacOS/VLC --extraintf http --http-host "#{@host}" --http-port #{@port} --http-password #{@password}`
    end if @platform == :macOS
    
    sleep(2)
  end

  def status
    JSON.parse(`curl "http://#{@host}:#{@port}/requests/status.json" -u ":#{@password}"`)['state']
  end

  def play(filename)
    `curl "http://#{@host}:#{@port}/requests/status.xml?command=in_play&input=#{filename}" -u ":#{@password}"`
    
    @filename = filename
  end

  def pause
    `curl "http://#{@host}:#{@port}/requests/status.json?command=pl_pause" -u ":#{@password}"`
  end

  def resume
    `curl "http://#{@host}:#{@port}/requests/status.json?command=pl_play" -u ":#{@password}"`
  end

  def stop 
    `curl "http://#{@host}:#{@port}/requests/status.json?command=pl_stop" -u ":#{@password}"`
  end

  
  def playing?
    status() == "playing"
  end
  
  def paused?
    status() == "paused"
  end
  
  def stopped?
    status() == "stopped"
  end

end

