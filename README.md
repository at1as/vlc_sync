# VLC Sync

*WORK IN PROGRESS*

Quick script to keep two VLC sessions in sync using ngrok for communication


# Usage

One VLC session will act as the server, whose state is updated by and fetched by the client to keep the two video feeds in sync 

### Server

```
FILENAME="/Users/jwillems/Media/its.a.wonderful.life.(1946).mkv" ruby vlc_sync/server.rb 
ngrok http 4567
```


### Client

```
NGROK="ab99dx8f" FILENAME="/Users/jwillems/Media/its.a.wonderful.life.(1946).mkv" ruby start_client.rb 
```

## Details

When either user now pauses or resumes the video, the other player will perform the same action
