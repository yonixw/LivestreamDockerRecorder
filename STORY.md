# The story behind this repo

## What problem is this project trying to solve?

There are more and more Live broadcasts around me, whether it's because of what happened in 2020 (something major I heard...) or simply because technology adaption is advancing. From YouTube entertainment to Zoom educational content and seminars.

The problem, of course, is that I can't always watch the live broadcasts in their entirety because either a different time zone (catching me mid sleep) or because I am busy working.

And you'd think that in our time, along with the technological progress and adaption of live broadcasts, they would have advanced recordings adaption as well, but that didn't happen. As a result, I created this project.

## What's the problem with recordings adaption?

In the narrow sense, where recordings are only video files that are stored on a server, the offer does exist.

However, there are some non techinacal issues surrounding the recordings that simply make them extremely rare. Among them we find:
* Copyright issues when using music or reacting to content
* Mistakes made by the broadcaster, causing him to delete the recording (for example, he displayed a problematic image sent in chat)
* "Exclusive" content which was provided for free only once, such as a seminar - and other types that do not grant permission for recording.

In many cases, the situation ends up absurd, such as when I miss a zoom during work hours due to an unplanned meeting. After all, I might as well click on the link at the time... Why not obtain access to the recording?

Yet, I will say that some companies do send the recording and presentation at the end of each Zoom. Yet, they are extremely rare.

## Is this your first solution?

No, the specific solution and architecture presented here were developed around May 2021. I had a quite different solution in 2018.

Previous solutions had 2 big pitfalls:

First, because I was looking for a highly automated solutions that will be performant at the same time, I went in the direction of a controlled browser or HTML that is parsed to extract the raw video URL which then saves the video files to be merged and processed by something like FFMPEG.

On the one hand, this method provided the highest quality, but it was severely limited. As soon as you wanted something more, such as downloading the chat or maybe metadata things, you had to start digging into the platform's own format and tailoring a specific solution through reverse engineering. This resulted in a lot of bugs and maintenance because the format is always updating and a fix had to be found or the system would be broken. Furthermore, I was suddenly tasked with synchronizing things, deducing the status of the live broadcast from JSON, and so on. Which were very technical tasks, only to be thrown away at random at the next platfrom update.

This caused the solution to be built and abandoned only a week after. Not to mention that ZOOM is a software, and at the time I was unaware you were allowed to see ZOOM in the browser as well.

The second pitfall which caused the solution failure was the difficulty to access the recording's result (say it was created successfully given previous problems). I did have a simple storage solution in S3 and a simple player that can even jump to any point in the saved video, but because the recordings were of the highest quality, they sometimes weighed as much as 10GB. Which made the price of the tool rise on intensive usage... Another issue was accessing the recording from a mobile device, which was not always able to load the best quality on WIFI. 

All of this prompted me to seek a more straightforward and generic solution. Even if some compromises are required.

## What is the proposed solution?

DOCKER with a LINUX DESKTOP inside it with OBS installed was the solution I chose. The DOCKER includes a virtual video and audio card, allowing full recording.
You can also install additional software, such as ZOOM for native recording (not just websites in a browser).

## What are the disadvantages of the solution?

In contrast to the solution that simply downloads video files after analyzing the website, OBS here runs for the duration of the recording. As a result, the first disadvantage is that even a minimum quality of 20FPS and 720p requires, that, for the entire recording duration, a working machine with 4 vCPU will be up (memory remains low).

If you don't use a browser, then it must support running on LINUX, but I haven't had any issues with that yet (Zoom has a linux installer).

Another disadvantage is that this is a very generic solution, so some specifiec problems are not answered for out of the box. For example, how do you know when a YouTube broadcast has become stuck/live/offline and you need to refresh the browser page? A browser add-on that refreshes every few minutes will be needed in addition. With the inherit disadvantage that if the refresh time is too frequent, it will interfere with the broadcast. But, if the refresh time is too far apart, you might miss something important if the stream hangs!

There are also some quirks special to this solution like making sure the OBS is in the forground during the recording, but it is insignificat relativly.

## What are the advantages of the solution?

First and foremost, you can open any live broadcast you want. From YouTube to ZOOM and other sites.

Also, because it's DOCKER, you can create an image variant with all of your personal preferences (OBS settings, browser plugins that improve chat, and so on...) that you can open at any time to get the exact experience you want (can even be manual GUI actions, saved with `docker commit`).

Another advantage is the ability to run multiple DOCKER instances in the cloud and thus record multiple things at the same time. (Remember to assign each 4x vCPU... )

Another advantage we get to keep, despite the fact that the solution appears to be "heavy.", is cloud setup time. For example, in Hetzner, it takes less than 5 minutes, and because it is generic, it is always ready to be started for any live broadcast you come across! You'll be surprised to learn how much content you pass on because you are unable to fit it into your schedule!

Also, OBS supports scheduling recording (and stopping), so you can prepare everything ahead of time, go to sleep, and then return in the morning to a record hot from the oven! Viewing pleasure and good sleep are now compatible (FOMO no mo)!

## Wait, but what about the problem of easy accessibility of the recordings?

Choosing DOCKER has no effect on the situation. But now that we have OBS, we have access to a whole new world. In addition to recording locally, we can also stream the result to YouTube Live, for example, and then have easy access from mobile because multiple video quality is created by YouTube. With the added benefit of not having to pay for storage.

Youtube Live has even more features:
* You can make a hidden live broadcast ("Unlisted") to which only the link provides access... so you can share it with whoever you want. It will also help you not risk any important Youtube account you have with copyright issues.
* Youtube Clips are also supported!
* The live stream time is limited to 12 hours. (it is possible to stream more but the recording will be truncated at **FIRST** 12 hours, while live replay is limited to the **LATEST** 12 hours)
* [Looking through people's comments on Quora](https://www.quora.com/Can-I-do-more-than-1-live-on-YouTube-simultaneously), it appears that you can have multiple live streams at the same time if you create a stream key for each instance.  (an example was also given of 34 at the same time).
    * I was able to do it by scheduling a Live, and it opened an option to create new stream keys

Of course, you can still save a recording locally or broadcast it to another provider (Twitch?) using OBS. It's your decision.
