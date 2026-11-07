<?php
//
// Adds the name of each Live TV channel's group (the playlist's group-title) to the channels returned to the client.
// A channel that's in more than one group uses the first group (by group number).
//
function AddChannelGroupNames( $channels_file_path, &$channels )
{
	$ids = [];
	foreach ( $channels as $channel )
	{
		if ( isset( $channel[ "id" ] ) && isset( $channel[ "url" ] ) )
		{
			$ids[] = ( int )$channel[ "id" ];
		}
	}

	if ( count( $ids ) == 0 )
	{
		return;
	}

	$group_names = [];

	$db = new SQLite3( $channels_file_path, SQLITE3_OPEN_READONLY );

	$query = "SELECT m.channel_id, g.name, g.alias FROM [group_channel_map] m JOIN [group] g ON g.id = m.id" .
			 " WHERE m.channel_id IN (" . implode( ",", array_unique( $ids ) ) . ") ORDER BY g.number ASC";
	$results = @$db->query( $query );
	if ( $results )
	{
		while ( $row = $results->fetchArray( SQLITE3_ASSOC ) )
		{
			if ( !array_key_exists( $row[ "channel_id" ], $group_names ) )
			{
				$group_names[ $row[ "channel_id" ] ] = ( $row[ "alias" ] != NULL && $row[ "alias" ] != "" ? $row[ "alias" ] : $row[ "name" ] );
			}
		}
	}

	$db->close();

	foreach ( $channels as &$channel )
	{
		if ( isset( $channel[ "id" ] ) && isset( $channel[ "url" ] ) )
		{
			$channel[ "group_name" ] = ( array_key_exists( $channel[ "id" ], $group_names ) ? $group_names[ $channel[ "id" ] ] : "" );
		}
	}
	unset( $channel );
}
?>
