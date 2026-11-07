<?php
require_once( "catchup.php" );
require_once( "channel_groups.php" );

$sort = isset( $_REQUEST[ "sort" ] ) ? ( int )$_REQUEST[ "sort" ] : -1;
$id = isset( $_REQUEST[ "id" ] ) ? ( int )$_REQUEST[ "id" ] : -1;

$limit = isset( $_REQUEST[ "limit" ] ) ? ( int )$_REQUEST[ "limit" ] : 0;
$offset = isset( $_REQUEST[ "offset" ] ) ? ( int )$_REQUEST[ "offset" ] : 0;

$search_query = isset( $_REQUEST[ "query" ] ) ? $_REQUEST[ "query" ] : "";

$json_array = [ "data" => array( "total" => 0, "id" => -1, "name" => "", "time_zone_offset" => 0, "values" => [] ) ];

$time_zone = "Europe/London";	// The time zone of the program times sent to the client. Should match the Roku device's time zone.

$tz = new DateTimeZone( $time_zone );
$time_zone_offset = $tz->getOffset( new DateTime( "now", $tz ) );

// Program times are offset by this value. The client uses it to get the UTC times when requesting catch-up content.
$json_array[ "data" ][ "time_zone_offset" ] = $time_zone_offset;

$database_path = "databases/";

$channels_file_path = $database_path . "channels.db";

function GetRange( $_total, $_limit, $_offset )
{
	$ret = [ 0, 0, 0, 0 ];

	if ( $_limit >= 0 && $_limit <= $_total )
	{
		if ( abs( $_offset ) >= $_total )
		{
			if ( $_offset < 0 )
			{
				$_offset = ( $_total + $_offset ) % $_total;
			}
			else
			{
				$_offset = $_offset % $_total;
			}
		}

		$old_limit = $_limit;
		$old_offset = $_offset;

		if ( ( $old_offset + $old_limit ) > $_total )
		{
			$old_offset = $old_offset - $_total;
		}

		if ( $old_offset < 0 )
		{
			$_limit = $_limit + $old_offset;
			$_offset = 0;
		}

		if ( $_limit > 0 )
		{
			$ret[ 0 ] = $_limit;
			$ret[ 1 ] = $_offset;
		}

		if ( $old_offset < 0 )
		{
			$_limit = abs( $old_offset );
			if ( $_limit > $old_limit )
			{
				$_limit = $old_limit;
			}
			$_offset = ( $_total + $old_offset ) % $_total;

			if ( $_limit > 0 )
			{
				$ret[ 2 ] = $_limit;
				$ret[ 3 ] = $_offset;
			}
		}
	}
	else
	{
		$ret[ 0 ] = $_total;
	}

	return $ret;
}

function MakeQuery( $_range, $_query )
{
	$query = "SELECT 0 WHERE 0";

	if ( $_range[ 0 ] != 0 && $_range[ 2 ] != 0 )
	{
		$query = "SELECT * FROM (" . $_query . " LIMIT " . $_range[ 0 ] . " OFFSET " . $_range[ 1 ] . ")";
		$query .= " UNION ALL";
		$query .= " SELECT * FROM (" . $_query . " LIMIT " . $_range[ 2 ] . " OFFSET " . $_range[ 3 ] . ")";
	}
	else if ( $_range[ 0 ] != 0 )
	{
		$query = $_query . " LIMIT " . $_range[ 0 ] . " OFFSET " . $_range[ 1 ];
	}
	else if ( $_range[ 2 ] != 0 )
	{
		$query = $_query . " LIMIT " . $_range[ 2 ] . " OFFSET " . $_range[ 3 ];
	}

	return $query;
}

$db = new SQLite3( $channels_file_path );

$index = -1;

$channel_array = [];
$program_array = [];

// Programs that end before this time (UTC) aren't returned. Channels that support catch-up return the programs they can play.
// Recently ended programs are kept so that the guide can fill its current time column.
$min_stop_array = [];
$current_time = time() - 3600;

$tables_exist = 0;

// Do our tables exist?
$query = "SELECT name FROM sqlite_master WHERE type='table'";
$results = $db->query( $query );
while ( $row = $results->fetchArray() )
{
	if ( $row[ "name" ] == "epg" || $row[ "name" ] == "group" || $row[ "name" ] == "channel" || $row[ "name" ] == "group_channel_map" )
	{
		++$tables_exist;
	}
}

if ( $tables_exist == 4 )
{
	$json_array[ "data" ][ "id" ] = $id;
	if ( $id == 0 )
	{
		$json_array[ "data" ][ "name" ] = "Live TV";
	}
	else
	{
		$results = $db->query( "SELECT name FROM [group] WHERE id=" . $id );
		if ( $row = $results->fetchArray() )
		{
			$json_array[ "data" ][ "name" ] = $row[ "name" ];
		}
	}

	$sort_type = "number";
	if ( $sort == 1 )
	{
		$sort_type = "name";
	}

	$t_query = "";

	if ( $id == 1 )	// Get all.
	{
		$t_query = " FROM [channel] ORDER BY " . $sort_type . " ASC";
	}
	else if ( $id == 4 )	// Favorites
	{
		$t_query = " FROM [channel] WHERE favorite = 1 ORDER BY " . $sort_type . " ASC";
	}
	else if ( $id == 5 )	// Search Channels.
	{
		$t_query = " FROM [channel] WHERE id IN (" .
					"SELECT id FROM [channel] WHERE name LIKE '" . $search_query . " %'".
											   " OR name LIKE '% " . $search_query . "'" .
											   " OR name LIKE '% " . $search_query . " %'" .
											   " OR LOWER(name) = '" . strtolower( $search_query ) . "'" .
											   " OR alias LIKE '" . $search_query . " %'".
											   " OR alias LIKE '% " . $search_query . "'" .
											   " OR alias LIKE '% " . $search_query . " %'" .
											   " OR LOWER(alias) = '" . strtolower( $search_query ) . "'" .
					" UNION" .
					" SELECT id FROM [epg] WHERE description LIKE '" . $search_query . " %'".
											" OR description LIKE '% " . $search_query . "'" .
											" OR description LIKE '% " . $search_query . " %'" .
											" OR LOWER(description) = '" . strtolower( $search_query ) . "'" .
					") ORDER BY " . $sort_type . " ASC";
	}
	else
	{
		$t_query = " FROM [channel] WHERE id IN (SELECT channel_id FROM [group_channel_map] WHERE id = " . $id . ") ORDER BY " . $sort_type . " ASC";
	}

	$query = "SELECT COUNT(id)" . $t_query;
	$results = $db->query( $query );
	if ( $row = $results->fetchArray() )
	{
		$total = $row[ "COUNT(id)" ];

		$json_array[ "data" ][ "total" ] = $total;

		if ( $total > 0 )
		{
			$range = GetRange( $total, $limit, $offset );
			$t_query = MakeQuery( $range, "SELECT *" . $t_query );
			$results = $db->query( $t_query );

			while ( $row = $results->fetchArray() )
			{
				if ( !array_key_exists( $row[ "id" ], $channel_array ) )
				{
					$channel_array += array( $row[ "id" ] => ++$index );

					$name = ( $row[ "alias" ] != NULL ? $row[ "alias" ] : $row[ "name" ] );
					$headers = ( $row[ "headers" ] != NULL ? $row[ "headers" ] : "" );

					$catchup_info = GetChannelCatchupInfo( $row );
					$min_stop_array[ $index ] = $current_time - ( $catchup_info[ "catchup_source" ] != "" ? $catchup_info[ "catchup_days" ] * 86400 : 0 );

					array_push( $program_array, array( "id" => $row[ "id" ],
													   "number" => $row[ "number" ],
													   "name" => $name,
													   "guide_id" => $row[ "guide_id" ],
													   "url" => $row[ "url" ],
													   "extension" => $row[ "extension" ],
													   "logo_url" => $row[ "logo_url" ],
													   "headers" => $headers,
													   "favorite" => $row[ "favorite" ],
													   "programs" => [] ) + $catchup_info );
				}
			}

			$query = "SELECT t1.id AS t1_id, t2.id, t2.title, t2.start, t2.stop, t2.description";
			$query .= " FROM (" . $t_query . ") t1";
			$query .= " JOIN";
			$query .= " [epg] t2";
			$query .= " ON t1.guide_id = t2.id";
			$query .= " ORDER BY t2.start ASC";	// The client expects each channel's programs to be in order. Past (catch-up) programs can be added after future ones.

			$results = $db->query( $query );

			while ( $row = $results->fetchArray() )
			{
				$index = $channel_array[ $row[ "t1_id" ] ];

				if ( $row[ "stop" ] <= $min_stop_array[ $index ] )
				{
					continue;
				}

				$row[ "start" ] += $time_zone_offset;
				$row[ "stop" ] += $time_zone_offset;

				// Add the current program to the channel's list of programs.
				array_push( $program_array[ $index ][ "programs" ], array( "title" => $row[ "title" ],
																		   "start" => $row[ "start" ],
																		   "stop" => $row[ "stop" ],
																		   "description" => $row[ "description" ] ) );
			}
		}
	}
}

$db->close();

$json_array[ "data" ][ "values" ] = $program_array;

if ( $tables_exist == 4 )
{
	AddChannelGroupNames( $channels_file_path, $json_array[ "data" ][ "values" ] );
}

header( "Access-Control-Allow-Origin: *" );
echo json_encode( $json_array, JSON_UNESCAPED_SLASHES );
?>
