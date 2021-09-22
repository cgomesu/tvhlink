#!/usr/bin/env sh

#########################################################################################
# Script to install and update Streamlink on the TVHeadend LinuxServer docker container #
#########################################################################################
# How-To:
#  1. Copy 'streamlink_for_tvh_container.sh' to /config/custom-cont-init.d
#  2. Start/Restart the tvheadend container
#########################################################################################
# Author: cgomesu
# Repo: https://github.com/cgomesu/tvhlink
#########################################################################################
# Notes
#  - LinuxServer image comes with Python3 and the community repo source enabled
#  - Streamlink 2.4.0 introduces lxml>=4.6.3 requirement
#  - Keep this script POSIX sh compliant for compatibility
#  - Use shellcheck
#########################################################################################
# Additional info
#
# Base image URL target:
#  ghcr.io/linuxserver/tvheadend
#
# Script installs and updates the pkg:
#  pip3, setuptools, streamlink
#
# Tested images (tvheadend:latest):
#  arm:
#   @sha256:93283bf7f45fc04b74e4c4148b93baac4a07cd0e4a58a0a512b338d9fd5af11e
#########################################################################################

# takes msg ($1) and status ($2) as args
end () {
  echo '*********************************************'
  echo '* Finished Streamlink install/update script'
  echo "* Message: $1"
  echo '*********************************************'
  exit "$2"
}

# takes message ($1) and level ($2) as args
message () {
  echo "[TVHlink] [$2] $1"
}

start () {
  echo '**********************************************'
  echo '****** Streamlink install/update script ******'
  echo '**********************************************'
  echo 'Author: cgomesu'
  echo 'Repo: https://github.com/cgomesu/tvhlink'
  echo '**********************************************'
}

# checks return error (1) if requirements are not met
check_root () {
  if [ "$(id -u)" -ne 0 ]; then return 1; else return 0; fi
}

check_streamlink () {
  if [ -z "$(command -v streamlink)" ]; then return 1; else return 0; fi
}

check_py_lxml () {
  if ! python3 -c 'import lxml' > /dev/null 2>&1; then return 1; else return 0; fi
}

streamlink_update () {
  if [ -z "$(command -v pip3)" ]; then
    end 'PIP3: Critical error. pip3 should be installed but is not.' 1
  else
    # upgrade setuptools and pip first
    if ! pip3 install --no-cache-dir --upgrade setuptools pip; then
      message 'PIP3: Error while upgrading setuptools and pip.' 'error'
    fi
    # ensure lxml is installed. for more info, refer to https://github.com/cgomesu/tvhlink/issues/6
    if ! check_py_lxml; then
      if ! apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/v3.13/community "py3-lxml>4.6.3"; then
        end 'APK: Critical error. Unable to install compatible lxml.' 1
      fi
    fi 
    # upgrade streamlink last and exit on error
    if ! pip3 install --no-cache-dir -U streamlink; then
      end "PIP3: Critical error. Unable to upgrade Streamlink. Current version is still $(streamlink --version)." 1
    fi
  fi
}

streamlink_install () {
  message 'APK: Updating pkg list.' 'info'
  if apk update; then
    message 'APK and PIP3: Installing required packages.' 'info'
    # install lxml from apk instead of pip: https://github.com/cgomesu/tvhlink/issues/6
    if ! apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/v3.13/community py3-pip "py3-lxml>4.6.3"; then
      end 'APK: Critical error. Unable to install pip3 or lxml.' 1
    fi
    # upgrade setuptools and pip before streamlink installation
    if ! pip3 install --no-cache-dir -U setuptools pip; then 
      message 'PIP3: Error while upgrading setuptools and pip.' 'error'
    fi
    # install temporary build dependencies in .build-deps
    # required for building a few of the streamlink dependencies (e.g., pycryptodome)
    if ! apk add --no-cache --virtual .build-deps gcc musl-dev; then
        end 'APK: Critical error. Unable install required packages.' 1
    fi
    # let pip3 try to install until it succeed to install a version of streamlink
    message 'PIP3: Installing Streamlink.' 'info'
    pip3 install --no-cache-dir streamlink
    # cleanup
    message 'APK: Removing packages no longer required.' 'info'
    apk del .build-deps
  else
    end 'APK: Critical error. Unable to update pkg list. Check connectivity.' 1
  fi
  # check that pip3 succeeded to install streamlink or raise critical error
  if ! check_streamlink; then
    end 'PIP3: Critical error. Cannot find Streamlink. Check above for installation errors.' 1
  fi
}


############
# main logic
start

trap "end 'Received a signal to stop' 1" INT HUP TERM

if ! check_root; then end 'User is not root. This script needs root permission.' 1; fi

if check_streamlink; then
  message 'Updating Streamlink...' 'info'; streamlink_update
else
  message 'Installing Streamlink...' 'info'; streamlink_install
fi

message "Streamlink version: $(streamlink --version)." 'info'
end 'Reached EOF without critical errors.' 0
