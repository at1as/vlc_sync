require 'json'
require 'net/http'
require 'uri'

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

    # VLC built in http server won't accept requests until it has started up
    # Even after it has booted and returns 200s, it will drop requests sent to it for about the next second or so
    start_time = Time.now
    timeout    = 5

    loop do
      break if alive?
      raise "VLCFailedToLoad" if (Time.now - start_time) > timeout
      sleep(1)
    end
  end
  

  def alive?
    !!send_status_request
  rescue Errno::ECONNREFUSED
    false
  end

  def status
    JSON.parse(send_status_request.body)['state']
  end

  
  def play(filename)
    send_status_request("command=in_play&input=#{filename}") 
    @filename = filename
  end

  def pause
    send_status_request("command=pl_pause")
  end

  def resume
    send_status_request("command=pl_play")
  end

  def stop 
    send_status_request("command=pl_stop")
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

  
  private
    def send_status_request(params_string = "")
      vlc_server = "http://#{@host}:#{@port}"
      path       = "/requests/status.json"

      http    = Net::HTTP.new(@host, @port)
      request = Net::HTTP::Get.new("#{path}?#{params_string}".chomp("?"))
      request.basic_auth("", @password)

      http.request(request)
    end
end

