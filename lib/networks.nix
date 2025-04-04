# Attribute set describing my domains, hostnames and IP addresses  
{ flake, inputs, lib, ... }: let

  inherit (builtins) attrNames attrValues filter;
  inherit (flake.lib) mkAttrs;
  inherit (lib) foldl filterAttrs hasPrefix mapAttrsToList mapAttrs' nameValuePair naturalSort unique; 

  # Flatten the tree into a "hostName.domain = address" set
  flatten = tree: foldl (a: b: a // b) {}  ( 
    mapAttrsToList (domain: hostNames: 
    (mapAttrs' (hostName: ip: nameValuePair ("${hostName}.${domain}") ip) hostNames)) tree
  );

  # # Determine IP address for each host from configuration domain
  # domains = filterAttrs (n: v: v != "") ( mkConfigurations ( path: let
  #   config = import path;
  #   hostName = nameFromPath path;
  #   domain = if config ? domain then config.domain else "";
  #   ip = if networks ? ${domain} then ( if networks.${domain} ? ${hostName} then networks.${domain}.${hostName} else "" ) else "";
  # in ip ) );

in 

  # Centralized list of IP addresses
  mkAttrs ../networks ( network: import ../networks/${network} ) // rec {

    # inherit (import ../networks) ca domainName;

    # inherit domains;
    # mapping = (flatten networks) // domains;
    # hostNames = filter (name: hasPrefix config.networking.hostName name) (attrNames mapping);
    # addresses = [ "127.0.0.1" ] ++ unique( naturalSort( attrValues( filterAttrs (name: ip: hasPrefix this.hostName name) mapping )));

  }

  networking = {

    zones = { 
      tail = { cog = "..."; kit = "..."; };
      home = { cog = "..."; kit = "..."; };
    };

    records = {
      "cog.tail" = "...";
      "kit.tail" = "...";
      "cog.home" = "...";
      "kit.home" = "...";
    };

    domainName = "suderman.org";

  }

