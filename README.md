# Erku

Erku is an IPTV and video on demand client for the Roku OS, originally by [Eric Kutcher](https://github.com/erickutcher/erku).

## Repository layout

| Folder | Contents |
| --- | --- |
| [`app/`](app) | The Roku channel. Zip the contents of this folder and sideload it onto your Roku device. |
| [`web_manager/`](web_manager) | The Erku Web Manager: PHP scripts that process m3u/m3u8 playlists and XMLTV EPGs into SQLite databases, and serve them to the Roku channel. The channel's Feed URL must point to this folder. See [`web_manager/README.txt`](web_manager/README.txt). |

## Catch-up / timeshift

Channels can play programs that have already aired when the playlist has catch-up attributes (`catchup`, `catchup-source`, `catchup-days`, `catchup-correction`). These are the same attributes that Kodi's [IPTV Simple Client](https://github.com/kodi-pvr/pvr.iptvsimple) supports. The supported modes, placeholders, and remote controls are listed in [`web_manager/README.txt`](web_manager/README.txt).
