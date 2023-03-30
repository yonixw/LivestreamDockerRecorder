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


The second pitfall which caused the solution failure, was the difficulty to access the recording's result (and let's say it was created successfully after all the previous problems). I did have a simple storage solution in S3 and a simple player that can even jump to any point in time, but because the recordings were of the highest quality, they sometimes weighed as much as 10GB. Which made the price of the tool rise on intensive usage... Another issue was accessing the recording from a mobile device, which was not always able to load the best quality on WIFI.

All of this prompted me to seek a more straightforward and generic solution. Even if some compromises are required.

What is the solution?

