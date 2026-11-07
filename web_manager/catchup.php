<?php
//
// Catch-up (timeshift/archive) support.
//
// Playlists can describe how to retrieve previously aired programs using the
// attributes popularized by Kodi's IPTV Simple Client (pvr.iptvsimple):
//
//   catchup / catchup-type   The catch-up mode: default, append, shift (or timeshift),
//                            flussonic (flussonic-hls, flussonic-ts, fs), xc, or vod.
//   catchup-source           The URL template (default/vod), or the string appended
//                            to the channel URL (append).
//   catchup-days             How many days of programs are available. Also read from
//                            the legacy timeshift and tvg-rec attributes.
//   catchup-correction       Hours to add to the program times (may be fractional/negative).
//
// The attributes can be set on the #EXTM3U header line (applies to every channel)
// and overridden on each #EXTINF line.
//
// The Erku client receives a fully resolved "catchup_source" template that only
// contains time placeholders ({utc}, {utcend}, {lutc}, {duration}, {Y}, ${start}, etc.).
// The client replaces those with the selected program's times when it's played.
//

// The number of days of catch-up that's assumed when a mode is set without a day count.
const CATCHUP_DEFAULT_DAYS = 5;

// Returns the value of an attribute in an #EXTM3U or #EXTINF line, or NULL if it's not present.
function GetM3UAttribute( $line, $name )
{
	if ( preg_match( '/(?:^|[\s,])' . preg_quote( $name, '/' ) . '="([^"]*)"/i', $line, $matches ) )
	{
		return $matches[ 1 ];
	}

	return NULL;
}

// Reads the catch-up attributes of an #EXTM3U or #EXTINF line.
// Attributes that aren't present are NULL.
function ParseCatchupAttributes( $line )
{
	$catchup = GetM3UAttribute( $line, "catchup" );
	if ( $catchup === NULL )
	{
		$catchup = GetM3UAttribute( $line, "catchup-type" );
	}

	$days = GetM3UAttribute( $line, "catchup-days" );
	if ( $days === NULL )
	{
		$days = GetM3UAttribute( $line, "tvg-rec" );
	}
	if ( $days === NULL )
	{
		$days = GetM3UAttribute( $line, "timeshift" );
	}

	return array( "catchup" => ( $catchup !== NULL ? strtolower( trim( $catchup ) ) : NULL ),
				  "catchup_source" => GetM3UAttribute( $line, "catchup-source" ),
				  "catchup_days" => ( $days !== NULL ? ( int )$days : NULL ),
				  "catchup_correction" => GetM3UAttribute( $line, "catchup-correction" ) );
}

// Combines a channel's catch-up attributes with the playlist header's defaults.
// Returns the values that should be stored in the channel table.
function MergeCatchupAttributes( $channel_attributes, $header_attributes )
{
	$merged = [];
	foreach ( [ "catchup", "catchup_source", "catchup_days", "catchup_correction" ] as $key )
	{
		$merged[ $key ] = ( $channel_attributes[ $key ] !== NULL ? $channel_attributes[ $key ] : $header_attributes[ $key ] );
	}

	$catchup = ( $merged[ "catchup" ] !== NULL ? $merged[ "catchup" ] : "" );
	$source = ( $merged[ "catchup_source" ] !== NULL ? $merged[ "catchup_source" ] : "" );
	$days = ( $merged[ "catchup_days" ] !== NULL ? $merged[ "catchup_days" ] : 0 );
	$correction = ( $merged[ "catchup_correction" ] !== NULL ? ( float )$merged[ "catchup_correction" ] : 0 );

	if ( $catchup == "" || $catchup == "disabled" )
	{
		if ( $catchup == "" && $source != "" )
		{
			$catchup = "default";
		}
		else if ( $catchup == "" && $days > 0 )
		{
			$catchup = "shift";	// Legacy timeshift/tvg-rec attributes.
		}
		else
		{
			$catchup = "";
		}
	}

	if ( $catchup != "" && $days <= 0 )
	{
		$days = CATCHUP_DEFAULT_DAYS;
	}

	return array( "catchup" => $catchup,
				  "catchup_source" => $source,
				  "catchup_days" => $days,
				  "catchup_correction" => $correction );
}

// Generates the URL template used to retrieve a channel's previously aired programs.
// Returns an empty string if the channel doesn't support catch-up.
function GetCatchupTemplate( $url, $catchup, $source )
{
	$catchup = strtolower( ( string )$catchup );
	$source = ( string )$source;

	switch ( $catchup )
	{
		case "default":
		case "vod":
		{
			return $source;
		}

		case "append":
		{
			return ( $source != "" ? $url . $source : "" );
		}

		case "shift":
		case "timeshift":
		{
			return $url . ( strpos( $url, "?" ) !== false ? "&" : "?" ) . "utc={utc}&lutc={lutc}";
		}

		case "flussonic":
		case "flussonic-hls":
		case "flussonic-ts":
		case "fs":
		{
			// http://host/channel/index.m3u8?token=x  ->  http://host/channel/timeshift_rel-{offset:1}.m3u8?token=x
			// http://host/channel/video.m3u8?token=x  ->  http://host/channel/video-timeshift_rel-{offset:1}.m3u8?token=x
			// http://host/channel/mpegts?token=x      ->  http://host/channel/timeshift_abs-{utc}.ts?token=x
			if ( preg_match( '/^(https?:\/\/[^\/]+)\/(.*)\/([^\/]*)(mpegts|\.m3u8)(\?.+=.+)?$/', $url, $matches ) )
			{
				$host = $matches[ 1 ];
				$channel_id = $matches[ 2 ];
				$list_type = $matches[ 3 ];
				$stream_type = $matches[ 4 ];
				$query = ( isset( $matches[ 5 ] ) ? $matches[ 5 ] : "" );

				if ( $stream_type == "mpegts" || $catchup == "flussonic-ts" )
				{
					return $host . "/" . $channel_id . "/timeshift_abs-{utc}.ts" . $query;
				}
				else if ( $list_type == "index" || $list_type == "" )
				{
					return $host . "/" . $channel_id . "/timeshift_rel-{offset:1}.m3u8" . $query;
				}
				else
				{
					return $host . "/" . $channel_id . "/" . $list_type . "-timeshift_rel-{offset:1}.m3u8" . $query;
				}
			}
			else if ( preg_match( '/^(https?:\/\/[^\/]+)\/(.*)\/([^\?]*)(\?.+=.+)?$/', $url, $matches ) )
			{
				$host = $matches[ 1 ];
				$channel_id = $matches[ 2 ];
				$query = ( isset( $matches[ 4 ] ) ? $matches[ 4 ] : "" );

				if ( $catchup == "flussonic-hls" )
				{
					return $host . "/" . $channel_id . "/timeshift_rel-{offset:1}.m3u8" . $query;
				}

				return $host . "/" . $channel_id . "/timeshift_abs-{utc}.ts" . $query;
			}

			return $source;
		}

		case "xc":
		{
			// http://host:port/live/username/password/1234.ts  ->  http://host:port/timeshift/username/password/{duration:60}/{Y}-{m}-{d}:{H}-{M}/1234.ts
			if ( preg_match( '/^(https?:\/\/[^\/]+)\/(?:live\/)?([^\/]+)\/([^\/]+)\/([^\/\.\?]+)(\.[^\/\?]+)?(\?.*)?$/', $url, $matches ) )
			{
				$host = $matches[ 1 ];
				$username = $matches[ 2 ];
				$password = $matches[ 3 ];
				$stream_id = $matches[ 4 ];
				$extension = ( isset( $matches[ 5 ] ) && $matches[ 5 ] != "" ? $matches[ 5 ] : ".ts" );

				return $host . "/timeshift/" . $username . "/" . $password . "/{duration:60}/{Y}-{m}-{d}:{H}-{M}/" . $stream_id . $extension;
			}

			return $source;
		}
	}

	return "";
}

// Returns the file extension of a catch-up template, or the channel's extension if it doesn't have one.
function GetCatchupExtension( $template, $default_extension )
{
	$path = parse_url( $template, PHP_URL_PATH );
	if ( $path !== NULL && $path !== false )
	{
		$extension = pathinfo( $path, PATHINFO_EXTENSION );
		if ( $extension != "" && strpos( $extension, "{" ) === false && strpos( $extension, "}" ) === false )
		{
			return $extension;
		}
	}

	return $default_extension;
}

// Returns the catch-up fields for a row of the channel table.
// Older databases that don't have the catch-up columns return values that disable catch-up.
function GetChannelCatchupInfo( $row )
{
	$catchup = ( isset( $row[ "catchup" ] ) ? $row[ "catchup" ] : "" );
	$source = ( isset( $row[ "catchup_source" ] ) ? $row[ "catchup_source" ] : "" );
	$days = ( isset( $row[ "catchup_days" ] ) ? ( int )$row[ "catchup_days" ] : 0 );
	$correction = ( isset( $row[ "catchup_correction" ] ) ? ( float )$row[ "catchup_correction" ] : 0 );

	$template = "";
	if ( $catchup != "" )
	{
		$template = GetCatchupTemplate( $row[ "url" ], $catchup, $source );
	}

	if ( $template == "" )
	{
		return array( "catchup_source" => "",
					  "catchup_extension" => "",
					  "catchup_days" => 0,
					  "catchup_correction" => 0 );
	}

	return array( "catchup_source" => $template,
				  "catchup_extension" => GetCatchupExtension( $template, $row[ "extension" ] ),
				  "catchup_days" => ( $days > 0 ? $days : CATCHUP_DEFAULT_DAYS ),
				  "catchup_correction" => ( int )round( $correction * 3600 ) );	// In seconds.
}

// Adds the catch-up columns to a channel table that was created before they existed.
function AddCatchupColumns( $db )
{
	$columns = [];
	$results = $db->query( "PRAGMA table_info([channel])" );
	while ( $row = $results->fetchArray( SQLITE3_ASSOC ) )
	{
		$columns[ $row[ "name" ] ] = true;
	}

	// The table doesn't exist.
	if ( count( $columns ) == 0 )
	{
		return;
	}

	if ( !isset( $columns[ "catchup" ] ) )
	{
		$db->exec( "ALTER TABLE [channel] ADD COLUMN catchup TEXT" );
	}
	if ( !isset( $columns[ "catchup_source" ] ) )
	{
		$db->exec( "ALTER TABLE [channel] ADD COLUMN catchup_source TEXT" );
	}
	if ( !isset( $columns[ "catchup_days" ] ) )
	{
		$db->exec( "ALTER TABLE [channel] ADD COLUMN catchup_days INTEGER DEFAULT 0" );
	}
	if ( !isset( $columns[ "catchup_correction" ] ) )
	{
		$db->exec( "ALTER TABLE [channel] ADD COLUMN catchup_correction REAL DEFAULT 0" );
	}
}

// Returns the largest number of catch-up days of any channel, or 0 if no channel supports catch-up.
function GetMaxCatchupDays( $db )
{
	$max_days = 0;

	$results = @$db->query( "SELECT MAX(catchup_days) AS max_days FROM [channel] WHERE catchup IS NOT NULL AND catchup != ''" );
	if ( $results && ( $row = $results->fetchArray( SQLITE3_ASSOC ) ) && $row[ "max_days" ] !== NULL )
	{
		$max_days = ( int )$row[ "max_days" ];
	}

	return $max_days;
}
?>
