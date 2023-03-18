#!/usr/bin/env bash

# If we are debugging, enable trace
if [ "${DEBUG,,}" = "true" ]; then
  set -x
fi

if [ "$(id -u)" != "0" ]; then
  echo "Run as root."
  exit 1
fi

function getPref {
  local key="$1"
  sed -n -E "s/^.*${key}=\"([^\"]*)\".*$/\1/p" "${prefFile}"
}

function setPref {
  local key="$1"
  local value="$2"
  
  count="$(grep -c "${key}" "${prefFile}")"
  count=$(($count + 0))
  if [[ $count > 0 ]]; then
    sed -i -E "s/${key}=\"([^\"]*)\"/${key}=\"$value\"/" "${prefFile}"
  else
    sed -i -E "s/\/>/ ${key}=\"$value\"\/>/" "${prefFile}"
  fi
}

prefFile="/var/lib/plex/Plex Media Server/Preferences.xml"

PLEX_CLAIM="$1"
if [ -z "${PLEX_CLAIM}" ]; then
  echo "Missing argument from https://www.plex.tv/claim/"
  exit 1
fi

# Create empty shell pref file if it doesn't exist already
if [ ! -e "${prefFile}" ]; then
  echo "Creating pref shell"
  mkdir -p "$(dirname "${prefFile}")"
  cat > "${prefFile}" <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<Preferences/>
EOF
  chown -R plex:plex "$(dirname "${prefFile}")"
fi

# Setup Server's client identifier
serial="$(getPref "MachineIdentifier")"
if [ -z "${serial}" ]; then
  serial="$(uuidgen)"
  setPref "MachineIdentifier" "${serial}"
fi
clientId="$(getPref "ProcessedMachineIdentifier")"
if [ -z "${clientId}" ]; then
  clientId="$(echo -n "${serial}- Plex Media Server" | sha1sum | cut -b 1-40)"
  setPref "ProcessedMachineIdentifier" "${clientId}"
fi

# Get server token and only turn claim token into server token if we have former but not latter.
token="$(getPref "PlexOnlineToken")"

if [ -n "${token}" ]; then
  echo "This Plex Server has already been claimed."
  exit 1
fi

if [ ! -z "${PLEX_CLAIM}" ] && [ -z "${token}" ]; then
  echo "Attempting to obtain server token from claim token"
  loginInfo="$(curl -X POST \
        -H 'X-Plex-Client-Identifier: '${clientId} \
        -H 'X-Plex-Product: Plex Media Server'\
        -H 'X-Plex-Version: 1.1' \
        -H 'X-Plex-Provides: server' \
        -H 'X-Plex-Platform: Linux' \
        -H 'X-Plex-Platform-Version: 1.0' \
        -H 'X-Plex-Device-Name: PlexMediaServer' \
        -H 'X-Plex-Device: Linux' \
        "https://plex.tv/api/claim/exchange?token=${PLEX_CLAIM}")"
  token="$(echo "$loginInfo" | sed -n 's/.*<authentication-token>\(.*\)<\/authentication-token>.*/\1/p')"
  
  if [ "$token" ]; then
    setPref "PlexOnlineToken" "${token}"
    echo "Plex Media Server successfully claimed"
    sudo systemctl restart plex.service
  fi
fi

