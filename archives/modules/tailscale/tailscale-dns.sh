#!/usr/bin/env bash
API="https://api.cloudflare.com/client/v4";
TOKEN=$CF_DNS_API_TOKEN # from secrets

# Main function
function main {

  # Required env variables
  [ -z "$TOKEN" ] && echo "Error: missing TOKEN" && return 1
  [ -z "$DOMAIN" ] && echo "Error: missing DOMAIN" && return 1

  # tmp directory cached values
  local cache=/tmp/tailscale-dns

  # Check if the cache directory doesn't exist
  if [ ! -d $cache ]; then

    # Create this directory
    mkdir -p $cache

    # Assume this is a fresh boot, so also 
    # create/update two records for localhost
    record A "local" "127.0.0.1"
    record CNAME "*.local" "local.$DOMAIN"

  fi
    
  # Get all tailscale machines
  tailscale status | while read line; do

    # Extract ip address and machine name from each line
    ip="$(echo $line | awk '{print $1}')"
    name="$(echo $line | awk '{print $2}')"

    # Ensure a cache file exists
    touch $cache/$name

    # Check if tailscale's IP doesn't match the cached IP
    if [ "$(cat $cache/$name)" != "$ip" ]; then

      # Create/update two records for each machine
      record A $name $ip
      record CNAME "*.$name" $name.$DOMAIN

      # Save the record to the cache
      echo $ip > $cache/$name

    fi

  done

  # All done
  clean

}

# Create or update a record
function record {

  # Require token
  [ -z "$TOKEN" ] && return 1

  # Require three args
  local TYPE="$1" NAME="$2" CONTENTS="$3"
  [ -z "$TYPE" ] || [ -z "$NAME" ] || [ -z "$CONTENTS" ]  && return 1

  # Lookup zone id and record id
  local ZONE=$(zone_id) RECORD=$(record_id $TYPE $NAME)

  # Record doesn't yet exist
  if [ "$RECORD" = "null" ]; then

    # Create new record
    curl -s -X POST $API/zones/$ZONE/dns_records \
      --header "Authorization: Bearer $TOKEN" \
      --header "Content-Type: application/json" \
      --data '{
          "type": "'$TYPE'",
          "name": "'$NAME'",
          "content": "'$CONTENTS'",
          "ttl": 300,
          "proxied": false,
          "comment": "tailscale-dns"
        }' >/dev/null 2>&1

  # Record already exists
  else

    # Update existing record
    curl -s -X PUT $API/zones/$ZONE/dns_records/$RECORD \
    --header "Authorization: Bearer $TOKEN" \
    --header "Content-Type: application/json" \
    --data '{
        "type": "'$TYPE'",
        "name": "'$NAME'",
        "content": "'$CONTENTS'",
        "ttl": 300,
        "proxied": false,
        "comment": "tailscale-dns"
      }' >/dev/null 2>&1

  fi

}

# Get the record_id of the provided type and name
function record_id {

  # Require token
  [ -z "$TOKEN" ] && return 1

  # Require two args
  local TYPE="$1" NAME="$2"
  [ -z "$TYPE" ] || [ -z "$NAME" ] && return 1

  curl -s -X GET $API/zones/$(zone_id)/dns_records\?type=$TYPE\&name=$NAME.$DOMAIN \
    --header "Authorization: Bearer $TOKEN" \
    --header "Content-Type: application/json" \
    | jq '.result[0].id' | tr -d \"

  }

  # Get the zone_id for the host's domain
  function zone_id {

  # Require token
  [ -z "$TOKEN" ] && return 1

  # Check if zone_id has been cached on disk
  if [ ! -e /tmp/zone_id ]; then

    # If not, get the zone id from the API and save to disk
    curl -s -X GET $API/zones?name=$DOMAIN \
      --header "Authorization: Bearer $TOKEN" \
      --header "Content-Type: application/json" \
      | jq -r '.result[0].id' | tr -d \" > /tmp/zone_id

  fi

  # Output the cached copy
  cat /tmp/zone_id

}

# Clear the cached copy of the zone id
function clean {
  rm -f /tmp/zone_id
}

main 
