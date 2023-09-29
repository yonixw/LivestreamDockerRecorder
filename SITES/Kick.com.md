To autoplay kick.com in firefox:
1. Allow autoplay in settings
1. install `automate-click` from https://addons.mozilla.org/en-US/firefox/addon/automate-click/
2. Enter the extension to add rules
3. Add the following rules:
![image](https://github.com/yonixw/LivestreamDockerRecorder/assets/5826209/0f6c73a0-37a6-4f90-b827-42a14898cb0c)
4. Click "Save"
5. Enter kick.com and verify (I had to accept/decline cookie banner ...)

Values used in the image:
* `button[class*=-mute-]`
* `button[aria-label*=mute]`
* `(player\.)?kick\.com\/.*`

The rules click on unmute button (which has different html on the full website and on the player embed lol). 

Initial delay of 1000 (=1 second) worked for me, but to be sure that the mute button is loaded, because their website is quite heavy, I chose 2500 (=2.5 seconds)
