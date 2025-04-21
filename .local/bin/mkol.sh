#!/bin/bash

# mkopuslibrary
# A Bash script for converting trees of FLAC files into trees of Opus files
# call with -h for complete usage, configuration, and dependency info

#      _       __             _ _              _   _   _
#   __| | ___ / _| __ _ _   _| | |_   ___  ___| |_| |_(_)_ __   __ _ ___
#  / _` |/ _ \ |_ / _` | | | | | __| / __|/ _ \ __| __| | '_ \ / _` / __|
# | (_| |  __/  _| (_| | |_| | | |_  \__ \  __/ |_| |_| | | | | (_| \__ \
#  \__,_|\___|_|  \__,_|\__,_|_|\__| |___/\___|\__|\__|_|_| |_|\__, |___/
# (default settings)                                           |___/

# override any/all default settings by placing a user-configuration file at one of these locations:
# "${HOME}/.config/mkolrc"  |  "${HOME}/.config/mkopuslibrary/mkolrc"  |  "${HOME}/.mkolrc"

# parent FLAC source folder - must already exist
source="/flac"

# parent Opus/lossy target folder - must already exist
target="/opus"

# size limits in KB for artwork sources to copy or embed
# set to "0" or leave unset (eg: ="") to disable either art source size limit
art_copy_size_limit="0"
art_embed_size_limit="0"

# bitrate for opusenc in Kbps - if unset, or value is invalid, defaults to "96"
bitrate_opus="96"

# set to "1" to disable embedding detected artwork files AND to also ignore any
# artwork embedded in source FLACs when copying Vorbis tags to Opus outputs
# when enabled, this option overrides the 'embed_artwork' setting
discard_embedded="0"

# set to "1" to embed detected source artwork files in Opus outputs
# when disabled, unless disacrd_embedded is enabled, any source-embedded art will still be embedded in outputs
embed_artwork="0"

# "1" emits success/fail messages for each target file
# any other setting provides an overall status display w/ elapsed time, eta, and a count of jobs (total, successful, failed)
emit_per_file="0"

# *directory* paths containing this string will be excluded
exclude="__excluded__"

# - "1" skips checking for existing opus files in target dirs, potentially overwriting them (or piling them up redundantly) if they do exist
# - any other setting skips encoding any target dir where the number of existing opus files >= to that of source flacs, and if there are fewer
#   existing targets than flacs, those targets may still be overwritten (or piled up redundantly)
force_opusenc="0"

# "1" ignores existing artwork files in target folders, which would otherwise prevent copying art to those folders
force_copy_artwork="0"

# "N" or "+N" sets the maximum number of simultaneous jobs to "N"
# "0" sets the maximum number of simultaneous jobs to the number of available CPU cores
# "-N" sets the maximum number of simultaneous jobs to "N" less than the number of available CPU cores
jobs="2"

# folder to save any log files in - must already exist
# if log_failure_lists is enabled but log_dir is unset or invalid, defaults to $target (or the argument to --target, when used)
log_dir=""

# set "1" to save arrays of failed mkdirs, and missing and oversized artwork dirs, to log files in $log_dir
# in-progress option/feature -- should be functional
log_failure_lists="1"

# set "1" to print arrays of failed mkdirs, dirs missing artwork, and dirs containing oversized artwork, to stdout after all operations are completed
# this only toggles printing the full list(s), total numbers (when >0) for each type of failure are printed regardless of whether this option is enabled
# in-progress option/feature -- should be functional
print_failure_lists="0"

# setting any of the following to "1" includes the feature in default actions
copy_artwork="n"  # -y | -Y
copy_mp3s="n"     # -m | -M
encode_opus="1"   # -e | -E
find_orphans="n"  # -x | -X

#                 _          __            _   _   _
#   ___ _ __   __| |   ___  / _|  ___  ___| |_| |_(_)_ __   __ _ ___
#  / _ \ '_ \ / _` |  / _ \| |_  / __|/ _ \ __| __| | '_ \ / _` / __|
# |  __/ | | | (_| | | (_) |  _| \__ \  __/ |_| |_| | | | | (_| \__ \
#  \___|_| |_|\__,_|  \___/|_|   |___/\___|\__|\__|_|_| |_|\__, |___/
#  (end of settings)                                       |___/




# https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_(Control_Sequence_Introducer)_sequences
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR
# https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
#         ^^ "ESC[39;49m (not supported on some terminals)" (in the old times? not terminal emulators?)

# FG BG                   # FG  BG
# 30 40 Black             # 90 100 Bright Black (Gray)
# 31 41 Red               # 91 101 Bright Red
# 32 42 Green             # 92 102 Bright Green
# 33 43 Yellow            # 93 103 Bright Yellow
# 34 44 Blue              # 94 104 Bright Blue
# 35 45 Magenta           # 95 105 Bright Magenta
# 36 46 Cyan              # 96 106 Bright Cyan
# 37 47 White             # 97 107 Bright White
# 39 49 Default Colour

# if command -v tput >/dev/null 2>&1 ;then
# 	colour=$( tput something something )
# else
d='\033[0m'     # reset all attributes to default
u='\033[4m'     # underline
r='\033[0;31m'  # red
g='\033[0;32m'  # green
o='\033[0;33m'  # orange
b='\033[1;39m'  # 1: bold, 39: default fg colour
f='\033[41;97m' # red bg; bright white fg

clear_cte='\033[0K' # clear [from] cursor to end [of line]
#hide_cursor='\033[?25l'
#show_cursor='\033[?25h'
# fi


# _check_[type] functions:
# -take a single directory as argument
# -populate '[type]_files' arrays, and return 0 when [type] files are found, or unset array and return 1
# -test existence of first element - without nullglob, '[type]_files[0]' still contains the literal glob when no [type] files exist

# _check_artwork takes an additional "mode" argument, '-copy' or '-embed', and loops through one or more artwork files
# -it returns 0 when $art_file has been set to an artwork file that is within any applied size limits
# -it returns 1 when every file it checked was over the given size limit
_check_artwork() {
	local limit art_size
	case $1 in
		-copy)  limit="$art_copy_size_limit" ;;
		-embed) limit="$art_embed_size_limit" ;;
	esac
	shift
	for artfile in "$@" ;do
		((limit)) && {
			art_size="$( wc -c "$artfile" |awk '{ print $1 }' )"
			((  art_size / 1024 > limit  )) && continue
		}
		art_file="${artfile##*/}"
		return 0
	done
	# no artwork file was within applied limits
	return 1
}

_check_flac() {
	flac_files=( "${1%/}"/*.[Ff][Ll][Aa][Cc] )
	if [[ -e ${flac_files[0]} ]] ;then
		return 0
	else
		unset flac_files
		return 1
	fi
}

_check_mp3() {
	mp3_files=( "${1%/}"/*.[Mm][Pp]3 )
	if [[ -e ${mp3_files[0]} ]] ;then
		return 0
	else
		unset mp3_files
		return 1
	fi
}

_check_opus() {
	opus_files=( "${1%/}"/*.[Oo][Pp][Uu][Ss] )
	if [[ -e ${opus_files[0]} ]] ;then
		return 0
	else
		unset opus_files
		return 1
	fi
}


_copy_artwork() {
	# copies any $source_artworks to $target_artworks
	# prints list of flac-containing folders with no $artwork_name file

	printf -- ' %b*%b handling artwork ...\n' "$b" "$d"
	#if [[ -n "${source_artworks[*]}" ]] ;then
	if (( ${#source_artworks[@]} )) ;then
		printf -- '   %b->%b copying %s artwork file%s ... ' "$b" "$d" "${#source_artworks[@]}" \
			   "$( (( ${#source_artworks[@]} > 1 )) && printf '%s' "s" )"
		SECONDS="0"

		#printf 'artwork targets:\n';printf '  %s\n' "${source_artworks[@]}"
		for i in "${!source_artworks[@]}" ;do
			cp -a -- "${source_artworks[$i]}" "${target_artworks[$i]}"
		done

		printf -- '%s seconds\n\n' "$SECONDS"
	else
		printf -- '   %b->%b no artwork files to copy\n\n' "$b" "$d"
	fi
}


_copy_mp3s() {
	# copies *.mp3 from $source_mp3_copy_dirs to $target_mp3_copy_dirs
	printf -- ' %b*%b handling MP3s ...\n' "$b" "$d"
	if (( ${#source_mp3_copy_dirs[@]} )) ;then
		printf -- '   %b->%b copying from %s source %s ... ' "$b" "$d" "${#target_mp3_copy_dirs[@]}" "$( _dir_or_dirs "${#target_mp3_copy_dirs[@]}" )"
		SECONDS="0"
		for i in "${!source_mp3_copy_dirs[@]}" ;do
			cp -a -- "${source_mp3_copy_dirs[$i]}"/*.[Mm][Pp]3 "${target_mp3_copy_dirs[$i]}"
		done
		printf -- '%s seconds\n\n' "$SECONDS"
	else
		printf -- '   %b->%b no MP3s to copy\n\n' "$b" "$d"
	fi
}


_dir_or_dirs() {
	# really wants to be called _pluralizer or something and also handle other plural suffixes
	# until then this if statement is called at least 4 times so here we are
	if (( $1 == 1 )) ;then printf 'directory' ;else printf 'directories' ;fi
}


_encode_opus() {
	# takes a single source_files INDEX as argument, uses source_files and target_files arrays, source_embed_artworks array, discard_embedded var
	# encodes opus at $bitrate_opus (embedding in target ${source_embed_artworks[INDEX]}, if it exists and embedding is enabled)
	# returns 0 on opusenc success, 1 on opusenc failure
	# emits messages or doesn't, depending on $emit_per_file

	SECONDS="0"

	#sfi="$1"
	if [[ -n "${source_embed_artworks[$1]}" ]] ;then
		if opusenc --quiet --bitrate "$bitrate_opus" --discard-pictures --picture "${source_embed_artworks[$1]}" -- "${source_files[$1]}" "${target_files[$1]}" ;then
			((emit_per_file)) && printf '   %s: %b[%bEncoded!%b]%b [%ss]\n\n' "${target_files[$1]}" "$b" "$g" "$b" "$d" "$SECONDS"
			return 0
		else
			((emit_per_file)) && printf '   %s: %b[Failed!]%b\n\n' "${target_files[$1]}" "$f" "$d"
			return 1
		fi

	elif ((discard_embedded)) ;then
		if opusenc --quiet --bitrate "$bitrate_opus" --discard-pictures -- "${source_files[$1]}" "${target_files[$1]}" ;then
			((emit_per_file)) && printf '   %s: %b[%bEncoded!%b]%b [%ss]\n\n' "${target_files[$1]}" "$b" "$g" "$b" "$d" "$SECONDS"
			return 0
		else
			((emit_per_file)) && printf '   %s: %b[Failed!]%b\n\n' "${target_files[$1]}" "$f" "$d"
			return 1
		fi

	else
		if opusenc --quiet --bitrate "$bitrate_opus" -- "${source_files[$1]}" "${target_files[$1]}" ;then
			((emit_per_file)) && printf '   %s: %b[%bEncoded!%b]%b [%ss]\n\n' "${target_files[$1]}" "$b" "$g" "$b" "$d" "$SECONDS"
			return 0
		else
			((emit_per_file)) && printf '   %s: %b[Failed!]%b\n\n' "${target_files[$1]}" "$f" "$d"
			return 1
		fi
	fi
}


_find_orphans() {
	# prints a list of orphaned dirs in target

	local parent_target_dir parent_target_dirs orphan_dirs

	# construct canonical/ized target parent equivalents of/from source parents
	for dir in "${parent_source_dirs[@]}" ;do
		parent_target_dir="${dir#"$source"}"
		parent_target_dir="$( "$realpath" -qe -- "${target}/${parent_target_dir#/}" )" && parent_target_dirs+=( "$parent_target_dir" )
	done

	# create target_dirs array from output of `_get_dirs "${parent_target_dirs[@]}"`
	printf -- ' %b*%b checking for orphan target directories ... \n   %b->%b collecting dir(s) in target(s) ... ' "$b" "$d" "$b" "$d"
	SECONDS="0"
	_get_dirs "${parent_target_dirs[@]}"
	target_dirs=( "${unique_dirs[@]}" )
	printf -- '%s target %s, %s seconds\n' "${#target_dirs[@]}" \
		   "$( if (( "${#target_dirs[@]}" == 1 )) ;then printf 'directory' ;else printf 'directories' ;fi )" "$SECONDS"
	printf -- '   %b->%b comparing ... ' "$b" "$d"
	SECONDS="0"

	# https://unix.stackexchange.com/a/178335 / Comparing directories using diff
	# http://mywiki.wooledge.org/BashGuide/InputAndOutput#Process_Substitution
	# readarray -d '' -t orphan_dirs < <( comm -z -13 <( printf '%s\0' "${source_dirs[@]#$source}"  ) <( printf '%s\0' "${target_dirs[@]#$target}" ) )
	while IFS= read -r -d '' orphan_dir ;do
		orphan_dirs+=( "$orphan_dir" )
		# use comm to generate a list of target_dirs with no source_dirs equivalent
	done < <( "$comm" -z -13 <( printf -- '%s\0' "${source_dirs[@]#"$source"}" ) <( printf -- '%s\0' "${target_dirs[@]#"$target"}" ) )
		                                   # using "#$source/" or "#$target/" as the pattern here only works for subdirectories
	                                       # strip the now-leading slash when printing the orphan_dirs array below

	# perhaps this part can be at the end of the script with the other log/print sections? ... using $SECONDS is probably more complicated
	if (( ${#orphan_dirs[@]} )) ;then
		printf -- '%s orphan %s, %s seconds\n' "${#orphan_dirs[@]}" "$( _dir_or_dirs "${#orphan_dirs[@]}" )" "$SECONDS"

		((print_failure_lists)) && {
			printf -- '      %s\n' "${orphan_dirs[@]#/}"
		}

		((log_failure_lists)) && {
			# create orphan_paths earlier, use for ((print_failure_lists)) also?
			for i in "${!orphan_dirs[@]}" ;do
				orphan_paths[$i]="${target}/${orphan_dirs[$i]#/}"
			done

			[[ -s ${log_dir}/mkol-orphaned-target-dirs.txt ]] && mv "${log_dir}/mkol-orphaned-target-dirs.txt" "${log_dir}/mkol-orphaned-target-dirs.txt.old"
			printf -- '%s\n' "${orphan_paths[@]}" > "${log_dir}/mkol-orphaned-target-dirs.txt"
		}

		printf '\n'
	else
		printf -- '0 orphan directories found, %s seconds\n\n' "$SECONDS"
	fi
}


_generate_timestamp() { # convert seconds into '00h 00m 00s'
	local seconds minutes hours
	  hours=$(( "$1" / 3600  ))
	seconds=$(( "$1" % 3600 ))
	minutes=$(( "$seconds" / 60 ))
	seconds=$(( "$seconds" % 60 ))
	printf '%02dh %02dm %02ds' "$hours" "$minutes" "$seconds" # use '\n' when calling _generate_timestamp
}


_get_dirs() {
	# takes one or more directories as arguments, expects arguments are existing, verified directories
	# populates 'unique_dirs' array with absolute paths to parent folder(s) and all subfolders
	# /should/ always output at least the arguments provided, no return code

	local dirs
	unset unique_dirs

	if shopt -s globstar ;then # prefer globstar
		while [[ $# -gt 0 ]] ;do
			dirs+=( "${1%/}"/**/ ) # trailing slash
			shift
		done
		shopt -u globstar
	else                       # support find also ... but remember that threading with 'wait -n' requires bash 4.3+ anyway, so... usefulness?
		while [[ $# -gt 0 ]] ;do
			while IFS= read -r -d '' dir ;do # https://stackoverflow.com/a/23357277
				dirs+=( "$dir" )             # https://unix.stackexchange.com/questions/209123/understanding-ifs-read-r-line
			done < <( find "$1" -type d -print0 )
			shift
		done
	fi

	# sorting uniq-ly
	while IFS= read -r -d '' dir ;do
		[[ $dir == *"$exclude"* ]] && continue
		unique_dirs+=( "$dir" )
	done < <( printf '%s\0' "${dirs[@]%/}" |sort -zu ) # no trailing slash
}


_get_targets() { # v2.6
	# takes one source_dirs _index_ as argument, uses source_dirs array, source/target variables
	# creates various arrays depending on operating mode, source/target files, artworks, source_embed_artworks, mp3 dirs, failed_mkdirs ...

	local sdi source_dir encode_opus_local copy_mp3s_local \
		  flac_files existing_flacs mp3_files existing_mp3s target_dir existing_target_dir opus_files source_mp3_files
		  # found_artwork mp3_file encode_mp3s_local copy_aac_local

	sdi="$1"
	source_dir="${source_dirs[$sdi]}"

	encode_opus_local="$encode_opus"
	copy_mp3s_local="$copy_mp3s"
	# and maybe, eventually, at some point, before too long:
	#encode_mp3s_local="0"
	#copy_aac_local="0" # probably never happening, m4a, mp4, either could ALAC, or AAC, or some other thing

	# for tasks requiring flac files in $source_dir, check for flac files
	{ ((encode_opus_local)) || ((copy_artwork)) ; } && { # || ((encode_mp3s_local)) 
		_check_flac "$source_dir" && existing_flacs="1"
	}

	# for tasks requiring mp3 files in $source_dir, check for mp3 files
	# but not for ((copy_artwork)) task unless there are also no flacs_files
	{ ((copy_mp3s_local)) || { ((copy_artwork)) && (( existing_flacs != 1 )) ; } ; } && { # || ((copy_aac_local)) 
		_check_mp3  "$source_dir" && existing_mp3s="1"
		# _check_aac ...
	}

	### there are flacs or mp3s ###
	{ ((existing_flacs)) || ((existing_mp3s)) ; } && {
		# remove the root/parent source path from this specific source_dir
		# don't add a slash to the pattern here -- if $source_dir == $source, '$source/' isn't a match
		target_dir="${source_dir#"$source"}"
		# remove leading slash from/when $target_dir is a subdir of $source, else #/ has no effect (? methinks)
		target_dir="${target}/${target_dir#/}"
		[[ -d $target_dir ]] && existing_target_dir="1"

		### check for existing target opus files, unless forcing is on ###
		((force_opusenc)) || {
			### target_dir exists, there are flacs, and opus encoding is enabled ###
			((existing_target_dir)) && ((existing_flacs)) && ((encode_opus_local)) && {
				# disable opus encoding if there are more opus targets than flac sources
				# perhaps we should 'rm -f -- $target_dir/*.[Oo][Pp][Uu][Ss]' and re-encode dir when numbers are != ??
				_check_opus "$target_dir" && [[ ${#flac_files[@]} -le "${#opus_files[@]}" ]] &&
					encode_opus_local="0"
			} ### /target_dir exists, there are flacs, and opus encoding is enabled ###
		} ### /check for existing target opus files, unless forcing is on ###

		# ((force_lame)) || {
		# 	((rules for skipping mp3 encodes))
		# }

		### check for existing target mp3 files ###
		((existing_target_dir)) && ((existing_mp3s)) && ((copy_mp3s_local)) && {
			source_mp3_files=( "${mp3_files[@]}" )
			# 'mp3_files' is reset when _check_mp3 called
			_check_mp3 "$target_dir" && {
				# more thoroughness here perhaps ?? exact filenames /ie: per-file?
				# ? just rm -f $target_dir/*.mp3 if any exist, or if non-equal # to source_dir ?
				[[ "${#source_mp3_files[@]}" -le "${#mp3_files[@]}" ]] &&
					copy_mp3s_local="0"
			}
		} ### /check for existing target mp3 files ###

		### $target_dir does not exist ###
		((existing_target_dir)) || {
			### and we are encoding opus or copying mp3s ... OR COPYING ARTWORK ###
			{ ((encode_opus_local)) || ((copy_mp3s_local)) || ((copy_artwork)) ; } && {
				mkdir -p -- "$target_dir" >/dev/null 2>&1 || {
					failed_mkdirs[$sdi]="$target_dir"
 					return 1
				}
				existing_target_dir="1"
			} ### /and we are encoding opus or copying mp3s ###
		} ### /$target_dir does not exist ###

		### find artwork files, add to source_artworks and target_artworks arrays, set embed_artfile variable ###
		{  ((copy_artwork)) || ((embed_artwork))  ; } && {
			local source_art target_art target_art_exists art_file embed_artfile # copy_artfile copy_overlimit embed_overlimit

			source_art=( "${source_dir%/}"/{[Ff][Oo][Ll][Dd][Ee][Rr],[Cc][Oo][Vv][Ee][Rr],[Ff][Rr][Oo][Nn][Tt]}.{[Jj][Pp][Gg],[Jj][Pp][Ee][Gg],[Gg][Ii][Ff],[Ww][Ee][Bb][Pp],[Pp][Nn][Gg]} )
			for i in "${!source_art[@]}" ;do
			    [[ -s ${source_art[i]} ]] || unset 'source_art[i]'
			done
			if (( ${#source_art[@]} )) ;then
				((copy_artwork)) && {
					target_art=( "${target_dir%/}"/{[Ff][Oo][Ll][Dd][Ee][Rr],[Cc][Oo][Vv][Ee][Rr],[Ff][Rr][Oo][Nn][Tt]}.{[Jj][Pp][Gg],[Jj][Pp][Ee][Gg],[Gg][Ii][Ff],[Ww][Ee][Bb][Pp],[Pp][Nn][Gg]} )
					(( ${#target_art[@]} )) && (( ! force_copy_artwork )) && target_art_exists="1"

					### target art doesn't exist, or forced copying is enabled
					((target_art_exists)) || {
						if _check_artwork -copy "${source_art[@]}" ;then
							source_artworks[$sdi]="${source_dir}/${art_file}"
							target_artworks[$sdi]="${target_dir}/${art_file}"
						else
							oversized_copy_art_dirs+=( "${source_dir}" )
						fi
					}
				}
				((existing_flacs)) && ((encode_opus_local)) && ((embed_artwork)) && {
					if _check_artwork -embed "${source_art[@]}" ;then
						embed_artfile="${source_dir}/${art_file}"
					else
						# use imagemagick to resize oversized art?
						oversized_embed_art_dirs+=( "${source_dir}" )
					fi
				}
			else
				dirs_missing_artwork+=( "$source_dir" )
			fi
		} ### /find artwork files, add to source_artworks and target_artworks arrays, set embed_artfile variable ###

		### source_dir contains flac files ###
		((existing_flacs)) && {
			### setup opus/mp3/embed_art target vars and arrays ###
			((encode_opus_local)) && { # || ((encode_mp3s_local))
				local index_list last_index idx flac_extn flac_base opus_file
				# get the currently highest source_files index
				index_list=( "${!source_files[@]}" ) # create a new array containing the source_files array indexes
				last_index="${index_list[*]: -1}"    # get the last element of the new array
				if [[ -z $last_index ]] ;then        # set starting index for this set of source/target array additions
					idx="0"
				else
					idx="$(( last_index + 1 ))"
				fi
				for flac_file in "${flac_files[@]}" ;do
					flac_extn="${flac_file##*.}" # de/construct flac/opus paths/names
					flac_base="${flac_file##*/}" # https://mywiki.wooledge.org/BashGuide/Parameters
					flac_base="${flac_base%."$flac_extn"}"
					opus_file="${target_dir}/${flac_base}.opus"
					# ((encode_opus_local)) && opus_file="${target_dir}/${flac_base}.opus"
					# ((encode_mp3s_local)) &&  mp3_file="${target_dir}/${flac_base}.mp3"

					source_files[idx]="$flac_file"
					target_files[idx]="$opus_file"
					# ((encode_opus_local)) && target_opus_files[i]="$opus_file"
					# ((encode_mp3s_local)) && target_mp3_files[i]="$mp3_file"

					# add embedded artwork sources to source_embed_artworks array
					((embed_artwork)) && [[ -n $embed_artfile ]] &&
						source_embed_artworks[idx]="$embed_artfile"

					# ((encode_mp3)) && {
					# 	a lot more work to bring over at least the following tags:
					# 	album artist, artist, album, date, track number, track title, genre(s)
					#   target_mp3_tags_album="$( metaflac ... )"
					# }

					# increment $idx
					(( idx++ ))
				done
			} ### /setup opus/mp3/embed_art target vars and arrays ###
		} ### /source_dir contains flac files ###

		### source_dir contains mp3s ###
		((existing_mp3s)) && {
			### copy mp3s ###
			((existing_target_dir)) && ((copy_mp3s_local)) && {
				# only one source/target dir to store for mp3 copying, can just use $sdi
				source_mp3_copy_dirs[sdi]="$source_dir"
				target_mp3_copy_dirs[sdi]="$target_dir"
			} ### /copy mp3s ###
		} ### /source_dir contains mp3s ###
	} ### /there are flacs or mp3s ###

	return 0
}


_help() {

	printf -v name_synopsis -- '
%bName%b
  mkopuslibrary - a recursive, multiprocess frontend to opusenc

%bSynopsis%b
  %bmkol.sh%b [%b--source%b] [%b--target%b] [%boption%b [%bargument%b]]...
  %bmkol.sh%b [%b--source%b] [%b--target%b] [%boption%b [%bargument%b]]... %b--help%b
  %bmkol.sh --version%b

' "$b" "$d"  "$b" "$d" \
		   "$b" "$d"  "$b" "$d"  "$b" "$d"  "$u" "$d" "$u" "$d" \
		   "$b" "$d"  "$b" "$d"  "$b" "$d"  "$u" "$d" "$u" "$d"  "$b" "$d" \
		   "$b" "$d"


	printf -v desc_deps_docs -- '%bDescription%b
  mkopuslibrary converts trees of FLAC files into corresponding hierarchies of
  Opus files, while providing some additional related conveniences:
    -copying MP3 files
    -copying and/or embedding cover art files (with configurable size limits)
    -listing directories missing artwork, and those orphaned in the output tree

%bDependencies%b
  Bash >= v5.1: globstar (v4.0) / wait -n (v4.3) / wait -p (v5.1)
  coreutils: realpath / grealpath (or your realpath has same -e/-q behaviour)
  opusenc (optional)
  coreutils: comm / gcomm (optional)
  posix: cp (optional), less (optional), mkdir, wc, awk

%bDocumentation%b
  %b-h%b | %b-H%b | %b--help%b   Open full help text.
  %b-hg%b | %b--general%b    Open general help text.
  %b-hs%b | %b--script%b     Print script options.
  %b-hm%b | %b--modes%b      Print operating mode options.
  %b-ho%b | %b--opus%b       Print opus encode options
  %b-ha%b | %b--art%b        Print art options.
  %b-hl%b | %b--log%b        Print log options.

' "$b" "$d"  "$b" "$d"  "$b" "$d" \
		   "$b" "$d"  "$b" "$d"  "$b" "$d" \
		   "$b" "$d"  "$b" "$d"    "$b" "$d"  "$b" "$d"    "$b" "$d"  "$b" "$d" \
		   "$b" "$d"  "$b" "$d"    "$b" "$d"  "$b" "$d"    "$b" "$d"  "$b" "$d"



	printf -v usage -- '%bUsage%b
  There are 4 operating modes: encoding opus, copying artwork, copying MP3s, and
  finding orphaned target directories. Each mode can be run alone or in addition
  to any other mode(s). See %bOperating Mode Options%b for more details.

  Any arguments to command-line options must be quoted if they contain any non-
  alphanumeric characters (spaces, symbols, etc).

  Help sections detailing command-line options will list the current setting of
  each option in brackets to the right their respective flags, including values
  for any options passed to the left of the %b--help%b / %b-h%b / %b-H%b flag.

  Each configuration option may or may not apply to a given operation mode.

' "$b" "$d" "$b" "$d" "$b" "$d" "$b" "$d" "$b" "$d"



	printf -v config_files -- '%bConfiguration Files%b
  Enable a user-config file by placing it in one of these locations:

    %sHOME/.config/mkolrc
    %sHOME/.config/mkopuslibrary/mkolrc
    %sHOME/.mkolrc

  An example config file, %bmkolrc.example%b, is provided in the mkopuslibrary
  package directory. The comments and settings are copied from the in-script
  default settings section.

  A configuration file can include as many, or as few, of the options from
  %bmkolrc.example%b as you require.

  At present configuration files are sourced directly. This is a potential
  security risk as any shell code within a config file will be executed. Every
  un-commented line %bmust only contain a variable definition%b in the form
  of %bvariable_name="value"%b.

' "$b" "$d"    "$" "$" "$"   "$b" "$d" "$b" "$d"    "$u" "$d" "$b" "$d"



	printf -v config_priority -- '%bConfiguration Priority%b
  The default configuration settings are found at the beginning of the script.
  These settings are superseded by those from a user-configuration file, when
  one is detected. Both script and user defaults are superseded by option flags
  on the command line.

  Excluding %b-d%b / %b--subdir%b, options appearing right-most in an %bmkol.sh%b command
  replace and/or override any conflicting options appearing to their left.

  When %b-c%b is used to load a configuration file, options within that file will
  override any conflicting flags to the left of %b-c%b on the command line, and
  any conflicting options further to the right will override those in the file.

' "$b" "$d"    "$b" "$d" "$b" "$d" "$b" "$d"    "$b" "$d" "$b" "$d"



	printf -v artwork -- '%bArtwork%b
  Artwork files found in source directories can be copied to the corresponding
  directory in the Opus tree, and/or embedded in Opus outputs.

  When either mode is enabled, each source directory is searched for files which
  case-insensitively match any combination of these names and extensions:

    %bfolder%b, %bcover%b, %bfront%b -|- %bjpg%b, %bjpeg%b, %bgif%b, %bwebp%b, %bpng%b

  Size limits can be applied to either artwork mode. When limits are in use,
  each filename match in a directory is examined until one is found within the
  configured limit, or all filename matches have been exhausted.

  In either mode, if no size limit is enabled, the first artwork filename match
  found in a source directory will be used as the file to embed/copy.

  When embedding artwork is enabled, if a source artwork file is found, any
  existing artwork embedded in the source file will be omitted from the Opus
  output, and the detected artwork file will be embedded instead.

  Unless %b--discard-embedded-art%b is used, source-embedded artwork will still
  be embedded in Opus outputs when %b--embed-art%b is not enabled, and
  regardless of any enabled size limits.

' "$b" "$d"    "$b" "$d"    "$b" "$d"    "$b" "$d"     "$b" "$d"    "$b" "$d" \
		   "$b" "$d"    "$b" "$d"    "$b" "$d"    "$b" "$d"    "$b" "$d"



	printf -v logging -- '%bLogging%b
  During applicable operations and with applicable options enabled, directories
  meeting the following criteria are logged:

    -> source is missing artwork
    -> artwork exists in source, but all candidates exceed copy size limit
    -> artwork exists in source, but all candidates exceed embed size limit
    -> target directory is orphaned (no matching source directory)
    -> target directory could not be created

  Each set of directories can be printed to stdout on completion, and/or saved
  to a file. See %bLog Options%b for more information. If printing and logging 
  are both disabled, only counts of the directories matching each condition will
  be displayed - enabling at least one of these modes is recommended.

' "$b" "$d"  "$b" "$d"  



	printf -v mode_opts -- '%bOperating Mode Options%b
  The default operating modes can be configured by setting the %bcopy_artwork%b,
  %bcopy_mp3s%b, %bencode_opus%b, and %bfind_orphans%b variables in the default settings
  section, or in an external config file, and can be changed at runtime using
  the option flags listed below.

  %b-o%b | %b--all-ops%b%s
    Enables all operations (encode Opus, copy artwork files, copy MP3 files,
    check for orphaned output folders).

  %b-O%b | %b--no-ops%b%s
    Disables all operations. Enable specific modes with subsequent flags.

  %b-e%b | %b--encode-opus%b%s
    Encode FLAC files in source(s) to Opus files in target(s).

  %b-E%b | %b--no-encode-opus%b%s
    Do not encode FLAC files in source(s) to Opus files in target(s).

  %b-m%b | %b--copy-mp3%b%s
    Copy any mp3s found in source directories.

  %b-M%b | %b--no-copy-mp3%b%s
    Do not copy any mp3s found in source directories.

  %b-x%b | %b--extraneous%b | %b--orphans%b%s
    Check for and list any orphaned target directories.

  %b-X%b | %b--no-extraneous%b | %b--no-orphans%b%s
    Do not check for or list any orphaned target directories.

  %b-y%b | %b--copy-art%b%s
    Copy cover artwork files found in source directories.

  %b-Y%b | %b--no-copy-art%b%s
    Do not copy cover artwork files found in source directories.

' "$b" "$d"  "$b" "$d"  "$b" "$d"  "$b" "$d"  "$b" "$d" \
				   "$b" "$d"  "$b" "$d" "$( { ((copy_artwork)) && ((copy_mp3s)) && ((encode_opus)) && ((find_orphans)) ; } && printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( { ((copy_artwork != 1)) && ((copy_mp3s != 1)) && ((encode_opus != 1)) && ((find_orphans != 1)) ; } && printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((encode_opus)) && printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((encode_opus)) || printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((copy_mp3s)) && printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((copy_mp3s)) || printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$b" "$d" "$( ((find_orphans)) && printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$b" "$d" "$( ((find_orphans)) || printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((copy_artwork)) && printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((copy_artwork)) || printf ' | (enabled)' )"



	printf -v script_opts -- '%bScript Options%b
  %b-c [config file]%b | %b--config-file [config file]%b | (%s)
    Load configuration settings from an external file. Every un-commented line
    of your config file %bmust only contain one variable definition%b in the form
    of %bvarname="value"%b.

  %b-d [subdirectory]%b | %b--subdir [subdirectory]%b | (occurrences in cmd: %s)
    Recursively restrict source selection to files within [subfolder].
    [subfolder] must be a subfolder of parent source. Must be preceded by any
    -s or --source calls. Can be called multiple times in the same command.

  %b-D [string]%b | %b--exclude [string]%b | (%s)
    Skip any directory paths containing [string].

  %b-s [source_root]%b | %b--source [source_root]%b | (%s)
    Set the root source folder/tree to [source_root]. Must precede any -d or
    --subdir calls. [source_root] must already exist.

  %b-t [target_root]%b | %b--target [target_root]%b | (%s)
    Set the root target folder/tree to [target_root]. [target_root] must already
    exist.

  %b--version%b | (%s)
    Prints the version number of the script and exits.

' "$b" "$d" \
				   "$b" "$d"  "$b" "$d" "${loaded_config:-variable is unset}" "$u" "$d" "$b" "$d" \
				   "$b" "$d"  "$b" "$d" "${#subdir_args[@]}" \
				   "$b" "$d"  "$b" "$d" "${exclude:-variable is unset}" \
				   "$b" "$d"  "$b" "$d" "${source:-variable is unset}" \
				   "$b" "$d"  "$b" "$d" "${target:-variable is unset}" \
				   "$b" "$d"            "${mkol_version:-variable is unset}"



	printf -v opus_opts -- '%bOpus Encode Options%b
  %b-b [bitrate]%b | %b--bitrate-opus [bitrate]%b | (%s)
    Set the bitrate for opusenc to [bitrate]. Must be set with a number.
    Invalid values are replaced with the opusenc default, 96Kbps.

  %b-f%b | %b--force-opusenc%b%s
    Encode Opus files regardless of (and potentially overwriting) any
    pre-existing targets.

  %b-F%b | %b--no-force%b%s
    Only encode Opus when number of pre-existing targets is less than the
    number of corresponding source files.

  %b-j [jobs]%b | %b--jobs [jobs]%b | (%s)
    Set the number of simultaneous background opusenc jobs to [jobs]. Must
    be set with an (optionally signed) integer. Specify a maximum using "N" or
    "+N". Detect and use all available CPU cores with "0", or specify the
    number of cores to leave unused with "-N".

  %b-v%b | %b--emit-per-file%b%s
    Emit success/failure message for each opus encode target.

  %b-V%b | %b--emit-progress-summary%b%s
    Display a continuously updated overall status summary of opus encodes.

' "$b" "$d" \
				   "$b" "$d"  "$b" "$d" "${bitrate_opus:-variable is unset}" \
				   "$b" "$d"  "$b" "$d" "$( ((force_opusenc)) && printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((force_opusenc)) || printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "${jobs:-variable is unset}" \
				   "$b" "$d"  "$b" "$d" "$( ((emit_per_file)) && printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((emit_per_file)) || printf ' | (enabled)' )"



	printf -v art_opts -- '%bArtwork Options%b
  Artwork embedding options only apply when encode-opus mode is enabled.
  Artwork copying options only apply when copy-art mode is enabled
  See %bOperating Mode Options%b for details on enabling either mode.

  %b-a [limit]%b | %b--art-copy-limit [limit]%b | (%s)
    Set the limit in KB on the size of artwork files to copy to target folders.
    Directories containing artwork files which all exceed the limit are logged.

  %b-A [limit]%b | %b--art-embed-limit [limit]%b | (%s)
    Set the limit in KB on the size of artwork files to embed in Opus outputs.
    If no detected artwork file is within the limit, the folder will be marked
    as missing embeddable artwork, but source-embedded artwork may still be
    embedded in the Opus output, if --discard-embedded-artwork is not enabled.

  %b-w%b | %b--force-copy-art%b%s
    Ignore existing artwork in target directories, which would otherwise
    prevent copying art to those directories. Artwork files in targets may be
    overwritten, or become redundant. Has no effect on embedding artwork.

  %b-W%b | %b--no-force-copy-art%b%s
    Existing artwork files in target directories will prevent new artwork from
    being copied there. Has no effect on embedding artwork.

  %b-z%b | %b--embed-art%b%s
    Embed detected artwork files in Opus outputs.

  %b-Z%b | %b--no-embed-art%b%s
    Do not embed detected artwork files in Opus outputs, but if source
    contains embedded artwork, embed it in Opus output.

  %b-ZZ%b | %b--discard-embedded-art%b%s
    Do not embed detected artwork files in Opus outputs, and if source
    contains embedded artwork, do not embed it in Opus output either.

' "$b" "$d" "$b" "$d" \
				   "$b" "$d"  "$b" "$d" "${art_copy_size_limit:-variable is unset}" \
				   "$b" "$d"  "$b" "$d" "${art_embed_size_limit:-variable is unset}" \
				   "$b" "$d"  "$b" "$d" "$( ((force_copy_artwork)) && printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((force_copy_artwork)) || printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((embed_artwork)) && printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((embed_artwork)) || printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((discard_embedded)) && printf ' | (enabled)' )"



	printf -v log_opts -- '%bLog Options%b
  Currently, failed mkdirs, directories missing artwork files, or those having
  oversized artwork files, and orphaned target directories, can be listed to
  stdout when all operations are complete, and/or logged to a file.

  %b-g [directory]%b | %b--log-dir [directory]%b | (%s)
    Set the directory to save log files in, when logging is enabled. Defaults
    to the parent target folder.

  %b-l%b | %b--log-failures%b%s
    Log failures in enabled operating modes to applicable file in %slog_dir.

  %b-L%b | %b--no-log-failures%b%s
    Do not log failures to file.

  %b-p%b | %b--print-failures%b%s
    Print failures in enabled operating modes to stdout upon completion.

  %b-P%b | %b--no-print-failures%b%s
    Do not print failures to stdout.

' "$b" "$d" \
				   "$b" "$d"  "$b" "$d" "${log_dir:-${target}}" \
				   "$b" "$d"  "$b" "$d" "$( ((log_failure_lists)) && printf ' | (enabled)' )" "$" \
				   "$b" "$d"  "$b" "$d" "$( ((log_failure_lists)) || printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((print_failure_lists)) && printf ' | (enabled)' )" \
				   "$b" "$d"  "$b" "$d" "$( ((print_failure_lists)) || printf ' | (enabled)' )"



	printf -v end -- '%bExamples%b
  enable all modes, then disable copying MP3s:
    %s> %bmkol.sh -o -M%b

  disable all modes, then enable finding oprhaned target directories:
    %s> %bmkol.sh -O -x%b

  the value from the first %b-b%b call is replaced, Opus bitrate is set to 96:
    %s> %bmkol.sh -b 128 -b 96%b

%bBugs, Updates%b
  https://gitlab.com/beep_street/mkopuslibrary

' "$b" "$d"    "$" "$b" "$d"   "$" "$b" "$d"     "$b" "$d" "$" "$b" "$d"     "$b" "$d"


	case $1 in
		general)
			printf -- '%s%s%s%s%s%s%s%s' "$name_synopsis"  "$desc_deps_docs"  "$usage"  "$config_files"  "$config_priority"  "$artwork" "$logging" "$end"
			;;
		script)
			printf -- '%s' "$script_opts"
			;;
		modes)
			printf -- '%s' "$mode_opts"
			;;
		opus)
			printf -- '%s' "$opus_opts"
			;;
		art)
			printf -- '%s' "$art_opts"
			;;
		log)
			printf -- '%s' "$log_opts"
			;;
		*)
			printf -- '%s%s%s%s%s%s%s%s%s%s%s%s%s' "$name_synopsis"  "$desc_deps_docs"  "$usage"  "$config_files"  "$config_priority"  "$artwork" "$logging" \
				   "$mode_opts" "$script_opts" "$opus_opts" "$art_opts" "$log_opts" "$end"
			;;
	esac
}


_is_uint() { # https://stackoverflow.com/a/61835747
	# returns 1 when argument is empty or contains any non-digit characters
	case $1 in '' | *[!0-9]* ) return 1;; esac
}

_is_sint() { # https://stackoverflow.com/a/61835747
	# signed interger version
	case ${1#[-+]} in '' | *[!0-9]* ) return 1 ;; esac
}


# requires 'declare -g' when used in function, ok, but the quotes are being retained in the declared vars
# just source it, it works, notes are in help
# keep looking for something better
# _load_config() { # https://unix.stackexchange.com/a/582370/538685
# 	# takes config files and discards lines that are not variable definitions ... (?)
# 	while read -r line ;do
# 		declare -g "$line" 2>/dev/null
# 	done < "$1"
# }


_mkol() { # should rename ... oet? (opus enc threaded) ... ?
	# uses up to $jobs simultaneous jobs to encode any ${source_files[@]} into their matching ${target_files[@]}
	# takes no arguments, runs _encode_opus against "${!source_files[@]}"
	# http://mywiki.wooledge.org/ProcessManagement

	local status_colour percent_jobs_complete actual_complete percent_jobs_remaining seconds_remaining mins_remaining eta \
		  i c s lines_back wpid pids failed_source_index # sleep_time

	# if there are no source files, skip back a line and put the abort message in the "processing source dir(s)" section
	# this assumes that section is always the previous section run/printed... is that always true? ... yes, if _mkol keeps getting put in actions[0]
	# change source_files to target_files in here!
	#[[ ${#source_files[@]} -lt "1" ]] && { printf '%b   %b->%b nothing to do, aborting _mkol action\n\n' "\033[1A" "$b" "$d" ;return 0 ;}
	# maybe reporting "0 opus targets" is enough...?
	(( ${#source_files[@]} )) || return 0

	# all success = green | all failure = red | some success, some failure = orange
	_set_status_colour() {
		if (( ${#failed_targets[@]} == 0 )) ;then
			status_colour="$g"
		elif (( s > 0 )) ;then
			status_colour="$o"
		else
			status_colour="$r"
		fi
	}

	_get_progress() {
		#                                                            https://stackoverflow.com/a/37536107
		#                                                            calculates the 1st decimal place, and if it is equal to or greater
		#                                                            than 5, adds 1 to the integer result in order to round it up.
		percent_jobs_complete="$(( 100 * c / ${#target_files[@]} + ( 1000 * c / ${#target_files[@]} % 10 >= 5 ? 1 : 0 ) ))"
		if (( percent_jobs_complete == 0 )) ;then
			actual_complete="0"
			percent_jobs_complete="1"
		else
			actual_complete="$percent_jobs_complete"
		fi
		percent_jobs_remaining="$(( 100 - percent_jobs_complete ))"
		# SC2017: Increase precision by replacing a/b*c with a*c/b
		seconds_remaining="$(( SECONDS * percent_jobs_remaining / percent_jobs_complete ))"
		#seconds_remaining="$(( 100 * SECONDS / percent_jobs_complete * percent_jobs_remaining / 100 ))"
		mins_remaining="$(( seconds_remaining / 60 ))"

		if (( c == 0 )) ;then
			printf -v eta '%s' "(~?t)"
		elif (( mins_remaining < 1 )) ;then
			printf -v eta '(~%ss)' "$seconds_remaining"
		else
			printf -v eta '(~%sm)' "$mins_remaining"
		fi
	}

	_jobs_status() {
		case "$1" in
			1)
				printf '   %b---- %bjobs status %b----%b\n       Active:%b %s\n      Started:%b %s\n    Completed:%b %s%%
   Successful:%b %s\n       %b:%b %s\n    Remaining:%b %s %s\n   %b---- %b%s %b----%b\n\n' \
					   "$status_colour" "$b" "$status_colour" "$d" \
					   "$clear_cte" "${#pids[@]}" \
					   "$clear_cte" "$i" \
					   "$clear_cte" "$actual_complete" \
					   "$clear_cte" "$s" \
					   "$( if (( "${#failed_targets[@]}" == 0 )) ;then printf 'Failed' ;else printf '%bFailed%b' "$f" "$d" ;fi )" \
					   "$clear_cte" "${#failed_targets[@]}" \
					   "$clear_cte" "$(( ${#target_files[@]} - c ))" "$eta" \
					   "$status_colour" "$b" "$( _generate_timestamp "$SECONDS"  )" "$status_colour" "$d"
				;;
			2) true
			   # columns or something
			   ;;
		esac
	}

	printf ' %b*%b encoding %s target files using %s threads ...\n' "$b" "$d" "${#source_files[@]}" "$jobs"

	SECONDS="0"
	set -m
	i="0" # iteration
	c="0" # completed
	s="0" # successful

	lines_back="9"
	#sleep_time="0s"

	#trap 'printf '%b' "$show_cursor" ;exit 1' INT
	#printf '%b' "$hide_cursor"

	for source_files_index in "${!source_files[@]}" ;do
		# once $i == $jobs, there are $jobs background jobs running,
		# every subsequent job must wait for one that is already running to finish
		if (( i++ >= jobs )) ;then

			# wait for the next-completed backgrounded process, store its PID in the variable $wpid
			# test for non-zero exit status of the now ended former background process which had PID "$wpid"
			if wait -n -p wpid ;then
				# increment successful count
				(( s++ ))
			else
				# store failed target_files in the failed_targets array using the corresponding source_files array index
				# can we not just store the index and use += ??
				failed_source_index="${pids[$wpid]}"
				failed_targets[$failed_source_index]="${target_files[$failed_source_index]}"
				# failed_targets[${pids[$wpid]}]="${target_files[${pids[$wpid]}]}"
			fi
			unset 'pids[wpid]'
			# increment completed count
			(( c++ ))
		fi

		_encode_opus "$source_files_index" &
		# use the PID of the backgrounded job as the 'pids' array index pointing to the corresponding source_files array index
		pids[$!]="$source_files_index"

		# https://askubuntu.com/a/1047473 / Overwrite previous output in Bash instead of appending it
		# https://blog.stevenocchipinti.com/2013/06/removing-previously-printed-lines.html/
		((emit_per_file)) || {
			# we end with a couple newlines so this always starts at column 0, ie: only need to consider which line cursor is on, not its position on it ...?
			(( i != 1 )) && printf '%b' "\033[${lines_back}A"
			_set_status_colour
			_get_progress
			_jobs_status 1
		}
		#sleep "$sleep_time"
	done

	# is it possible for a job to end in this space before the while loop starts to catch it?
	# how to not duplicate this job-waiting code? wrap it all in the while loop? 

	# when the previous loop fires off the last job,
	# there almost definitely are still $jobs jobs running in the background which need to be 'wait'ed for
	while (( "${#pids[@]}" > 0 )) ;do
		if wait -n -p wpid ;then
			(( s++ ))
		else
			failed_source_index="${pids[$wpid]}"
			failed_targets[$failed_source_index]="${target_files[$failed_source_index]}"
		fi
		unset 'pids[wpid]'
		(( c++ ))

		((emit_per_file)) || {
			printf '%b' "\033[${lines_back}A"
			_set_status_colour
			_get_progress
			_jobs_status 1
		}
		#sleep "$sleep_time"
	done
	set +m

	#printf '%b' "$show_cursor"

	# print failed targets when they exist
	# TODO: add option to output to file (with no indentation/format)
	#       with modifier to make it the only output to ease automating deletion of the list
	# TODO: add option/logic to restrict output (or send to file) when #of failed targets is excessive
	(( "${#failed_targets[@]}" > 0 )) && {
		printf '   %b-> %bFailed Targets%b:\n' "$b" "$f" "$d"
		printf '      %s\n' "${failed_targets[@]}"
		printf '\n'
	}
}



# check for an external config file
for external_config in "${HOME}/.config/mkolrc" "${HOME}/.config/mkopuslibrary/mkolrc" "${HOME}/.mkolrc"  ;do
	[ -s "$external_config" ] && {
		# and try to test if it's a 'valid' mkol config file
		# if grep -qi -e opt1 -e opt2 -e opt3 ... "$2" ;then or something
		source "$external_config"
		#_load_config "$external_config"
		loaded_config="$external_config"
		break
	}
done

# "any other setting" still disables in user settings, and ((var)) can still be used as a switch
for option in copy_artwork  copy_mp3s  discard_embedded  embed_artwork  emit_per_file  encode_opus  find_orphans  force_copy_artwork force_opusenc ;do
	# test value /of the variable whose name is/ the value of $option
	[[ ${!option} != "1" ]] && printf -v "$option" -- '%s' "0"
done

mkol_version="0.9.3-pre1"

# something to be done about options missing arguments, 'shift 2' wouldn't be desirable then, and an error should really be printed
while true ;do
	case $1 in
		-h|-H|--help)
			if command -v less >/dev/null 2>&1 ;then
				_help |
					less -R -Ps" mkopuslibrary help      scroll\: (PG)UP/(PG)DN      search\: '/'      quit\: 'q' "
			else
				_help
			fi
			exit 0
			;;
		-hg|--general)
			if command -v less >/dev/null 2>&1 ;then
				_help general |
					less -R -Ps" mkopuslibrary help      scroll\: (PG)UP/(PG)DN      search\: '/'      quit\: 'q' "
			else
				_help general
			fi
			exit 0
			;;
		-hs|--script)
			_help script
			exit 0
			;;
		-hm|--modes)
			_help modes
			exit 0
			;;
		-ho|--opus)
			_help opus
			exit 0
			;;
		-ha|--art)
			_help art
			exit 0
			;;
		-hl|--log)
			_help log
			exit 0
			;;
		-a|--art-copy-limit)
			art_copy_size_limit="$2"
			shift 2
			;;
		-A|--art-embed-limit)
			art_embed_size_limit="$2"
			shift 2
			;;
		-b|--bitrate-opus)
			bitrate_opus="$2"
			shift 2
			;;
		# haven't considered lame presets here, possible?? to check args for "[vV]2" or "[vV]0" or "320" and
		# set var including lame option switch? eg: var="--preset v2" or var="--bitrate 320"
		# -B|--bitrate-mp3)
		# 	bitrate_mp3="$2"
		# 	shift 2
		# 	;;
		-c|--config-file)
			if [ -s "$2" ] ;then # && grep -qi -e opt1 -e opt2 -e opt3 ... "$2"
				source "$2"
				#_load_config "$2"
				loaded_config="$2"
			else
				printf 'No config file found at "%s", no options were set.\n\n' "$2"
			fi
			shift 2
			;;
		# C
		-d|--subdir)
			# in this while loop, only add each --subdir argument to 'subdirs' (or something) array
			# then do any validation, sub-subdir finding, etc, on the entire array after the while/options loop
			subdir_called="1"
			subdir_args+=( "$2" )
			shift 2
			;;
		-D|--exclude)
			exclude="$2"
			shift 2
			;;
		-e|--encode-opus) # -p / -P #?
			encode_opus="1"
			shift
			;;
		-E|--no-encode-opus)
			encode_opus="0"
			shift
			;;
		-f|--force-opusenc)
			force_opusenc="1"
			shift
			;;
		-F|--no-force)
			force_opusenc="0"
			shift
			;;
		-g|--log-dir)
			if [[ -d $2 ]] ;then
				log_dir="$2"
			else
				printf '%sERROR%s: log dir not set to a directory, using %s instead.\n\n' "$o" "$d" "$target"
				log_dir="$target"
			fi
			shift 2
			;;
		# G
		# Ii
		-j|--jobs)
			jobs="$2"
			shift 2
			;;
		# J
		# Kk
		-l|--log-failures)
			log_failure_lists="1"
			shift
			;;
		-L|--no-log-failures)
			log_failure_lists="0"
			shift
			;;
		-m|--copy-mp3)
			copy_mp3s="1"
			shift
			;;
		-M|--no-copy-mp3)
			copy_mp3s="0"
			shift
			;;
		# Nn
		-o|--all-ops)
			copy_artwork="1"
			copy_mp3s="1"
			encode_opus="1"
			find_orphans="1"
			shift
			;;
		-O|--no-ops)
			copy_artwork="0"
			copy_mp3s="0"
			encode_opus="0"
			find_orphans="0"
			shift
			;;
		-p|--print-failures)
			print_failure_lists="1"
			shift
			;;
		-P|--no-print-failures)
			print_failure_lists="0"
			shift
			;;
		# Qq
		# Rr
		-s|--source)
			source="$2"
			shift 2
			;;
		# S
		-t|--target)
			target="$2"
			shift 2
			;;
		# T
		# uU
		-v|--emit-per-file)
			emit_per_file="1"
			shift
			;;
		-V|--emit-progress-summary)
			emit_per_file="0"
			shift
			;;
		--version)
			printf 'mkopuslibrary v%s\n' "$mkol_version"
			exit 0
			;;
		-w|--force-copy-art)
			force_copy_artwork="1"
			shift
			;;
		-W|--no-force-copy-art)
			force_copy_artwork="0"
			shift
			;;
		-x|--extraneous|--orphans)
			find_orphans="1"
			shift
			;;
		-X|--no-extraneous|--no-oprhans)
			find_orphans="0"
			shift
			;;
		-y|--copy-art)
			copy_artwork="1"
			shift
			;;
		-Y|--no-copy-art)
			copy_artwork="0"
			shift
			;;
		-z|--embed-art)
			embed_artwork="1"
			shift
			;;
		-Z|--no-embed-art)
			embed_artwork="0"
			shift
			;;
		-ZZ|--discard-embedded-art)
			discard_embedded="1"
			shift
			;;
		-?*)
			printf 'Unknown option %s, aborting.\n' "$1" ;_help general ;exit 1
			;;
		*)
			# test for dependencies of enabled operations, only add operation
			# to "actions" array if/when dependency is detected
			((encode_opus)) && {
				if command -v opusenc >/dev/null 2>&1 ;then
					# move _is_uint test on $threads here
					# if $threads = 1 (or another var is set..), actions[0]='_mkol_st'
					# ?
					((discard_embedded)) && embed_artwork="0"
					actions[0]='_mkol'
				else
					printf 'No opusenc, Opus encoding disabled.\n'
				fi
			}

			# just expect 'cp' to be there
			((copy_mp3s)) && actions[3]='_copy_mp3s'
			((copy_artwork)) && {
				# convert $artwork_names into an array, "split robustly" https://www.shellcheck.net/wiki/SC2206
				#IFS=, read -r -a art_names <<< "$artwork_names"
				#IFS=, read -r -a art_extns <<< "$artwork_extns"
				actions[6]='_copy_artwork'
				}

			# always test for $find_orphans last, then if it is the only action in ${actions[@]}, also set $skip_get_targets
			((find_orphans)) && {
				if command -v comm >/dev/null 2>&1 ;then
					comm="comm"
				elif command -v gcomm >/dev/null 2>&1 ;then
					comm="gcomm"
				fi
				if [[ -n $comm ]] ;then
					actions[9]='_find_orphans'
					(( ${#actions[@]} == 1 )) && skip_get_targets="1"
				else
					printf '%bNOTE%b: %s not found, detecting orphaned target folders is disabled.\n' "$o" "$d" "'comm' (or 'gcomm')"
				fi
			}
			break
			;;
	esac
done

# bash version must be at least [s]4.3[/s] !_5.1_!
{ (( BASH_VERSINFO[0] == 5 )) && (( BASH_VERSINFO[1] >= 1 )) ; } ||
	(( BASH_VERSINFO[0] > 5 )) || { printf '%bERROR:%b Bash version 5.1 or newer required, aborting.\n' "$f" "$d" ;exit 1 ; }

# (g)realpath must exist
if command -v realpath >/dev/null 2>&1 ;then
	realpath="realpath" ;elif command -v grealpath >/dev/null 2>&1 ;then realpath="grealpath" # uhh... is realpath really necessary?
else
	printf '%bERROR:%b %s not found, aborting.\n' "$f" "$d" "'realpath' (or 'grealpath')\n" ;exit 1
fi

# source/target options must be set to valid/existing dirs
source="$( "$realpath" -eq -- "$source" )" || { printf 'Invalid source library root path, %s, aborting.\n' "$source" ;exit 1 ; }
[[ -d "$source" ]] || { printf 'Source library root path, %s, not a directory, aborting.\n' "'${source}'" ;exit 1 ; }

target="$( "$realpath" -eq -- "$target" )" || { printf 'Invalid target library root path, %s, aborting.\n' "$target" ;exit 1 ; }
[[ -d "$target" ]] || { printf 'Target library root path, %s, not a directory, aborting.\n' "'${target}'" ;exit 1 ; }

# if logging is enabled but log_dir is unset or invalid, default to current $target
((log_failure_lists)) && {
	[[ -d $log_dir ]] || log_dir="$target"
}

# if $bitrate_opus is not a number >0, use 96 (opusenc's default Kbps for stereo)
{ _is_uint "$bitrate_opus" && (( bitrate_opus > 0 )) ; } ||
	{ printf '%bWARNING%b: invalid %sbitrate_opus value, using opusenc default (96kbps).\n\n' "$o" "$d" "$" ;bitrate_opus="96" ; }

# handle jobs
_is_sint "$jobs" || { printf '%bWARNING%b: Invalid %sjobs value, using "1" instead.\n\n' "$o" "$d" "$" ;jobs="1" ; }
case $jobs in
	-* | 0 )    # https://unix.stackexchange.com/a/564512 | https://gist.github.com/jj1bdx/5746298
		cores="$( getconf _NPROCESSORS_ONLN 2> /dev/null )" || # Linux and similar...
			cores="$( getconf NPROCESSORS_ONLN 2> /dev/null )" || # FreeBSD (and derivatives), OpenBSD, MacOS and similar...
			cores="$( ksh93 -c 'getconf NPROCESSORS_ONLN' 2> /dev/null )" || # Solaris and similar...
			unset cores

		if ((cores)) ;then
			if (( jobs == 0 )) ;then # emacs highlights "jobs" like it refers to the builtin here... :/ bash seems to know the difference
				jobs="$cores"
			else
				if (( cores > ${jobs#-} )) ;then
					jobs="$(( cores - ${jobs#-}  ))"
				else
					printf '\n%bWARNING%b: The jobs option is configured to leave more cores unused (%s) than the total available (%s).\n' "$o" "$d" "${jobs#-}" "$cores"
					printf 'Please try a negative value that is "less than" %s, or set the jobs limit manually with a positive value.\nUsing single-thread.\n\n' "$cores"
					jobs="1"
				fi
			fi
		else
		    printf 'Unable to detect available CPU cores, please set the jobs option to a positive integer. Using single-thread.\n' # abort ?
			jobs="1"
		fi
		;;
	*)
		jobs="${jobs#+}"
		;;
esac

# use root/parent source dir if -d/--subdir is not called
# abort if it is called and none of its arguments are valid
if ((subdir_called)) ;then
	for subdir in "${subdir_args[@]}" ;do
		# for every -d call, verify argument is 1) a directory, 2) a subdir of parent, then add to parent_source_dirs array
		absolute_subdir="$( "$realpath" -qe -- "$subdir" )" || unset absolute_subdir
		if [[ -z "$absolute_subdir" ]] ;then
			printf '%bError%b! Argument for %s option, %s, not a resolvable path, skipping.\n' "$r" "$d" "'-d' / '--subdir'" "'${subdir}'"
			continue
		elif [[ -d "$absolute_subdir" && $absolute_subdir == "$source"/* ]] ;then
			parent_source_dirs+=( "$absolute_subdir" )
		else
			printf '%bError%b! -d / --subdir argument, %s, not a subdirectory of source path, skipping.\n' "$r" "$d" "'${subdir}'"
			continue
		fi
	done
	[[ -z "${parent_source_dirs[*]}" ]] && {
		printf 'No valid subdirectories found in %s argument%s, aborting.\n' "'-d' / '--subdir'" "$( (( ${#subdir_args[@]} > 1 )) && printf 's' )" ;exit 1
	}
else
	parent_source_dirs=( "$source" )
fi

# further preamble printf? -  parent source/target? - restricted to subdirs? - bitrate used?

# create source_dirs array from output of `_get_dirs "${parent_source_dirs[@]}"`
printf ' %b*%b collecting source directories from %s parent %s ... ' \
	   "$b" "$d" "${#parent_source_dirs[@]}" "$( if (( ${#parent_source_dirs[@]} == 1 )) ;then printf 'directory' ;else printf 'directories' ;fi )"
SECONDS="0"
_get_dirs "${parent_source_dirs[@]}"
source_dirs=( "${unique_dirs[@]}" )
printf '\n   %b->%b %s source %s, %s seconds\n\n' "$b" "$d" "${#source_dirs[@]}" \
	   "$( if (( ${#source_dirs[@]} == 1 )) ;then printf 'directory' ;else printf 'directories' ;fi )" "$SECONDS"

# create arrays for enabled modes: source_files, target_files, source_artworks, target_artworks, dirs_missing_artwork (...) arrays
# except when -x is only enabled mode
((skip_get_targets)) || {
	printf ' %b*%b processing source dir(s) ... ' "$b" "$d"
	SECONDS="0"
	for index in "${!source_dirs[@]}" ;do
		# make sure at least one mode is enabled
		shopt -s nullglob
		_get_targets "$index"
		shopt -u nullglob
		# || failed_mkdirs+="$
	done
	printf '\n   %b->%b %s opus targets, %s artwork copy targets, %s source folder%s missing an artwork file, %s seconds\n\n' \
		   "$b" "$d" "${#target_files[@]}" "${#target_artworks[@]}" "${#dirs_missing_artwork[@]}" \
		   "$( (( ${#dirs_missing_artwork[@]} > 1 )) && printf 's' )" "$SECONDS"
}

(( ${#failed_mkdirs[@]} )) && {
	printf -- '%bERROR:%b mkdir failed to create one or more directories, aborting.\n' "$f" "$d"

	((print_failure_lists)) && {
		printf -- '      %s\n' "${failed_mkdirs[@]}"
	}

	((log_failure_lists)) && {
		[[ -s ${log_dir}/mkol-failed_mkdirs.txt ]] && mv "${log_dir}/mkol-failed_mkdirs.txt" "${log_dir}/mkol-failed_mkdirs.txt.old"
		printf -- '%s\n' "${failed_mkdirs[@]}" > "${log_dir}/mkol-failed_mkdirs.txt"
	}

	printf '\n'

	exit 1
}
#SECONDS="0"

for action in "${actions[@]}" ;do
	"$action"
done
#printf 'total time for all tasks: %s\n' "$( _generate_timestamp "$SECONDS" )"
#printf 'failed targets #: %s\n' "${#failed_targets[@]}"


{ (( ${#dirs_missing_artwork[@]} )) || (( ${#oversized_copy_art_dirs[@]} )) || (( ${#oversized_embed_art_dirs[@]} ))  ; } && {
	printf -- ' %b*%b detailing artwork failures ...\n' "$b" "$d"
}

(( ${#dirs_missing_artwork[@]} )) && {
	printf -- '   %b->%b no artwork (files) exist in %s source %s\n' "$b" "$d" "${#dirs_missing_artwork[@]}" "$( _dir_or_dirs "${#dirs_missing_artwork[@]}" )"

	((print_failure_lists)) && {
		printf -- '      %s\n' "${dirs_missing_artwork[@]}"
	}

	((log_failure_lists)) && {
		[[ -s ${log_dir}/mkol-art-missing-dirs.txt ]] && mv "${log_dir}/mkol-art-missing-dirs.txt" "${log_dir}/mkol-art-missing-dirs.txt.old"
		printf -- '%s\n' "${dirs_missing_artwork[@]}" > "${log_dir}/mkol-art-missing-dirs.txt"
	}

	printf '\n'
}

(( ${#oversized_copy_art_dirs[@]} )) && {
	printf -- '   %b->%b artwork in %s source %s is over the applied size limit for copying (%s KB)\n' "$b" "$d" \
		   "${#oversized_copy_art_dirs[@]}" "$( _dir_or_dirs "${#oversized_copy_art_dirs[@]}" )" "$art_copy_size_limit"

	((print_failure_lists)) && {
		printf -- '      %s\n' "${oversized_copy_art_dirs[@]}"
	}

	((log_failure_lists)) && {
		[[ -s ${log_dir}/mkol-art-copy-limit-dirs.txt ]] && mv "${log_dir}/mkol-art-copy-limit-dirs.txt" "${log_dir}/mkol-art-copy-limit-dirs.txt.old"
		printf -- '%s\n' "${oversized_copy_art_dirs[@]}" > "${log_dir}/mkol-art-copy-limit-dirs.txt"
	}

	printf '\n'
}

(( ${#oversized_embed_art_dirs[@]} )) && {
	printf -- '   %b->%b artwork in %s source %s is over the applied size limit for embedding (%s KB)\n' "$b" "$d" \
		   "${#oversized_embed_art_dirs[@]}" "$( _dir_or_dirs "${#oversized_embed_art_dirs[@]}" )" "$art_embed_size_limit"

	((print_failure_lists)) && {
		printf -- '      %s\n' "${oversized_embed_art_dirs[@]}"
	}

	((log_failure_lists)) && {
		[[ -s ${log_dir}/mkol-art-embed-limit-dirs.txt ]] && mv "${log_dir}/mkol-art-embed-limit-dirs.txt" "${log_dir}/mkol-art-embed-limit-dirs.txt.old"
		printf -- '%s\n' "${oversized_embed_art_dirs[@]}" > "${log_dir}/mkol-art-embed-limit-dirs.txt"
	}

	printf '\n'
}
