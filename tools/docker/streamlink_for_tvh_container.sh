#!/usr/bin/env sh

###########################################################################################
# Script to install and upgrade Streamlink on the TVHeadend LinuxServer.io docker container
###########################################################################################
# How-To:
#  1. Copy 'streamlink_for_tvh_container.sh' to /custom-cont-init.d
#     (see https://www.linuxserver.io/blog/2019-09-14-customizing-our-containers)
#  2. Start/Restart the tvheadend container
###########################################################################################
# Author: cgomesu
# Repo: https://github.com/cgomesu/tvhlink
###########################################################################################
# Notes
#  - Streamlink is no longer being maintained by APK. Reverted installation to system-wide
#    pip.
#  - System-wide Python3 pkgs now managed by APK. 'testing' repo of the 'edge' branch seems
#    to be pretty quick with release updates.
#  - PEP 668 in Python 3.11 disables global pip3 install
#  - Linuxserver.io changed location of custom scripts dir from /config/custom-cont-init.d
#    to /custom-cont-init.d
#  - Python 3.10.1 (edge branch) changes Python pkg directory
#  - LinuxServer image comes with Python3 and the community repo source enabled
#  - Streamlink 3.0.0 introduces lxml>=4.6.4 and <5.0 requirement
#  - Streamlink 3.0.0 introduces pycountry and pycrypto dependencies
#  - Keep this script POSIX sh compliant for compatibility
#  - Use shellcheck
###########################################################################################
# Additional info
#
# Base image URL target:
#  ghcr.io/linuxserver/tvheadend
#
# Script installs or upgrades the following pkg:
#  python3, streamlink
#
# Tested images (tvheadend:latest):
#  arm64:
#   sha256:sha256:f91e8fcf8e1f7dbfb1001aebc9e5568deba4867e5a2504bdae3b4f1664fb73c3
###########################################################################################

# apk variables
APK_BRANCH='edge'
APK_MAIN="http://dl-cdn.alpinelinux.org/alpine/${APK_BRANCH:-edge}/main"
APK_COMMUNITY="http://dl-cdn.alpinelinux.org/alpine/${APK_BRANCH:-edge}/community"
APK_TESTING="http://dl-cdn.alpinelinux.org/alpine/${APK_BRANCH:-edge}/testing"

# takes msg ($1) and status ($2) as args
end () {
  echo '***********************************************'
  echo '* Finished Streamlink install/upgrade script'
  echo "* Message: $1"
  echo '***********************************************'
  exit "$2"
}

# takes message ($1) and level ($2) as args
message () {
  echo "[TVHlink] [$2] $1"
}

start () {
  echo '***********************************************'
  echo '****** Streamlink install/upgrade script ******'
  echo '***********************************************'
  echo 'Author: cgomesu'
  echo 'Repo: https://github.com/cgomesu/tvhlink'
  echo '***********************************************'
}

# checks user is root
check_root () {
  if [ "$(id -u)" -eq 0 ]; then return 0; else return 1; fi
}

streamlink_apk () {
  if ! apk add --upgrade -U -X "$APK_MAIN" -X "$APK_COMMUNITY" -X "$APK_TESTING" streamlink; then
    end 'APK: Critical error. Unable install required packages. Check previous messages.' 1
  fi
}

requirements_apk () {
  if ! apk add --upgrade -U -X "$APK_MAIN" -X "$APK_COMMUNITY" -X "$APK_TESTING" python3 py3-pip; then
    end 'APK: Critical error. Unable install required packages. Check previous messages.' 1
  fi
}

streamlink_pip () {
  if ! python3 -m pip install -U --break-system-packages streamlink; then
    end 'PIP: There was an error installing streamlink via pip. Check previous messages.' 1
  fi
}


############
# main logic
start

trap "end 'Received a signal to stop' 1" INT HUP TERM

if ! check_root; then end 'User is not root. This script needs root permission.' 1; fi

# reverting installation mode to system-wide pip.
# see https://github.com/cgomesu/tvhlink/issues/29
message 'Installing/upgrading Python3 and pip...' 'info'
requirements_apk
message 'Installing/upgrading Streamlink...' 'info'
streamlink_pip

# #uncomment to try to install it via apk, if the pkg is currently being maintained
# #see https://pkgs.alpinelinux.org/packages
# streamlink_apk

# EOF
message "Streamlink version: $(streamlink --version)." 'info'
end 'Reached EOF without critical errors.' 0
