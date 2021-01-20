#!/usr/bin/env sh

###################################################################################
# Custom script to install Streamlink on the TVHeadend LinuxServer docker container
###################################################################################
# How-to:
#   1. Copy 'install_streamlink.sh' to /config/custom-cont-init.d
#   2. Start/Restart the tvheadend container
###################################################################################
# Author: cgomesu
# Repo: https://github.com/cgomesu/tvhlink
# Note: Keep it POSIX sh compliant for compatibility
###################################################################################
# LinuxServer image comes with Python3 and the community repo source enabled
#
# Base image URL target:
#   ghcr.io/linuxserver/tvheadend
#
# Script installs and updates the pkg: 
#   pip3, setuptools, streamlink
#
# Tested images (tvheadend:latest):
#   x86-64:
#     @sha256:c05411d415a097b7f7cd98eef7414e09e035e6f3c740b016a6b77769f1278475
#
###################################################################################

# takes msg and status as args
end () {
  echo '*********************************************'
  echo '* Finished Streamlink install/update script *'
  echo "* Message: $1"
  echo '*********************************************'
  exit "$2"
}

# takes message and level as args
message () {
  if [ "$2" = 'info' ]; then echo "[TVHlink] $1"; else echo "[TVHlink] [ERROR] $1"; fi
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
  if [ -z "$(command -v pip3)" ]; then end 'Unusual behavior: pip3 is not installed.' 1;
  else
    if pip3 install --upgrade streamlink; then 
      message "Streamlink version: $(streamlink --version)." 'info'
    else 
      message 'Streamlink update failed!' 'error'
    fi
  fi
}

streamlink_install () {
  message 'APK: Updating pkg list.' 'info'
  if apk update; then 
    message 'APK: Installing required packages.' 'info'
    if apk add --no-cache py3-pip && apk add --no-cache --virtual .build-deps gcc musl-dev; then
        message 'PIP3: Updating and installing required packages.' 'info'
        if ! pip3 install --no-cache --upgrade setuptools; then message 'PIP3: Error while upgrading setuptools.' 'error'; fi
        if ! pip3 install --no-cache streamlink; then message 'PIP3: Error while installing Streamlink.' 'error' ; fi
    else
      end 'APK Critical error: Unable install required packages.' 1
    fi
    message 'APK: Removing packages no longer required.' 'info'
    apk del .build-deps gcc musl-dev
  else
    end 'APK Critical error: Unable to update pkg list. Check connectivity.' 1
  fi
  message 'Finsihed APK update and installs.' 'info'
}


############
# main logic
trap 'end "Received a signal to stop" 1' INT HUP TERM
if ! check_root; then end 'User is not root. This script needs root permission.' 1; fi

if check_streamlink; then
  message 'Updating Streamlink...'; streamlink_update
else
  message 'Installing Streamlink...'; streamlink_install
fi

end 'Completed without errors.' 0

exit 0