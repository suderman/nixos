#!/usr/bin/env bash
API="https://api.cloudflare.com/client/v4";
TOKEN=$CF_DNS_API_TOKEN # from secrets

# Main function
function main {

  # Required env variables
  [ -z "$TOKEN" ] && echo "Error: missing TOKEN" && return 1
  [ -z "$HOSTNAME" ] && echo "Error: missing HOSTNAME" && return 1
  [ -z "$DOMAIN" ] && echo "Error: missing DOMAIN" && return 1

  # tmp file of cached IP
  local cache=/tmp/ddns

  # Remove the cached IP if older than 1 hour
  if [ -e $cache ]; then
    test $(find $cache -mmin +60 | head -n 1) && rm -f $cache && touch $cache
  else
    touch $cache
  fi

  # Get public IP address from Cloudflare
  ip="$(dig +short txt ch whoami.cloudflare @1.0.0.1 | tr -d \")"
  
  # Check if public IP doesn't match the cached IP
  if [ "$(cat $cache)" != "$ip" ]; then

    # Create/update A record
    record A "ddns.$HOSTNAME" $ip

    # Save the IP to the cache
    echo $ip > $cache

  fi

  # All done
  clean

}

# Create or update a record
function record {

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
          "comment": "ddns"
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
        "comment": "ddns"
      }' >/dev/null 2>&1

  fi

}

# Get the record_id of the provided type and name
function record_id {

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
