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
#  x86-64:
#   @sha256:cf7b44ddba0bde7d1dd225cf4a6faa8f24f5cf3dd841b212b4630a4ebc9636e3
#   @sha256:c05411d415a097b7f7cd98eef7414e09e035e6f3c740b016a6b77769f1278475
#  arm:
#   @sha256:d5fc6f2e77beecb655ec5325f002109cd5d5c82c9d2fc3ee39dbb4fc098cd328
#########################################################################################

# takes msg ($1) and status ($2) as args
end () {
  echo '*********************************************'
  echo '* Finished Streamlink install/update script *'
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

# checks return error if requirements are not met
check_root () {
  if [ "$(id -u)" -ne 0 ]; then return 1; else return 0; fi
}

check_streamlink () {
  if [ -z "$(command -v streamlink)" ]; then return 1; else return 0; fi
}

streamlink_update () {
  if [ -z "$(command -v pip3)" ]; then end 'Unusual behavior: pip3 should be installed but is not.' 1;
  else
    if pip3 install --no-cache-dir --upgrade streamlink; then
      message "Streamlink version: $(streamlink --version)." 'info'
    else
      message "Streamlink update failed! Current version is still $(streamlink --version)." 'error'
      end 'There was an error while trying to update streamlink.' 1
    fi
  fi
}

streamlink_install () {
  message 'APK: Updating pkg list.' 'info'
  if apk update; then
    message 'APK: Installing required packages.' 'info'
    if apk add --no-cache py3-pip && apk add --no-cache --virtual .build-deps gcc musl-dev; then
        message 'PIP3: Updating and installing required packages.' 'info'
        if ! pip3 install --no-cache-dir --upgrade setuptools; then message 'PIP3: Error while upgrading setuptools.' 'error'; fi
        ## install the last compatible version of streamlink (2.3.0)
        ## reference to build issues with streamlink 2.4.0 in Alpine
        if ! pip3 install --no-cache-dir streamlink==2.3.0; then message 'PIP3: Error while installing Streamlink.' 'error' ; fi
    else
      end 'APK: Critical error. Unable install required packages.' 1
    fi
    message 'APK: Removing packages no longer required.' 'info'
    apk del .build-deps gcc musl-dev
  else
    end 'APK: Critical error. Unable to update pkg list. Check connectivity.' 1
  fi
  message 'Finsihed all APK and PIP3 updates and installs.' 'info'
}


############
# main logic
start

trap 'end "Received a signal to stop" 1' INT HUP TERM

if ! check_root; then end 'User is not root. This script needs root permission.' 1; fi

if check_streamlink; then
  message 'Updating Streamlink...' 'info'; streamlink_update
else
  message 'Installing Streamlink...' 'info'; streamlink_install
fi

end 'Completed without errors.' 0
