# VLC Sync

Quick script to keep two VLC sessions in sync using ngrok for communication


### Demo

![Demo](https://github.com/at1as/at1as.github.io/raw/master/github_repo_assets/vlc_sync-1_320-240.gif)

# Usage

One VLC session will act as the `server`, whose state is updated by the `client` to keep the two video feeds in sync. The server is stateless: it just reports its current state, while the client is stateful, it tracks changes and matches itself to server, or updates the server state to match local changes


### Running The Server

```
## Run sinatra server locally

FILENAME="/Users/jwillems/Media/its.a.wonderful.life.(1946).mkv" ruby vlc_sync/server.rb

## Run ngrok to tunnel local server to the web

$ ngrok http 4567
# => http://9cf13f35.ngrok.io -> localhost:4567
```


### Running the Client

Note that on the ngrok free plan, the server will need to start first and pass the user the ngrok URL. On paid plans a static URL can be chosen

```
$ NGROK="9cf13f35" FILENAME="/Users/jwillems/Media/its.a.wonderful.life.(1946).mkv" ruby start_client.rb 
```


### Details

When either user now pauses or resumes the video, the other player will perform the same action in less than a second


### Dependencies

* Requires an ngrok installation on the acting `server` user
* Server and client have different individual requirement. Gemfile contains all dependencies for both


### Notes

* Built and tested on MacOS 10.11
* Built on Ruby 2.4.0

### TODO

* Switch from server send events to websockets for realtime two-way communication. The server will have to maintain state in order to know when to send events, however it appears to be a worthwhile trade off as keeping players in sync will be more reliable
