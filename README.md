# LivestreamDockerRecorder

# The story behind this repo

## What problem is this project trying to solve?

There are more and more Live broadcasts around me, whether it's because of what happened in 2020 (shhh...) or simply because technology is advancing. From YouTube entertainment to Zoom educational content and seminars.

The problem, of course, is that I couldn't always watch the live broadcasts in their entirety because I was in a different time zone on Earth or because I was at work.

And you'd think that in our time, along with the technological progress of live broadcasts, they would have advanced recording technology as well, but that didn't happen. As a result, I created this project.

## What's the problem with the recordings?

In the narrow sense, the recordings are video files that are stored on a server. In that sense, the offer does exist.

However, there are numerous issues surrounding the recordings that simply make them extremely rare. Among these are:
* Music or broadcast content copyright issues
* Mistakes made by the broadcaster, causing him to delete the recording (for example, he displayed a problematic image sent in chat)
* "Exclusive" content which was provided for free only once, such as a seminar - and other types that do not grant permission for recording.

In many cases, the situation ends up absurd, such as when I miss a zoom during work hours due to an unplanned meeting. After all, I might as well click on the link as needed... Why not obtain access to the recording?

Yet, I will say that some companies are very serious, and they send a recording and the presentation at the end of each Zoom. However, they are extremely rare.

## Is this your first solution?

No, the specific solution and architecture presented here were developed around May 2021. I had a quite different solution in 2018.

Previous solutions had 2 big pitfalls:

First, because I was looking for highly automated solutions that could be performant at the time, I went in the direction of a controlled browser, or HTML that is parsed, and very simply saves the video files to be merged and processed by the likes of FFMPEG.

On the one hand, this method provided the highest quality, but it was severely limited. As soon as you wanted something else, such as downloading the chat or other things, you had to start digging into the platform's format and tailoring a specific solution through reverse engineering. This resulted in a lot of bugs and maintenance because the format was always changing and a fix had to be found. Furthermore, I was suddenly tasked with synchronizing things, deducing the status of the live broadcast from JSON, and so on. Which were very technical tasks, only to be thrown away at random.

This caused the solution to be built and abandoned only a week after. Not to mention that ZOOM is a software, and at the time I was unaware of tricks that allowed you to see ZOOM in the browser as well.


The second pitfall which caused the solution failure was the difficulty to access the recording's result (and let's say it was created successfully after all the previous problems). I did have a simple storage solution in S3 and a simple player that can even jump to any point in time, but because the recordings were of the highest quality, they sometimes weighed as much as 10GB. Which made the price of the tool rise on intensive usage... Another issue was accessing the recording from a mobile device, which was not always able to load the best quality on WIFI.

All of this prompted me to seek a more straightforward and generic solution. Even if some compromises are required.

## What is the proposed solution?

DOCKER with a LINUX DESKTOP with OBS installed was the solution I chose. The DOCKER includes a virtual video card as well as virtual audio card, allowing full recording.
You can also install additional software, such as a browser for websites like YouTube or ZOOM.

## What are the disadvantages of the solution?

In contrast to the solution that simply downloads video files after analyzing the website, OBS here runs for the duration of the recording. As a result, the first disadvantage is that even a minimum quality of 20FPS and 720p requires, that, for the entire recording duration, a working machine with 4 vCPU (memory remains low).

You should also be able to open the live broadcast from LINUX, but I haven't had any issues with that yet as most support Linux.

Another disadvantage is that this is a very generic solution with no automation, so some problems go unattended. For example, how do you know when a YouTube broadcast has become stuck and you need to refresh the page? A browser add-on that refreshes every few minutes is the generic solution. With the disadvantage that if the refresh time is too short, it will interfere with the broadcast. But, if the refresh time is too long, you might miss something important on hangs!

## What are the advantages of the solution?

First and foremost, you can open any live broadcast you want. From YouTube to ZOOM and other sites.

Also, because it's DOCKER, you can create an image with all of your personal preferences (OBS settings, browser plugins that improve chat, and so on...) that you can open at any time to get the exact experience you want (can even be manual GUI actions, saved with `docker commit`).

Another advantage that is shared with other solutions is the ability to run multiple DOCKER instances in the cloud and thus record multiple things at the same time. (Remember to assign everyone four vCPU... that's about $0.15 per hour in most clouds.)

Another advantage we get to keep, despite the fact that the solution appears to be "heavy.", is cloud setup time. For example, in Hetzner, is less than 5 minutes, and because it is generic, it is always ready to be started for any live broadcast you come across! You'll be surprised to learn how much
You lose because you are unable to fit it into your schedule!

Also, OBS supports scheduling recording (and stopping), so you can prepare everything ahead of time, go to sleep, and then return in the morning to a record hot from the oven! Viewing pleasure and good sleep are now compatible!

## Wait, but what about the problem of easy accessibility of the recordings?

Choosing DOCKER has no effect on the situation. But now that we have OBS, we have access to a whole new world. Instead of recording locally, we can stream the result to YouTube Live, for example, and then have easy access from mobile because multiple video quality is created by them. With the added benefit of not having to pay for storage.

Youtube Live has even more features:
* You can make a hidden live broadcast ("Unlisted") to which only the link provides access... so you can give it to whomever you want. It will also help you not risk any important Youtube account you have.
* Youtube Clips are also supported!
* The live stream time is limited to 12 hours. (it is possible to stream more but the recording will be truncated at 12 hours)
* [Looking through people's comments on Quora](https://www.quora.com/Can-I-do-more-than-1-live-on-YouTube-simultaneously), it appears that you can have multiple live streams at the same time if you create a stream key for each instance.  (an example was also given of 34 at the same time). 

Of course, you can still save a recording locally or broadcast it to another provider (Twitch?) using OBS. It's your decision.