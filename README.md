# VLC Sync

Quick script to keep two VLC sessions in sync using ngrok for communication


### Demo

![Demo](https://github.com/at1as/at1as.github.io/raw/master/github_repo_assets/vlc_sync-1_320-240.gif)

# Usage

One VLC session will act as the `server`, which will run the rack webserver on port 4567. The other VLC session will act as the client, which will connect to the server. Client and server will push VLC state changes to each other over a websocket connection.

While this may technically work with multiple clients, it is primarily intended to keep two remote sessions in sync.


### Running The Server

```
## Step 1) Run rack webserver locally

FILENAME="/Users/jwillems/Media/its.a.wonderful.life.(1946).mkv" ruby vlc_sync/server.rb


## Step 2) Run ngrok to tunnel local server port 4567 to the web at the returned ngrok URL

$ ngrok http 4567
# => http://9cf13f35.ngrok.io -> localhost:4567
```


### Running the Client

Note that on the ngrok free plan, the server will need to start first and pass the user the ngrok URL, `9cf13f35`, in the example below. On paid plans a static URL can be chosen

```
## Step 3) Connect client to the remote server over ngrok URL

$ NGROK="9cf13f35" FILENAME="/Users/jwillems/Media/its.a.wonderful.life.(1946).mkv" ruby start_client.rb 
```

The server should be started before the client, or the client will fail to connect


### Details

When either user now pauses or resumes the video, the other player will perform the same action in less than a second


### Dependencies

* Requires an ngrok installation on the acting `server` user
* Server and client have different individual requirement. Gemfile contains all dependencies for both


### Notes

* Built and tested on MacOS 10.11
* Built on Ruby 2.4.0

