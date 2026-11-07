'
'	Erku - IPTV client for the Roku OS
'	Copyright (C) 2024 Eric Kutcher
'	Released under the GPLv3 license.
'

sub Init()
'{
	m.top.visible = false

	m.row_width = m.global.screen_width
	m.row_height = 500

	m.row_color = "0x00000000"

	m.column_time_interval = 1800

	m.current_program_end_time = -1

	m.panel = CreateObject( "roSGNode", "Rectangle" )
	m.panel.color = m.global.panel_color
	m.panel.width = m.row_width

	''''''''''''''''''''''''

	m.container = CreateObject( "roSGNode", "Rectangle" )
	m.container.width = m.row_width
	m.container.color = "0x00000000"

	''''''''''''''''''''''''

	row = CreateObject( "roSGNode", "Rectangle" )
	row.width = m.row_width
	row.translation = [ 0, 0 ]
	row.color = m.row_color

		channel_logo_width = 180
		channel_logo_height = 180

		current_time_width = 300

		program_name_width = m.global.screen_width - ( channel_logo_width + 20 ) - ( current_time_width + 20 )

		channel_name_width = program_name_width

		program_description_width = program_name_width

		' Channel Logo
		m.channel_logo = CreateObject( "roSGNode", "Poster" )
		m.channel_logo.loadDisplayMode = "scaleToFit"
		m.channel_logo.width = channel_logo_width
		m.channel_logo.height = channel_logo_height
		m.channel_logo.translation = [ 20, 20 ]
		m.channel_logo.uri = "pkg:/images/no-poster.png"
		row.AppendChild( m.channel_logo )

		' Channel Number
		m.channel_number = CreateObject( "roSGNode", "Label" )
		m.channel_number.width = channel_logo_width
		m.channel_number.numLines = 1
		m.channel_number.translation = [ 20, 20 + channel_logo_height + 20 ]
		m.channel_number.horizAlign = "center"
		row.AppendChild( m.channel_number )

		' Program Name
		m.program_name = CreateObject( "roSGNode", "ScrollingLabel" )
		m.program_name.maxWidth = program_name_width
		m.program_name.translation = [ 20 + channel_logo_width + 20, 20 ]
		m.program_name.font = "font:LargeSystemFont"
		row.AppendChild( m.program_name )
		program_name_height = m.program_name.boundingRect()[ "height" ]

		' Program Time / Channel Name
		m.channel_name = CreateObject( "roSGNode", "Label" )
		m.channel_name.width = channel_name_width
		m.channel_name.numLines = 1
		m.channel_name.translation = [ 20 + channel_logo_width + 20, 20 + program_name_height + 20 ]
		m.channel_name.font = "font:SmallSystemFont"
		row.AppendChild( m.channel_name )
		channel_name_height = m.channel_name.boundingRect()[ "height" ]

		' Program Description
		m.program_description = CreateObject( "roSGNode", "Label" )
		m.program_description.width = program_description_width
		m.program_description.numLines = 3
		m.program_description.translation = [ 20 + channel_logo_width + 20, 20 + program_name_height + 20 + channel_name_height + 20 ]
		m.program_description.wrap = true
		m.program_description.text = ""
		row.AppendChild( m.program_description )
		program_description_height = m.program_description.boundingRect()[ "height" ]

		m.drawing_styles = {
			"icon": {
				"fontSize": 48
				"fontUri": "pkg:/components/fonts/Erku.ttf"
				"color": "#FFFFFFFF"
			}
			"icon_selected": {
				"fontSize": 48
				"fontUri": "pkg:/components/fonts/Erku.ttf"
				"color": "#3070f0FF"
			}
			"default": {
				"fontSize": 48
				"fontUri": "font:LargeSystemFont"
				"color": "#FFFFFFFF"
			}
		}

		' Channel Progress
		progress_bar = CreateObject( "roSGNode", "Rectangle" )
		progress_bar.width = m.global.screen_width - 20 - 20
		progress_bar.translation = [ 20, 20 + program_name_height + 20 + channel_name_height + 20 + program_description_height + 20 ]

			m.progress = CreateObject( "roSGNode", "Poster" )
			m.progress.width = m.global.screen_width - 20 - 20
			m.progress.height = 10
			m.progress.uri = "pkg:/images/progress.9.png"

				m.progress_step = CreateObject( "roSGNode", "Poster" )
				m.progress_step.width = 0
				m.progress_step.height = 10
				m.progress_step.uri = "pkg:/images/progress_step.9.png"
				m.progress.AppendChild( m.progress_step )

			progress_bar.AppendChild( m.progress )

			m.progress_position_info = CreateObject( "roSGNode", "Label" )
			m.progress_position_info.width = 300
			m.progress_position_info.numLines = 1
			m.progress_position_info.translation = [ 0, 20 ]
			m.progress_position_info.font = "font:SmallSystemFont"
			progress_bar.AppendChild( m.progress_position_info )

			m.progress_duration_info = CreateObject( "roSGNode", "Label" )
			m.progress_duration_info.width = 300
			m.progress_duration_info.numLines = 1
			m.progress_duration_info.translation = [ progress_bar.width - 300, 20 ]
			m.progress_duration_info.horizAlign = "right"
			m.progress_duration_info.font = "font:SmallSystemFont"
			progress_bar.AppendChild( m.progress_duration_info )

			progress_buttons = CreateObject( "roSGNode", "Rectangle" )
			progress_buttons.translation = [ ( progress_bar.width - 200 ) / 2, 20 ]

				m.progress_rewind = CreateObject( "roSGNode", "MultiStyleLabel" )
				m.progress_rewind.width = 50
				m.progress_rewind.height = 50
				m.progress_rewind.translation = [ 0, 0 ]
				m.progress_rewind.vertAlign = "center"
				m.progress_rewind.drawingStyles = m.drawing_styles
				m.progress_rewind.text = "<icon>" + chr( 59658 ) + "</icon>"	' Rewind
				progress_buttons.AppendChild( m.progress_rewind )

				m.progress_play_pause_stop = CreateObject( "roSGNode", "MultiStyleLabel" )
				m.progress_play_pause_stop.width = 50
				m.progress_play_pause_stop.height = 50
				m.progress_play_pause_stop.translation = [ 75, 0 ]
				m.progress_play_pause_stop.vertAlign = "center"
				m.progress_play_pause_stop.drawingStyles = m.drawing_styles
				m.progress_play_pause_stop.text = "<icon>" + chr( 59656 ) + "</icon>"	' Play
				progress_buttons.AppendChild( m.progress_play_pause_stop )

				m.progress_fast_forward = CreateObject( "roSGNode", "MultiStyleLabel" )
				m.progress_fast_forward.width = 50
				m.progress_fast_forward.height = 50
				m.progress_fast_forward.translation = [ 150, 0 ]
				m.progress_fast_forward.vertAlign = "center"
				m.progress_fast_forward.drawingStyles = m.drawing_styles
				m.progress_fast_forward.text = "<icon>" + chr( 59659 ) + "</icon>"	' Fast Forward
				progress_buttons.AppendChild( m.progress_fast_forward )

			progress_bar.AppendChild( progress_buttons )

		row.AppendChild( progress_bar )

		''''''''''''''''''''''''

		m.time = CreateObject( "roDateTime" )
		m.time.ToLocalTime()

		' Current Time
		m.current_time = CreateObject( "roSGNode", "Label" )
		m.current_time.width = current_time_width
		m.current_time.numLines = 1
		m.current_time.translation = [ m.global.screen_width - current_time_width - 20, 20 ]
		m.current_time.horizAlign = "right"
		m.current_time.font = "font:LargeSystemFont"
		m.current_time.text = m.time.asTimeStringLoc( "short" )
		row.AppendChild( m.current_time )

	height = 20 + program_name_height + 20 + channel_name_height + 20 + program_description_height + 20 + 50 + 50

	row.height = height
	m.container.AppendChild( row )

	''''''''''''''''''''''''

	m.container.height = height
	m.panel.AppendChild( m.container )

	m.panel.height = height
	m.panel.translation = [ m.global.overscan_offset_x, m.global.overscan_offset_y + ( m.global.screen_height - height ) ]
	m.top.AppendChild( m.panel )

	m.top.ObserveField( "visible", "OnVisible" )

	' Enable when visible, disable when hidden
	m.update_timer = CreateObject( "roSGNode", "Timer" )
	m.update_timer.repeat = true
	m.update_timer.ObserveField( "fire", "UpdateProgressAndTime" )

	''''''''''''''''''''''''

	m.ffrw_speed = 0.2

	m.ffrw_timer = CreateObject( "roSGNode", "Timer" )
	m.ffrw_timer.repeat = true
	m.ffrw_timer.duration = 0.5
	m.ffrw_timer.ObserveField( "fire", "HandleFastForwardRewind" )

	m.ffrw_type = 0	' 0 = off, 1 = fast forward, 2 = rewind
	m.long_ffrw = 0	' If fast forward or frewind are held down for 2.0 seconds.

	''''''''''''''''''''''''

	m.seek_position = 0
	m.seek = false

	''''''''''''''''''''''''

	m.seek_info = { "type": 0, "position": 0, "duration": 0, "max": 0 }

	' Seeks to the selected position shortly after the fast forward/rewind keys are released.
	m.commit_seek_timer = CreateObject( "roSGNode", "Timer" )
	m.commit_seek_timer.repeat = false
	m.commit_seek_timer.duration = 1.5
	m.commit_seek_timer.ObserveField( "fire", "CommitSeek" )

	m.current_content_type = -1

	m.video_format_map = { "hevc": "H.265",
						   "hevc_b": "H.265",
						   "mpeg4_10b": "H.264",
						   "mpeg4_15": "H.264",
						   "mpeg4_2": "H.263",
						   "mpeg2": "H.262",
						   "mpeg1": "H.261",
						   "vp9": "VP9"
						   "vp8": "VP8",
						   "vc1": "VC-1",
						   "wmv": "WMV",
						   "unknown": "Unknown",
						   "none": "None" }

	m.audio_format_map = { "aac": "AAC",
						   "aac_adif": "AAC-ADIF",
						   "aac_adts": "AAC-ADTS",
						   "aac_latm": "AAC-LATM",
						   "ac3": "Dolby Digital",
						   "ac4": "AC-4",
						   "alac": "ALAC",
						   "dts": "DTS"
						   "eac3": "Dolby Digital Plus",
						   "flac": "FLAC",
						   "mat": "Dolby TrueHD",
						   "mp3": "MP3",
						   "pcm": "PCM",
						   "vorbis": "Ogg Vorbis",
						   "wma": "WMA",
						   "wmapro": "WMA Pro",
						   "unknown": "Unknown",
						   "none": "None" }
'}
end sub

sub OnContentChange()
'{
	' Retain the last content type so that the info reflects the most recently played content.
	' If we were to switch from the VOD section to the Live TV section, then this ensures that it still shows the last VOD content that was played.
	m.current_content_type = m.global.current_content_type

	if m.current_content_type = 0
	'{
		m.channel_logo.failedBitmapUri = "pkg:/images/no-channel.png"
	'}
	else
	'{
		m.channel_logo.failedBitmapUri = "pkg:/images/no-poster.png"
	'}
	end if
'}
end sub

sub OnDetailsContentChange()
'{
	if m.top.visible = true and m.top.details_content <> invalid
	'{
		UpdateProgramInfo()
	'}
	end if
'}
end sub

' Returns how the playing video can be seeked.
' type: 0 = can't seek, 1 = seek the video, 2 = a catch-up program, 3 = Live TV that can be rewound using catch-up.
' position, duration, and max (the furthest position that can be seeked to) are in seconds.
' For catch-up programs and Live TV, the values are relative to the beginning of the program.
function GetSeekInfo() as object
'{
	info = { "type": 0, "position": 0, "duration": 0, "max": 0 }

	content = m.top.content
	video = m.top.video

	if content = invalid or video = invalid
	'{
		return info
	'}
	end if

	if content.IsCatchup = true and content.GetChildCount() > 0
	'{
		program = content.GetChild( 0 )

		' A program that's still airing can only be seeked up to the current time.
		available_end_time = program.end_time
		current_time = Catchup_GetLocalTime()
		if available_end_time > current_time
		'{
			available_end_time = current_time
		'}
		end if

		info.type = 2
		info.duration = program.end_time - program.start_time
		info.max = available_end_time - program.start_time
		info.position = ( content.CatchupStreamStart - program.start_time ) + Int( video.position )
		if info.position > info.duration
		'{
			info.position = info.duration
		'}
		end if
	'}
	else if content.IsCatchup = false and content.CatchupSource <> ""
	'{
		program_index = Catchup_GetCurrentProgramIndex( content )
		if program_index <> -1
		'{
			program = content.GetChild( program_index )
			if Catchup_IsAvailable( content, program.start_time, program.end_time, true )
			'{
				info.type = 3
				info.duration = program.end_time - program.start_time
				info.max = Catchup_GetLocalTime() - program.start_time
				info.position = info.max	' We're at the live position.
			'}
			end if
		'}
		end if
	'}
	end if

	if info.type = 0 and video.duration > 0
	'{
		info.type = 1
		info.duration = Int( video.duration )
		info.max = info.duration
		info.position = Int( video.position )
	'}
	end if

	return info
'}
end function

sub UpdateSeekProgress()
'{
	if m.seek_info.duration > 0 and m.progress.width > 0
	'{
		m.progress_step.width = Int( m.seek_position / m.seek_info.duration * m.progress.width )

		m.progress_position_info.text = GetHMS( m.seek_position )
		m.progress_duration_info.text = GetHMS( m.seek_info.duration )
	'}
	end if
'}
end sub

' Starts seeking forward (key = "fastforward") or backward (key = "rewind").
sub StartFastForwardRewind( key as string )
'{
	m.commit_seek_timer.control = "stop"

	if m.seek = false
	'{
		m.seek_info = GetSeekInfo()
		m.seek_position = m.seek_info.position
	'}
	end if

	if m.seek_info.type = 0
	'{
		return
	'}
	end if

	if key = "fastforward"
	'{
		m.ffrw_type = 1

		m.progress_fast_forward.text = "<icon_selected>" + chr( 59659 ) + "</icon_selected>"	' Fast Forward
	'}
	else' if key = "rewind"
	'{
		m.ffrw_type = 2

		m.progress_rewind.text = "<icon_selected>" + chr( 59658 ) + "</icon_selected>"	' Rewind
	'}
	end if

	HandleFastForwardRewind()

	m.ffrw_timer.control = "start"
'}
end sub

' Stops seeking. The position is seeked to once the commit timer fires, or when OK/play is pressed.
sub StopFastForwardRewind()
'{
	if m.ffrw_type = 1	' Fast Forward
	'{
		m.progress_fast_forward.text = "<icon>" + chr( 59659 ) + "</icon>"	' Fast Forward
	'}
	else if m.ffrw_type = 2	' Rewind
	'{
		m.progress_rewind.text = "<icon>" + chr( 59658 ) + "</icon>"	' Rewind
	'}
	end if

	m.ffrw_type = 0

	m.long_ffrw = 0
	m.ffrw_timer.duration = m.ffrw_speed

	m.ffrw_timer.control = "stop"

	if m.seek = true
	'{
		m.commit_seek_timer.control = "start"
	'}
	end if
'}
end sub

' The video player forwards the fast forward/rewind keys that opened the video info menu.
sub OnFastForwardRewindKey()
'{
	if m.top.ffrw_key = "fastforward" or m.top.ffrw_key = "rewind"
	'{
		StartFastForwardRewind( m.top.ffrw_key )
	'}
	else
	'{
		StopFastForwardRewind()
	'}
	end if
'}
end sub

' Seeks to the selected position.
sub CommitSeek()
'{
	m.commit_seek_timer.control = "stop"

	if m.seek = false or m.top.video = invalid
	'{
		return
	'}
	end if

	position = m.seek_position

	m.seek_position = 0
	m.seek = false

	native_seek = false

	if m.seek_info.type = 2	' A catch-up program.
	'{
		program = m.top.content.GetChild( 0 )

		' Seek within the stream if it's possible. Otherwise request the program starting at the new position.
		stream_position = position - ( m.top.content.CatchupStreamStart - program.start_time )
		if m.top.video.duration > 0 and stream_position >= 0 and stream_position <= m.top.video.duration - 5
		'{
			native_seek = true
			position = stream_position
		'}
		else
		'{
			m.top.catchup_seek = position
		'}
		end if
	'}
	else if m.seek_info.type = 3	' Live TV
	'{
		' Stay live if we're close enough to the live position.
		if position < m.seek_info.max - 30
		'{
			m.top.catchup_seek = position
		'}
		end if
	'}
	else if m.seek_info.type = 1
	'{
		native_seek = true
	'}
	end if

	if native_seek = true
	'{
		m.top.video.seek = position

		if m.top.video.state <> "playing" and m.top.video.state <> "paused"
		'{
			m.top.video.control = "play"
		'}
		end if
	'}
	end if

	if m.top.video.state <> "paused"
	'{
		m.progress_play_pause_stop.text = "<icon>" + chr( 59657 ) + "</icon>"	' Pause
	'}
	end if

	UpdateProgressAndTime()
'}
end sub

sub HandleFastForwardRewind()
'{
	if m.top.video <> invalid and m.ffrw_type <> 0
	'{
		' Speed up the timer if the key was held down long enough.
		if m.long_ffrw < 600
		'{
			m.long_ffrw++

			if m.long_ffrw = 3
			'{
				m.ffrw_timer.duration = 0.1
			'}
			else if m.long_ffrw = 30
			'{
				m.ffrw_timer.duration = 0.01
			'}
			end if
		'}
		end if

		' The first press skips 10 seconds. Holding the key down speeds it up.
		seek_position = 10

		if m.long_ffrw > 1 and m.long_ffrw < 200
		'{
			seek_position = 1
		'}
		else if m.long_ffrw >= 200 and m.long_ffrw < 400
		'{
			seek_position = 5
		'}
		else if m.long_ffrw >= 400 and m.long_ffrw < 600
		'{
			seek_position = 10
		'}
		else if m.long_ffrw = 600
		'{
			seek_position = 20
		'}
		end if

		if m.ffrw_type = 1	' Fast Forward
		'{
			m.seek_position = m.seek_position + seek_position

			if m.seek_position > m.seek_info.max
			'{
				m.seek_position = m.seek_info.max
			'}
			end if
		'}
		else' if m.ffrw_type = 2	' Rewind
		'{
			m.seek_position = m.seek_position - seek_position

			if m.seek_position < 0
			'{
				m.seek_position = 0
			'}
			end if
		'}
		end if

		m.seek = true

		UpdateSeekProgress()
	'}
	end if
'}
end sub

' time_val is in seconds.
function FormatRuntime( time_val as integer ) as string
'{
	hours = int( time_val / 3600 )
	minutes = int( time_val / 60 ) MOD 60

	if hours > 0
	'{
		if minutes > 0
		'{
			return hours.ToStr() + "h " + minutes.ToStr() + "m"
		'}
		else
		'{
			return hours.ToStr() + "h"
		'}
		end if
	'}
	else if minutes > 0
	'{
		return minutes.ToStr() + "m"
	'}
	end if

	return ""
'}
end function

sub UpdateProgramInfo()
'{
	date_time = CreateObject( "roDateTime" )
	date_time.Mark()
	date_time.ToLocalTime()
	time = date_time.AsSeconds()

	first_time_column_time = time - ( time mod m.column_time_interval )

	m.current_program_end_time = -1

	if m.top.content <> invalid
	'{
		program_name_text = "No information"
		program_description_text = ""
		channel_number_text = ""
		poster_url = m.top.content.HDPosterUrl

		release_info = []

		audio_format = ""
		video_format = ""

		' The formats don't reset if we change videos. So wait until it's done buffering to set the strings.
		if m.top.video <> invalid and m.top.video.state <> "buffering"
		'{
			if m.top.video.audioFormat <> "" and m.audio_format_map.Lookup( m.top.video.audioFormat ) <> invalid
			'{
				audio_format = m.audio_format_map[ m.top.video.audioFormat ]
			'}
			end if

			if m.top.video.videoFormat <> "" and m.video_format_map.Lookup( m.top.video.videoFormat ) <> invalid
			'{
				video_format = m.video_format_map[ m.top.video.videoFormat ]
			'}
			end if
		'}
		end if

		if m.current_content_type = 0 and m.top.content.IsCatchup = true	' A Live TV program that's being played using catch-up.
		'{
			if m.top.content.GetChildCount() > 0
			'{
				program = m.top.content.GetChild( 0 )

				program_name_text = program.Title
				program_description_text = program.Description

				date_time.FromSeconds( program.start_time )
				time_string = date_time.asDateStringLoc( "EEE, MMM d" ) + " • " + date_time.asTimeStringLoc( "hh:mm a" ) + " - "
				date_time.FromSeconds( program.end_time )
				time_string = time_string + date_time.asTimeStringLoc( "hh:mm a" ) + " • " + FormatRuntime( program.end_time - program.start_time )

				release_info.Push( time_string )
			'}
			end if

			release_info.Push( "Catch-up" )
			if m.top.content.GroupTitle <> ""
			'{
				release_info.Push( m.top.content.GroupTitle )
			'}
			end if

			channel_number_text = m.top.content.Number.ToStr()
		'}
		else if m.current_content_type = 0	' Live TV
		'{
			last_program_index = m.top.content.GetChildCount() - 1

			if last_program_index >= 0
			'{
				start_time = -1
				end_time = -1

				current_program_index = 0
				remove_num_children = 0

				for i = 0 to last_program_index
				'{
					end_time = m.top.content.GetChild( i ).end_time

					' Remove programs that have ended.
					if first_time_column_time >= end_time
					'{
						remove_num_children++

						end_time = -1
					'}
					else	' Go through the remaining programs and find the one that falls within the current time.
					'{
						start_time = m.top.content.GetChild( i ).start_time

						' The program falls within the current time.
						if time >= start_time and time < end_time
						'{
							m.current_program_end_time = end_time

							exit for
						'}
						else if time < start_time	' The program hasn't begun. We're sitting on a gap.
						'{
							end_time = start_time
							if i > 0
							'{
								start_time = m.top.content.GetChild( i - 1 ).end_time
							'}
							else
							'{
								start_time = first_time_column_time
							'}
							end if

							current_program_index = -1

							m.current_program_end_time = end_time

							exit for
						'}
						else if i = last_program_index	' There's no more programs.
						'{
							start_time = -1
							end_time = -1
							current_program_index = -1

							exit for
						'}
						end if

						current_program_index++
					'}
					end if
				'}
				end for

				if remove_num_children > 0
				'{
					' Channels that support catch-up keep the programs that have ended so that they can be selected in the guide.
					if m.top.content.CatchupSource = ""
					'{
						m.top.content.RemoveChildrenIndex( remove_num_children, 0 )
					'}
					else if current_program_index <> -1
					'{
						current_program_index = current_program_index + remove_num_children
					'}
					end if
				'}
				end if

				if start_time > 0 and end_time > start_time
				'{
					if current_program_index <> -1
					'{
						program_name_text = m.top.content.GetChild( current_program_index ).Title
						program_description_text = m.top.content.GetChild( current_program_index ).Description
					'}
					end if

					date_time.FromSeconds( start_time )
					time_string = date_time.asTimeStringLoc( "hh:mm a" ) + " - "
					date_time.FromSeconds( end_time )
					time_string = time_string + date_time.asTimeStringLoc( "hh:mm a" ) + " • " + FormatRuntime( end_time - start_time )' + " • "

					release_info.Push( time_string )
				'}
				end if
			'}
			end if

			if m.top.content.GroupTitle <> ""
			'{
				release_info.Push( m.top.content.GroupTitle )
			'}
			end if

			channel_number_text = m.top.content.Number.ToStr()
		'}
		else	' A Movie or TV Show
		'{
			if m.current_content_type = 2	' TV Show
			'{
				title = ""
				if m.top.content.Title <> ""
				'{
					title = " - " + m.top.content.Title
				'}
				end if
				program_name_text = m.top.content.SeriesTitle + title
			'}
			else if m.current_content_type = 1	' Movie
			'{
				program_name_text = m.top.content.Title
			'}
			end if

			if m.top.details_content <> invalid
			'{
				program_description_text = m.top.details_content.Description

				if m.top.details_content.ReleaseDate <> ""
				'{
					release_info.Push( m.top.details_content.ReleaseDate )
				'}
				else if m.top.content.Year <> ""
				'{
					release_info.Push( m.top.content.Year )
				'}
				end if
				if m.top.details_content.Rating <> ""
				'{
					release_info.Push( m.top.details_content.Rating )
				'}
				end if
				formatted_runtime = FormatRuntime( m.top.details_content.Runtime * 60 )
				if formatted_runtime <> ""
				'{
					release_info.Push( formatted_runtime )
				'}
				end if

				if m.top.details_content.HDPosterUrl <> ""
				'{
					poster_url = m.top.details_content.HDPosterUrl
				'}
				end if
			'}
			else
			'{
				if m.top.content.Year <> ""
				'{
					release_info.Push( m.top.content.Year )
				'}
				end if
			'}
			end if
		'}
		end if

		if audio_format <> ""
		'{
			release_info.Push( audio_format )
		'}
		end if
		if video_format <> ""
		'{
			release_info.Push( video_format )
		'}
		end if
		m.channel_name.text = release_info.Join( " • " )

		m.program_name.text = program_name_text
		m.program_description.text = program_description_text

		if m.channel_logo.uri <> poster_url
		'{
			m.channel_logo.loadingBitmapUri = m.channel_logo.uri
			if poster_url = ""
			'{
				if m.current_content_type = 0
				'{
					poster_url = "pkg:/images/no-channel.png"
				'}
				else if m.current_content_type = 1 or m.current_content_type = 2
				'{
					poster_url = "pkg:/images/no-poster.png"
				'}
				end if
			'}
			end if
			m.channel_logo.uri = poster_url
		'}
		end if

		m.channel_number.text = channel_number_text
	'}
	end if
'}
end sub

sub OnVisible()
'{
	if m.top.visible = true
	'{
		if m.top.video <> invalid
		'{
			if m.top.video.state = "playing"
			'{
				m.progress_play_pause_stop.text = "<icon>" + chr( 59657 ) + "</icon>"	' Pause
			'}
			else
			'{
				m.progress_play_pause_stop.text = "<icon>" + chr( 59656 ) + "</icon>"	' Play
			'}
			end if
		'}
		end if

		UpdateProgramInfo()

		UpdateProgressAndTime()
		m.update_timer.control = "start"
	'}
	else
	'{
		m.update_timer.control = "stop"

		' Cancel any seeking.
		m.seek_position = 0
		m.seek = false

		StopFastForwardRewind()
		m.commit_seek_timer.control = "stop"
	'}
	end if
'}
end sub

function GetHMS( time_val as double ) as string
'{
	hours = int( time_val / 3600 )
	minutes = int( time_val / 60 ) MOD 60
	seconds = time_val MOD 60

	hr = hours.ToStr()
	if hours <= 9
	'{
		hr = "0" + hr
	'}
	end if

	min = minutes.ToStr()
	if minutes <= 9
	'{
		min = "0" + min
	'}
	end if

	sec = seconds.ToStr()
	if seconds <= 9
	'{
		sec = "0" + sec
	'}
	end if

	return hr + ":" + min + ":" + sec
'}
end function

sub UpdateProgressAndTime()
'{
	m.time.Mark()
	m.time.ToLocalTime()
	m.current_time.text = m.time.asTimeStringLoc( "short" )

	' Update the info if a new Live TV program is playing.
	if m.time.AsSeconds() > m.current_program_end_time and m.current_program_end_time <> -1
	'{
		UpdateProgramInfo()
	'}
	end if

	if m.seek = true
	'{
		UpdateSeekProgress()
	'}
	else if m.top.video <> invalid and m.top.video.state <> "buffering"
	'{
		info = GetSeekInfo()
		if info.duration > 0 and m.progress.width > 0
		'{
			if info.position <= info.duration
			'{
				m.progress_step.width = Int( info.position / info.duration * m.progress.width )
			'}
			else
			'{
				m.progress_step.width = m.progress.width
			'}
			end if

			m.progress_position_info.text = GetHMS( info.position )
			m.progress_duration_info.text = GetHMS( info.duration )
		'}
		end if
	'}
	end if
'}
end sub

sub OnResume()
'{
	if m.top.resume = true
	'{
		m.top.resume = false

		' The video errored and we're resuming.
		if m.top.video <> invalid and m.top.video.state <> "playing" and m.top.video.state <> "paused"
		'{
			m.seek_info = { "type": 1, "position": Int( m.top.video.position ), "duration": Int( m.top.video.duration ), "max": Int( m.top.video.duration ) }
			if m.seek_info.max < m.seek_info.position
			'{
				m.seek_info.max = m.seek_info.position
			'}
			end if
			m.seek_position = m.seek_info.position
			m.seek = true
		'}
		end if
	'}
	end if
'}
end sub

function OnKeyEvent( key as string, press as boolean ) as boolean
'{
	if press
	'{
		if key = "back"
		'{
			m.top.menu_state = 0	' Hide
		'}
		else if key = "OK"
		'{
			CommitSeek()
		'}
		else if key = "play"
		'{
			if m.top.video <> invalid
			'{
				if m.seek = true
				'{
					CommitSeek()
				'}
				else if m.top.video.state = "playing"
				'{
					m.top.video.control = "pause"

					m.progress_play_pause_stop.text = "<icon>" + chr( 59656 ) + "</icon>"	' Play
				'}
				else if m.top.video.state = "paused"
				'{
					m.top.video.control = "resume"

					m.progress_play_pause_stop.text = "<icon>" + chr( 59657 ) + "</icon>"	' Pause
				'}
				else
				'{
					m.seek_info = GetSeekInfo()
					m.seek_position = m.seek_info.position
					m.seek = true

					CommitSeek()

					m.top.video.control = "play"

					m.progress_play_pause_stop.text = "<icon>" + chr( 59657 ) + "</icon>"	' Pause
				'}
				end if
			'}
			end if
		'}
		else if key = "fastforward" or key = "rewind"
		'{
			StartFastForwardRewind( key )
		'}
		else if key = "replay"
		'{
			if m.top.video <> invalid
			'{
				if m.seek = false
				'{
					m.seek_info = GetSeekInfo()
					m.seek_position = m.seek_info.position
				'}
				end if

				if m.seek_info.type <> 0
				'{
					' Toggle between setting the seek position from the beginning and end of the video.
					if m.seek = true and m.seek_position = 0
					'{
						m.seek_position = m.seek_info.max
					'}
					else
					'{
						m.seek_position = 0
					'}
					end if

					m.seek = true

					UpdateSeekProgress()

					m.commit_seek_timer.control = "start"
				'}
				end if
			'}
			end if
		'}
		end if
	'}
	else if not press
	'{
		if key = "fastforward" or key = "rewind"
		'{
			StopFastForwardRewind()
		'}
		end if
	'}
	end if

	return true
'}
end function
