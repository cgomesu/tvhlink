#!/usr/bin/env sh

########################################################################
# Streamlink helper script for TVHeadend pipe:// with multiple URLs
#
# Note: Keep it POSIX shell compliant for compatibility
#
# Author: cgomesu
# Repo: https://github.com/cgomesu/tvhlink
#
# Related docs:
# - Streamlink: https://streamlink.github.io/cli.html#command-line-usage
########################################################################


usage () {
  echo ''
  echo 'Author: cgomesu'
  echo 'Repo: https://github.com/cgomesu/tvhlink'
  echo ''
  echo 'Usage:'
  echo ''
  echo "$0"' [OPTIONS] <URLS> '
  echo ''
  echo '  URLS:'
  echo '    Multiple http(s) URLs separted by spaces. The order defines priority.'
  echo ''
  echo '  OPTIONS:'
  echo '    -h  Show this help message.'
  echo '    -q  Stream quality profile. It allows fallback profiles. For example:'
  echo '        -q "1080p,720p,best" tries 1080p first, then 720p, then whatever is the best.'
  echo '        The default is "best".'
  echo ''
}

if [ -z "$(command -v streamlink)" ]; then echo '[tvhlink] ERROR: streamlink executable not found'; exit 1; fi

while getopts 'hq:' OPT; do
  case $OPT in
    h) usage; exit 0;;
    q) QUALITY="$OPTARG";;
    \?) echo '[tvhlink] ERROR: Invalid option in the arguments.'; usage; exit 1;;
  esac
done

# loop one or more URLs provided as arg
for URL in "$@"; do
  # use pattern match to find URL; QUALITY uses deault if empty
  if [ ! "$URL" = "${URL#http}" ]; then streamlink --stdout --default-stream "${QUALITY:-best}" --url "$URL"; fi
done

# EOF means no stream found; exit with error
exit 1
