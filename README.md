# Livestream Docker Recorder

Create a linux desktop in the cloud (with virtual screen and speakers) to record any livestream you want!

Based on `bandi13/docker-obs` repo.

# Builds

See: https://hub.docker.com/r/yonixw/obs-audio-firefox

# Demo Video

TODO

# Bugs and Notes:

* OBS need to be in the foreground at recording time
* Need to delete after commit:
    * rm /tmp/.X0-lock
    * rm /var/run/dbus/pid
    * rm ~/.config/obs-studio 
* The VNC password is printed to stdout.. so docker logs should not be public

# Hetzner QuickStart

TODO

# The story behind this repo

[Go to STORY.md](./STORY.md)
