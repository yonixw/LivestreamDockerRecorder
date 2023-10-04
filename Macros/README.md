# VNC Macros

In order to completely automate the start of a recording, we will use macros to control the vnc server (with high level commands such as click, type, mouse move etc.)

# Tool used

In my search, I found 3 options to control what the GUIs inside the docker once the X server is up.

1. [xdotool (2K ⭐)](https://github.com/jordansissel/xdotool) which runs inside a x11 environment and can send key strokes and mouse clicks. It can also search for window's names etc.

2. [rfbproxy](https://rfbproxy.sourceforge.net/) which records every VNC actions before passing it along to the upstream VNC server

3. [vncdotool (400 ⭐)](https://github.com/sibson/vncdotool) which, like xdotool, can send key strokes and mouse clicks to a VNC server. It has also a recoding utility that outputs a macro file.

I chose to go with option number 3 or number 1, but without the recording utility. Here are some of the reasons:

* While `xdotool` can give you the most reliable macros, if you know the names and classes of what you want to click, It is very hard to keep track of those if you are not the original developer and can't control them. So I think they will break the fastest.
* `xdotool` also require you to run inside the X11 environment (and thus have the script inside the docker) while I want to run it from CI pipeline as the script might contain passwords (like Youtube Live stream key)
    *  Unlike VNC which can be accessed remotely using a known password
    * TODO, `xdotool` remote port into vm into docker? (try my new docker variants), need SSH?;
        * https://manpages.ubuntu.com/manpages/trusty/man1/xdotool.1.html
        * https://manpages.ubuntu.com/manpages/trusty/man1/xwininfo.1.html
* `rfbproxy` saves the actions in RFB protocol way, sometimes even as binary and is really hard to change manually, like if we want to change URL you type.
* `vncdotool` works fine but it's recording utility is very janky. and while producing a macro recording, it is very hard to change since mouse movement is all over the place and not intuitive to changes (keystrokes are fine)
    * When I tried it, it didn't support upstream passwords (see issue [#272](https://github.com/sibson/vncdotool/issues/272))
    * When firefox start playing a Twitch stream, I guess the VNC server changes display encoding which cause the recorder to freak out and split the recorded file...

# How does it work

For the same reasons above, I am not going to record and replay as it very janky. I will craft "Macro Modules", each with specific purpose like "Open firefox with URL" or "Start OBS". They will be built following some conventions like that the most bottom-left pixel must be free to click on the desktop.

And then, the user will send a YAML of modules to run, each with variables to change.

And to help recording, I will have a script to restart the environment so you can iterate fast, that is a very good feature of using a vnc and x11 inside a docker.