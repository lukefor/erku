<?php
//
// m3u/m3u8 playlist helpers.
//

// Returns the value of an attribute in an #EXTM3U or #EXTINF line, or NULL if it's not present.
function GetM3UAttribute( $line, $name )
{
	if ( preg_match( '/(?:^|[\s,])' . preg_quote( $name, '/' ) . '="([^"]*)"/i', $line, $matches ) )
	{
		return $matches[ 1 ];
	}

	return NULL;
}

// Returns the channel number that an #EXTINF line sets, or NULL if it doesn't set one.
// tvg-chno is the standard attribute (channel-number and tvg-num are also used). Some playlists put the number in tvg-id instead.
function GetM3UChannelNumber( $line, $tvg_id )
{
	foreach ( [ "tvg-chno", "channel-number", "tvg-num" ] as $name )
	{
		$value = GetM3UAttribute( $line, $name );
		if ( $value !== NULL && preg_match( '/^\s*(\d+)(?:\.0+)?\s*$/', $value, $matches ) )
		{
			return ( int )$matches[ 1 ];
		}
	}

	if ( $tvg_id !== NULL && preg_match( '/^\s*(\d+)\s*$/', $tvg_id, $matches ) )
	{
		return ( int )$matches[ 1 ];
	}

	return NULL;
}
?>
