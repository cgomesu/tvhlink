#!/usr/bin/env sh

#########################################################################################
# Script to install and upgrade Streamlink on the TVHeadend LinuxServer docker container #
#########################################################################################
# How-To:
#  1. Copy 'streamlink_for_tvh_container.sh' to /config/custom-cont-init.d
#  2. Start/Restart the tvheadend container
#########################################################################################
# Author: cgomesu
# Repo: https://github.com/cgomesu/tvhlink
#########################################################################################
# Notes
#  - Python 3.10.1 (edge branch) changes Python pkg directory
#  - LinuxServer image comes with Python3 and the community repo source enabled
#  - Streamlink 3.0.0 introduces lxml>=4.6.4 and <5.0 requirement
#  - Streamlink 3.0.0 introduces pycountry and pycrypto dependencies
#  - Keep this script POSIX sh compliant for compatibility
#  - Use shellcheck
#########################################################################################
# Additional info
#
# Base image URL target:
#  ghcr.io/linuxserver/tvheadend
#
# Script installs or upgrades the following pkg:
#  python3, python3-dev, pip, setuptools, streamlink
#
# Tested images (tvheadend:latest):
#  arm64:
#   sha256:67821caa037da9d4fe68e83023a50518589193dfcd6fd3e1da0f23408ea9a139
#  amd64:
#   sha256:f77bfaf3a8440f3eeb6af418edd887676a6b27e21b53e1fde259e9b59201b28b
#########################################################################################

# apk variables
APK_BRANCH='edge'
APK_MAIN="http://dl-cdn.alpinelinux.org/alpine/${APK_BRANCH:-edge}/main"
APK_COMMUNITY="http://dl-cdn.alpinelinux.org/alpine/${APK_BRANCH:-edge}/community"
APK_PY3_LXML='4.6.4'

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

python3_upgrade () {
  message "APK: Installing packages from the $APK_BRANCH branch." 'info'
  if ! apk add --upgrade --no-cache -X "$APK_MAIN" -X "$APK_COMMUNITY" python3 py3-pip "py3-lxml>$APK_PY3_LXML"; then
    end "APK: Critical error. Unable to upgrade or install Python3 and related packages from Alpine's $APK_BRANCH branch." 1
  fi
}

streamlink_install () {
  message 'APK and PIP3: Installing required packages.' 'info'
  # install temporary build dependencies in .build-deps from default /etc/apk/repositories
  # this is required for building a few of the streamlink dependencies
  if ! apk add --no-cache --virtual .build-deps gcc musl-dev; then
    end 'APK: Critical error. Unable install required packages.' 1
  fi

  if check_py3_pkg_exist pip; then
    # upgrade setuptools and pip before streamlink installation
    if ! pip3 install --no-cache-dir -U setuptools pip; then 
      message 'PIP3: Error while upgrading setuptools and pip.' 'error'
    fi
    # after upgrade, let pip3 try to install streamlink until it succeed
    message 'PIP3: Installing Streamlink.' 'info'
    pip3 install --no-cache-dir streamlink
  else
    message 'PIP3: Critical error. pip3 should be installed but is not.' 'error'
  fi

  # cleanup for temporary apk build dependencies
  message 'APK: Removing packages no longer required.' 'info'
  apk del .build-deps

  # check that script succeeded to install streamlink or raise critical error
  if ! check_py3_pkg_exist streamlink; then
    end 'PIP3: Critical error. Cannot find Streamlink. Check above for installation errors.' 1
  fi
}

streamlink_upgrade () {
  if check_py3_pkg_exist pip; then
    # upgrade setuptools and pip first
    if ! pip3 install --no-cache-dir -U setuptools pip; then
      message 'PIP3: Error while upgrading setuptools and pip.' 'error'
    fi 
    # upgrade streamlink last and exit on error
    if ! pip3 install --no-cache-dir -U streamlink; then
      end "PIP3: Critical error. Unable to upgrade Streamlink. Current version is still $(streamlink --version)." 1
    fi
  else
    end 'PIP3: Critical error. pip3 should be installed but is not.' 1
  fi
}


############
# main logic
start

trap "end 'Received a signal to stop' 1" INT HUP TERM

if ! check_root; then end 'User is not root. This script needs root permission.' 1; fi

# upgrade to the latest available Python3 version and related APK packages
# see https://github.com/cgomesu/tvhlink/issues/10
# see https://github.com/cgomesu/tvhlink/issues/12
message 'Upgrading Python3...' 'info'; python3_upgrade

if check_py3_pkg_exist streamlink; then
  message 'Upgrading Streamlink...' 'info'; streamlink_upgrade
else
  message 'Installing Streamlink...' 'info'; streamlink_install
fi

message "Streamlink version: $(streamlink --version)." 'info'
end 'Reached EOF without critical errors.' 0
