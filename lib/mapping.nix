{ flake, lib, ... }: let

  inherit (lib) foldl mapAttrsToList mapAttrs' nameValuePair; 

  # Flatten the tree into a "hostName.domain = address" set
  flatten = tree: foldl (a: b: a // b) {}  ( 
    mapAttrsToList (domain: hostNames: 
    (mapAttrs' (hostName: ip: nameValuePair ("${hostName}.${domain}") ip) hostNames)) tree
  );

in (flatten flake.networks)
# in flake.networks
# in (flatten flake.networks) // domains
