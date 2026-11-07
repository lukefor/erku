'
'	Erku - IPTV client for the Roku OS
'	Copyright (C) 2024 Eric Kutcher
'	Released under the GPLv3 license.
'

'
'	Catch-up (timeshift/archive) helpers.
'
'	The web manager supplies each channel's CatchupSource: a URL template with time placeholders
'	that's compatible with Kodi's IPTV Simple Client. The placeholders are replaced with a program's
'	times to get the URL of the archived program.
'
'	EPG program times are offset by the web manager's time zone (TimeZoneOffset). They're converted
'	back to UTC before being used in the URL.
'

' Returns the current time in the same (time zone offset) format as the EPG program times.
function Catchup_GetLocalTime() as integer
'{
	date_time = CreateObject( "roDateTime" )
	date_time.ToLocalTime()
	return date_time.AsSeconds()
'}
end function

function Catchup_GetUTCTime() as integer
'{
	date_time = CreateObject( "roDateTime" )
	return date_time.AsSeconds()
'}
end function

' Returns true if the channel can play a program that started at start_time and ends at end_time.
' The times are in the EPG's time format.
' Programs that haven't ended can only be played if allow_current is true.
function Catchup_IsAvailable( channel as object, start_time as integer, end_time as integer, allow_current as boolean ) as boolean
'{
	if channel = invalid or channel.CatchupSource = invalid or channel.CatchupSource = "" or start_time <= 0 or end_time <= start_time
	'{
		return false
	'}
	end if

	current_time = Catchup_GetLocalTime()

	' The program hasn't started.
	if start_time >= current_time
	'{
		return false
	'}
	end if

	' The program hasn't finished.
	if end_time > current_time and allow_current = false
	'{
		return false
	'}
	end if

	' The program is older than what the provider keeps.
	if channel.CatchupDays > 0 and start_time < current_time - ( channel.CatchupDays * 86400 )
	'{
		return false
	'}
	end if

	return true
'}
end function

function Catchup_PadNumber( value as integer, length as integer ) as string
'{
	text = value.ToStr()
	while Len( text ) < length
	'{
		text = "0" + text
	'}
	end while

	return text
'}
end function

' Formats time_val using the letters Y (year), m (month), d (day), H (hours), M (minutes), and S (seconds).
' All other characters are copied as is.
function Catchup_FormatTime( format as string, time_val as integer ) as string
'{
	date_time = CreateObject( "roDateTime" )
	date_time.FromSeconds( time_val )

	text = ""
	for i = 1 to Len( format )
	'{
		c = Mid( format, i, 1 )
		if c = "Y"
		'{
			text = text + Catchup_PadNumber( date_time.GetYear(), 4 )
		'}
		else if c = "m"
		'{
			text = text + Catchup_PadNumber( date_time.GetMonth(), 2 )
		'}
		else if c = "d"
		'{
			text = text + Catchup_PadNumber( date_time.GetDayOfMonth(), 2 )
		'}
		else if c = "H"
		'{
			text = text + Catchup_PadNumber( date_time.GetHours(), 2 )
		'}
		else if c = "M"
		'{
			text = text + Catchup_PadNumber( date_time.GetMinutes(), 2 )
		'}
		else if c = "S"
		'{
			text = text + Catchup_PadNumber( date_time.GetSeconds(), 2 )
		'}
		else
		'{
			text = text + c
		'}
		end if
	'}
	end for

	return text
'}
end function

' Replaces placeholders like {utc:Y-m-d} and ${start:H-M} with the formatted time.
function Catchup_ReplaceFormattedTime( url as string, qualifier as string, time_val as integer ) as string
'{
	position = url.Instr( qualifier )
	while position >= 0
	'{
		format_start = position + Len( qualifier )
		format_end = url.Instr( format_start, "}" )
		if format_end < 0
		'{
			exit while
		'}
		end if

		formatted_time = Catchup_FormatTime( url.Mid( format_start, format_end - format_start ), time_val )

		url = url.Left( position ) + formatted_time + url.Mid( format_end + 1 )

		position = url.Instr( position + Len( formatted_time ), qualifier )
	'}
	end while

	return url
'}
end function

' Replaces placeholders like {duration:60} and {offset:1} with the value divided by the number.
function Catchup_ReplaceUnits( url as string, qualifier as string, value as integer ) as string
'{
	position = url.Instr( qualifier )
	while position >= 0
	'{
		divider_start = position + Len( qualifier )
		divider_end = url.Instr( divider_start, "}" )
		if divider_end < 0
		'{
			exit while
		'}
		end if

		divider = Val( url.Mid( divider_start, divider_end - divider_start ) )
		if divider <= 0
		'{
			divider = 1
		'}
		end if

		text = Int( value / divider ).ToStr()

		url = url.Left( position ) + text + url.Mid( divider_end + 1 )

		position = url.Instr( position + Len( text ), qualifier )
	'}
	end while

	return url
'}
end function

' Returns the URL of an archived program.
' start_utc, end_utc, and now_utc are UTC timestamps.
' time_zone_offset is used for the placeholders that represent a date/time ({Y}, {m}, {utc:Y-m-d}, etc.).
function Catchup_FormatUrl( template as string, start_utc as integer, end_utc as integer, now_utc as integer, time_zone_offset as integer ) as string
'{
	url = template

	duration = end_utc - start_utc
	offset = now_utc - start_utc

	' Formatted dates and times.
	url = Catchup_ReplaceFormattedTime( url, "${start:", start_utc + time_zone_offset )
	url = Catchup_ReplaceFormattedTime( url, "${end:", end_utc + time_zone_offset )
	url = Catchup_ReplaceFormattedTime( url, "${now:", now_utc + time_zone_offset )
	url = Catchup_ReplaceFormattedTime( url, "${timestamp:", now_utc + time_zone_offset )
	url = Catchup_ReplaceFormattedTime( url, "{utc:", start_utc + time_zone_offset )
	url = Catchup_ReplaceFormattedTime( url, "{utcend:", end_utc + time_zone_offset )
	url = Catchup_ReplaceFormattedTime( url, "{lutc:", now_utc + time_zone_offset )

	' Durations/offsets in other units.
	url = Catchup_ReplaceUnits( url, "${duration:", duration )
	url = Catchup_ReplaceUnits( url, "{duration:", duration )
	url = Catchup_ReplaceUnits( url, "${offset:", offset )
	url = Catchup_ReplaceUnits( url, "{offset:", offset )

	' Timestamps. The ${...} forms are replaced first since they contain the {...} forms.
	url = url.Replace( "${start}", start_utc.ToStr() )
	url = url.Replace( "${end}", end_utc.ToStr() )
	url = url.Replace( "${now}", now_utc.ToStr() )
	url = url.Replace( "${timestamp}", now_utc.ToStr() )
	url = url.Replace( "${duration}", duration.ToStr() )
	url = url.Replace( "${offset}", offset.ToStr() )
	url = url.Replace( "{utc}", start_utc.ToStr() )
	url = url.Replace( "{utcend}", end_utc.ToStr() )
	url = url.Replace( "{lutc}", now_utc.ToStr() )
	url = url.Replace( "{duration}", duration.ToStr() )
	url = url.Replace( "{offset}", offset.ToStr() )

	' The program's start date and time.
	for each c in [ "Y", "m", "d", "H", "M", "S" ]
	'{
		url = url.Replace( "{" + c + "}", Catchup_FormatTime( c, start_utc + time_zone_offset ) )
	'}
	end for

	return url
'}
end function

' Returns the URL that plays a channel's program, starting offset seconds after the program begins.
' channel can be a ChannelContentNode of a channel or catch-up program. program is an EPGContentNode.
function Catchup_GetProgramUrl( channel as object, program as object, offset as integer ) as string
'{
	' Program times are offset by the time zone. Convert them back to UTC and apply the provider's correction.
	start_utc = program.start_time + offset - channel.TimeZoneOffset + channel.CatchupCorrection
	end_utc = program.end_time - channel.TimeZoneOffset + channel.CatchupCorrection

	return Catchup_FormatUrl( channel.CatchupSource, start_utc, end_utc, Catchup_GetUTCTime(), channel.TimeZoneOffset )
'}
end function

' Creates a ChannelContentNode that plays the channel's program from its beginning, or offset seconds after it.
' program_index is the index of the channel's EPGContentNode child.
' Returns invalid if the program can't be played.
function Catchup_CreateContent( channel as object, program_index as integer, allow_current as boolean, offset = 0 as integer ) as dynamic
'{
	if channel = invalid or program_index < 0 or program_index >= channel.GetChildCount()
	'{
		return invalid
	'}
	end if

	program = channel.GetChild( program_index )

	if Catchup_IsAvailable( channel, program.start_time, program.end_time, allow_current ) = false
	'{
		return invalid
	'}
	end if

	if offset < 0
	'{
		offset = 0
	'}
	end if

	content = CreateObject( "roSGNode", "ChannelContentNode" )
	content.channel_id = channel.channel_id
	content.group_id = channel.group_id
	content.Number = channel.Number
	content.Title = channel.Title
	content.HDPosterUrl = channel.HDPosterUrl
	content.HttpHeaders = channel.HttpHeaders
	content.Favorite = channel.Favorite
	content.GroupTitle = channel.GroupTitle
	content.CatchupSource = channel.CatchupSource
	content.CatchupStreamFormat = channel.CatchupStreamFormat
	content.CatchupDays = channel.CatchupDays
	content.CatchupCorrection = channel.CatchupCorrection
	content.TimeZoneOffset = channel.TimeZoneOffset

	content.IsCatchup = true
	content.Url = Catchup_GetProgramUrl( channel, program, offset )
	content.CatchupStreamStart = program.start_time + offset
	if channel.CatchupStreamFormat <> ""
	'{
		content.StreamFormat = channel.CatchupStreamFormat
	'}
	else
	'{
		content.StreamFormat = channel.StreamFormat
	'}
	end if

	' The program that's being played. The video info menu displays it.
	program_content = CreateObject( "roSGNode", "EPGContentNode" )
	program_content.Title = program.Title
	program_content.Description = program.Description
	program_content.start_time = program.start_time
	program_content.end_time = program.end_time
	content.AppendChild( program_content )

	return content
'}
end function

' Returns the index of the channel's program that's currently airing, or -1 if there isn't one.
function Catchup_GetCurrentProgramIndex( channel as object ) as integer
'{
	if channel <> invalid
	'{
		current_time = Catchup_GetLocalTime()

		for i = 0 to channel.GetChildCount() - 1
		'{
			program = channel.GetChild( i )
			if program.start_time <= current_time and program.end_time > current_time
			'{
				return i
			'}
			end if
		'}
		end for
	'}
	end if

	return -1
'}
end function
