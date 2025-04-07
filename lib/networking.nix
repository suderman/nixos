# Attribute set describing my domains and IP addresses  
{ flake, lib, ... }: let

  inherit (flake.lib) mkAttrs;
  inherit (lib) foldl filterAttrs mapAttrsToList mapAttrs' nameValuePair; 

  # Flatten the tree into a "hostName.domain = address" set
  flatten = tree: foldl (a: b: a // b) {}  ( 
    mapAttrsToList (domain: hostNames: 
    (mapAttrs' (hostName: ip: nameValuePair ("${hostName}.${domain}") ip) hostNames)) tree
  );

in rec {

  # Self-signed CA certificate, domain name used for public services
  inherit (import ../zones) ca domainName;

  # Centralized list of IP addresses
  zones = mkAttrs ../zones (zone: import ../zones/${zone});

  # Internal DNS records
  records = (flatten zones) // domains;

  # Determine IP address for each host from configuration domain
  domains = filterAttrs (n: v: v != "") ( mkAttrs flake.nixosConfigurations ( hostName: let
    inherit (flake.nixosConfigurations."${hostName}".config.networking) domain;
    ip = if zones ? ${domain} then ( if zones.${domain} ? ${hostName} then zones.${domain}.${hostName} else "" ) else "";
  in ip ) );

}

