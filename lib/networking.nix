# Attribute set describing my domains and IP addresses  
{ flake, lib, ... }: let

  inherit (flake.lib) mkAttrs;
  inherit (lib) foldl filterAttrs mapAttrsToList mapAttrs' nameValuePair; 

  # Centralized hierarchy of IP addresses
  zones = mkAttrs ../zones (zone: import ../zones/${zone});

  # Determine primary IP address for each host from configuration domain
  addresses = filterAttrs (n: v: v != "") ( mkAttrs flake.nixosConfigurations ( hostName: let
    inherit (flake.nixosConfigurations."${hostName}".config.networking) domain;
    ip = if isNull domain then "" else (zones.${domain}.${hostName} or "");
  in ip ) );

  # Flatten the tree into a "hostName.domain = address" set
  flatten = tree: foldl (a: b: a // b) {}  ( 
    mapAttrsToList (domain: hostNames: 
    (mapAttrs' (hostName: ip: nameValuePair ("${hostName}.${domain}") ip) hostNames)) tree
  );

in {

  # Self-signed CA certificate, domain name used for public services
  inherit (import ../zones) ca domainName;

  # Centralized hierarchy of IP addresses
  inherit zones;

  # Internal DNS records
  records = (flatten zones) // addresses;

}

