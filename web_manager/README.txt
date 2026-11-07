The Erku client requires the following files in order to run properly. Its Feed URL must point to the directory that contains these files.

get_content.php
get_content_info.php
get_epg.php
search.php
favorites.php

These files return JSON encoded strings. The format of each string is documented in each of those files. Refer to the $json_array variable and its output.

get_content_info.php currently uses The Movie Database (TMDB) to retrieve content information. An API key is required, and the $api_read_access_token variable needs to be filled out.
Set the $time_zone variable in get_epg.php to an appropriate value.

The /manager directory contains files that'll help process m3u/m3u8 playlists and XML based electronic programming guides (EPG). It can be accessed from your web browser.
The /databases directory contains the channels.db and vod.db SQLite databases where content is stored. It's also used to download the playlists and EPG.

Make sure the read and write permissions are set correctly on these directories so that all necessary files can be created and accessed.

The channels.db and vod.db databases have to be created first before any content is stored in them. Use the web manager to create them.

Catch-up (timeshift/archive)
----------------------------

Playlists can describe how to watch programs that have already aired using the attributes supported by Kodi's IPTV Simple Client (https://github.com/kodi-pvr/pvr.iptvsimple).
They can be set on the #EXTM3U line (they apply to every channel) and on each #EXTINF line (they override the #EXTM3U values).

catchup (or catchup-type)	default, append, shift (or timeshift), flussonic (flussonic-hls, flussonic-ts, fs), xc, vod, or disabled.
catchup-source			The URL template (default/vod), or the string that's appended to the channel URL (append).
catchup-days			The number of days of programs that are available. The legacy timeshift and tvg-rec attributes are also read. Defaults to 5.
catchup-correction		The number of hours (can be fractional or negative) that's added to the program times.

If catchup isn't set, then default is used when catchup-source is set, and shift is used when only the number of days is set.

The URL templates can use these placeholders:

{utc} ${start}				The program's start time (Unix timestamp).
{utcend} ${end}				The program's end time (Unix timestamp).
{lutc} ${now} ${timestamp}		The current time (Unix timestamp).
{duration} ${duration}			The program's duration in seconds.
{duration:X} ${duration:X}		The program's duration divided by X. e.g. {duration:60} is the duration in minutes.
${offset} {offset:X} ${offset:X}	The number of seconds since the program started, divided by X.
{Y} {m} {d} {H} {M} {S}			The program's start year, month, day, hours, minutes, and seconds.
{utc:Y-m-d H:M:S} ${start:...}		A formatted start time. Also {utcend:...}, ${end:...}, {lutc:...}, ${now:...}, and ${timestamp:...}.

The date/time placeholders use the $time_zone that's set in get_epg.php.

Process the playlist after updating to this version. Existing channels will have their catch-up values updated.
Programs in the EPG are kept for as long as a channel can play them, so the EPG needs to include past programs (or be processed regularly) for them to be available.

In the Erku client's channel guide:
- Press rewind to scroll back before the current time. Left/right scroll by 30 minutes once you're viewing past times.
- Press OK on a program that has ended to watch it. Programs that can be watched show "Catch-up" in their information.
- Press options (*) on a program that's airing (or has ended) and choose "Play from Start" to watch it from its beginning.
While watching a Live TV channel, press the instant replay button to watch the current program from its beginning.
