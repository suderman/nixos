# Attribute set describing my domains, hostnames and IP addresses  
this: let

  inherit (builtins) attrNames attrValues filter;
  inherit (this.lib) mkAttrs;
  inherit (this.inputs.nixpkgs.lib) foldl filterAttrs hasPrefix mapAttrsToList mapAttrs' nameValuePair naturalSort unique; 

  # Centralized list of IP addresses
  networks = mkAttrs ./. ( network: import ./${network} );

  # Flatten the tree into a "hostName.domain = address" set
  flatten = tree: foldl (a: b: a // b) {}  ( 
    mapAttrsToList (domain: hostNames: 
    (mapAttrs' (hostName: ip: nameValuePair ("${hostName}.${domain}") ip) hostNames)) tree
  );

  # Determine IP address for each host from configuration domain
  domains = filterAttrs (n: v: v != "") ( mkAttrs ../configurations ( hostName: let
    config = import ../configurations/${hostName};
    domain = if config ? domain then config.domain else "";
    ip = if networks ? ${domain} then ( if networks.${domain} ? ${hostName} then networks.${domain}.${hostName} else "" ) else "";
  in ip ) );

in this // rec {

  # Self-signed CA certificate (with ca-key in secrets)
  # openssl req -new -x509 -nodes -extensions v3_ca -days 25568 -subj "/CN=Suderman CA" -key ca.key -out ca.crt  
  ca = ./ca.crt;

  inherit networks domains;
  mapping = (flatten networks) // domains;
  hostNames = filter (name: hasPrefix this.hostName name) (attrNames mapping);
  addresses = [ "127.0.0.1" ] ++ unique( naturalSort( attrValues( filterAttrs (name: ip: hasPrefix this.hostName name) mapping )));

}
