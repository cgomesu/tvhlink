# tvhlink
This is the general purpose repository for my **TVHLink ([TVHeadend](https://github.com/tvheadend/tvheadend) + [Streamlink](https://github.com/streamlink/streamlink)) integration**.  You can find a detailed description of this integration on my website: [https://cgomesu.com/blog/Tvhlink](https://cgomesu.com/blog/Tvhlink).

## Disclaimer
All the software used or mentioned here is free and open-source and all livestream sources are publicly available and are provided by the copyright owners themselves via either plataforms such as Youtube, Twitch, Dailymotion, etc., or their official channels (e.g., CBS News, DW, Reuters) for anyone to use. If you enjoy the content, please consider supporting the developers, streamers, and providers who make this possible.

## tools
The `/tools` subdir contains helper scripts for running the TVHlink integration.  Of note, there's a (`POSIX`) shell script for adding multiple URLs to a single `streamlink` command (it iterates through them and outputs the first one with valid data); and there's a script for Dockerized TVHeadend containers that automatically installs and updates Streamlink inside the TVHeadend container.

## m3u
The `/m3u` subdir contains curated `m3u` playlists to be used with the TVHlink integration.
