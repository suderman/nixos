{ config, lib, pkgs, ... }:

let
  cfg = config.services.tailscale;
  inherit (lib) mkIf;

  # agenix secrets combined with age files paths
  age = config.age // { 
    files = config.secrets.files; 
    enable = config.secrets.enable; 
  };

in {

  # services.tailscale.enable = true;
  config = mkIf cfg.enable {

    networking.firewall = {
      checkReversePath = "loose";  # https://github.com/tailscale/tailscale/issues/4432
      allowedUDPPorts = [ 41641 ]; # Facilitate firewall punching
    };

    # agenix
    age.secrets = mkIf age.enable {
      cloudflare-env = { file = age.files.cloudflare-env; };
    };

    # I want all my tailscale machines to have DNS records in Cloudflare
    #
    # If I have a machine named foo with IP address 100.65.1.1, and another
    # named bar with IP address 100.65.1.2, this will create four records: 
    #     foo.mydomain.org -> A     -> 100.65.1.1
    #     bar.mydomain.org -> A     -> 100.65.1.2
    #   *.foo.mydomain.org -> CNAME -> foo.mydomain.org
    #   *.bar.mydomain.org -> CNAME -> bar.mydomain.org
    # 
    # This is true for all my tailscale machines, and two localhost records: 
    #     local.mydomain.org -> A     -> 127.0.0.1
    #   *.local.mydomain.org -> CNAME -> local.mydomain.org
    #
    systemd.services."tailscale-dns" = {
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = mkIf age.enable age.secrets.cloudflare-env.path;
      };
      environment.DOMAIN = config.networking.domain;
      path = with pkgs; [ coreutils curl gawk jq tailscale ];
      script = ''

        API="https://api.cloudflare.com/client/v4";
        TOKEN=$CF_DNS_API_TOKEN # from secrets

        # Main function
        function main {

          # Require token and domain
          if [ -z "$TOKEN" ] || [ -z "$DOMAIN" ]; then
            echo "Error: missing TOKEN and/or DOMAIN"
            return 1
          fi

          # Get all tailscale machines
          tailscale status | while read line; do

            # Extract ip address and machine name from each line
            ip="$(echo $line | awk '{print $1}')"
            name="$(echo $line | awk '{print $2}')"

            # Create/update two records for each machine
            record A $name $ip
            record CNAME "*.$name" $name.$DOMAIN

          done

          # Also create/update two records for localhost
          record A "local" "127.0.0.1"
          record CNAME "*.local" "local.$DOMAIN"

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
            # echo "curl -s -X POST $API/zones/$ZONE/dns_records"

            # Create new record
            curl -s -X POST $API/zones/$ZONE/dns_records \
              --header "Authorization: Bearer $TOKEN" \
              --header "Content-Type: application/json" \
              --data '{
                  "type": "'$TYPE'",
                  "name": "'$NAME'",
                  "content": "'$CONTENTS'",
                  "ttl": 300,
                  "proxied": false
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
                "proxied": false
              }' >/dev/null 2>&1

          fi

        }

        # Get the record_id of the provided type and name
        function record_id {

          # Require token and domain
          [ -z "$TOKEN" ] || [ -z "$DOMAIN" ] && return 1

          # Require two args
          local TYPE="$1" NAME="$2"
          [ -z "$TYPE" ] || [ -z "$NAME" ] && return 1

          curl -s -X GET $API/zones/$(zone_id)/dns_records\?type=$TYPE\&name=$NAME.$DOMAIN \
            --header "Authorization: Bearer $TOKEN" \
            --header "Content-Type: application/json" \
            | jq '.result[0].id' | tr -d \"

        }

        # Get the zone_id for the provided $DOMAIN
        function zone_id {

          # Require token and domain
          [ -z "$TOKEN" ] || [ -z "$DOMAIN" ] && return 1

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

      '';
    };

    # Run this script every day
    systemd.timers."tailscale-dns" = {
      wantedBy = [ "timers.target" ];
      partOf = [ "tailscale-dns.service" ];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "tailscale-dns.service";
      };
    };

    systemd.extraConfig = ''
      DefaultTimeoutStopSec=30s
    '';

    # # If tailscale is enabled, provide convenient hostnames to each IP address
    # # These records also exist in Cloudflare DNS, so it's a duplicated effort here.
    # services.dnsmasq.enable = mkIf cfg.enable true;
    # services.dnsmasq.extraConfig = with config.networking; mkIf cfg.enable ''
    #   address=/.local.${domain}/127.0.0.1
    #   address=/.cog.${domain}/100.67.140.102
    #   address=/.lux.${domain}/100.103.189.54
    #   address=/.graphene.${domain}/100.101.42.9
    # '';

  };

}
