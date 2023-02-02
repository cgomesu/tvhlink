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
#   sha256:f14ee2a6c645286078c755a16a055f93860ceeb65d5e3f54ab61168e6b70b20b
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

#takes a python3 pkg as argument ($1)
check_py3_pkg_exist () {
  if python3 -c "import $1" > /dev/null 2>&1; then return 0; else return 1; fi
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

python3_remove_all () {
  message 'APK: Python3 packages are now going to be managed by APK instead of PIP.' 'warning'
  apk del --no-cache streamlink py3-lxml py3-requests py3-pip python3
}

############
# main logic
start

trap "end 'Received a signal to stop' 1" INT HUP TERM

if ! check_root; then end 'User is not root. This script needs root permission.' 1; fi

# for backward compatibility, let APK manage Python3 pkgs
# see https://github.com/cgomesu/tvhlink/issues/21
if check_py3_pkg_exist pip; then python3_remove_all; fi
message 'Installing/upgrading Streamlink...' 'info'
streamlink_apk

# EOF
message "Streamlink version: $(streamlink --version)." 'info'
end 'Reached EOF without critical errors.' 0
