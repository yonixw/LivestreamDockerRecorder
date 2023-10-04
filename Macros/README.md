# VNC Macros

In order to completely automate the start of a recording, we will use macros to control the vnc server (with high level commands such as click, type, mouse move etc.)

# Tool used

In my search, I found 3 options to control what the GUIs inside the docker once the X server is up.

1. [xdotool (2K ⭐)](https://github.com/jordansissel/xdotool) which runs inside a x11 environment and can send key strokes and mouse clicks. It can also search for window's names etc.

2. [rfbproxy](https://rfbproxy.sourceforge.net/) which records every VNC actions before passing it along to the upstream VNC server

3. [vncdotool (400 ⭐)](https://github.com/sibson/vncdotool) which, like xdotool, can send key strokes and mouse clicks to a VNC server. It has also a recoding utility that outputs a macro file.

4. vncrobot.com which unfortunately is not up, and the latest version in [webarchive](https://web.archive.org/web/*/http://www.vncrobot.com/downloads/*) uses outdated Java libraries which I didn't want to start and support

I chose to go with option number 3, but without the recording utility. Here are some of the reasons:

* While `xdotool` can give you the most reliable macros, if you know the names and classes of what you want to click, It is very hard to keep track of those if you are not the original developer and can't control them. So I think they will break the fastest.
* `xdotool` also require you to run inside the X11 environment (and thus have to install extra and have the script inside the docker) while I want to run it from CI pipeline as the script might contain passwords (like Youtube Live stream key)
    *  VNC can be accessed remotely using just IP + a known password
* Because we will interact with a lot of buttons, and stuff in HTML, using `xdotool` with all the connectivity complexity attached seems too wasteful, because in the end, most of our macros will have hardcoded locations and no nicely named classes/windows. and see bellow that we will assume same env, to make stuff easier and reliable enough for `vncdotool`.
* `rfbproxy` saves the actions in RFB protocol way, sometimes even as binary and is really hard to change manually, like if we want to change URL you type.
* `vncdotool` works fine but it's recording utility is very janky. and while producing a macro recording, it is very hard to change since mouse movement is all over the place and not intuitive to changes (keystrokes are fine)
    * When I tried it, it didn't support upstream passwords (see issue [#272](https://github.com/sibson/vncdotool/issues/272))
    * When firefox start playing a Twitch stream, I guess the VNC server changes display encoding which cause the recorder to freak out and split the recorded file...
* The only thing that is only available in `xdotool` is the get mouse position command. Since VNC might emulate it in client side. but if you use something like noVNC, you can print XY for every click.
    * in `/core/rfb.js` in `pointerEvent(...)` create a custom breakpoint with `mask && console.log([mask,Math.round(x),Math.round(y)].join(" "))`

# How does it work

For the same reasons above, I am not going to record and replay as it very janky. I will craft "Macro Modules", each with specific purpose like "Open firefox with URL" or "Start OBS". They will be built following some conventions like that the most bottom-left pixel must be free to click on the desktop.

And then, the user will send a YAML of modules to run, each with variables to change.

And to help recording, I will have a script to restart the environment so you can iterate fast, that is a very good feature of using a vnc and x11 inside a docker.

# vncdotool

## Install & Run 

It is very simple to run, just:

```
# pip3 install vncdotool
# OR
pip install git+https://github.com/sibson/vncdotool.git@main 
# OR @v1.1.0 for more stable version

vncdo --version

alias rdo='vncdo --server 127.0.0.1::5900 -p 123456'
rdo type "123"
rdo ./path/to/command_list_script.vdo
```

## Commands
```
pause SECONDS
type STRING
click BUTTON
    1 – Left click
    2 – Middle click
    3 – Right click (4 in noVNC)
    4 – Scroll wheel up
    5 – Scroll wheel down
capture FILENAME.PNG
move X Y
drag X Y  // Move slowly to X,Y
key KEY
mousemove X Y

keydown KEY
keyup KEY
mousedown BUTTON
mouseup BUTTON
rcapture FILENAME.PNG X Y W H

// Need image utils to compare images:
expect FILENAME.PNG FUZZ
rexpect FILENAME.PNG X Y FUZZ
```

## Connecting to VNC

In the dockers I use, connection from the outside world was disabled, you had to add `-localhost no --I-KNOW-THIS-IS-INSECURE` for the server startup command (in `container_startup.sh`) to work.

Another way, is to trick it with another port proxy:
```
docker-compose exec vncmain bash
apt update && apt install -y simpleproxy
simpleproxy -L 5902 -R 127.0.0.1:5900
```
But then, you would need to connect to port 5902, good for security by obscurity (against port scanners) but not all tools support it.

If you want to use a reverse websockify (because noVNC exposes a websockify http endpoint), see this discussion: https://stackoverflow.com/a/14941048/1997873 