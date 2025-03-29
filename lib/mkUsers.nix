{ flake, ... }: let

  inherit (builtins) readFile;
  inherit (flake.lib) trim;

in users:  

  flake.lib.mkAttrs users ( dir: let
    user = import "${users}/${dir}";
  in user // (

    # Special case for root user
    if dir == "root" then rec {
      name = "root";
      uid = 0;
      description = "System administrator";
      isSystemUser = true;
      isNormalUser = false;
      linger = false;
      openssh = {
        authorizedKeys = user.openssh.authorizedKeys or {};
        authorizedPrincipals = user.openssh.authorizedPrincipals or [];
        publicKey = trim (readFile "${users}/${dir}/id_ed25519.pub"); # custom option
        privateKey = null; # custom option
      };

    # Normal users with custom defaults
    } else rec {
      name = user.name or dir;
      uid = user.uid or null;
      description = user.description or name;
      isSystemUser = user.isSystemUser or false;
      isNormalUser = ! isSystemUser;
      useDefaultShell = user.useDefaultShell or true;
      linger = user.linger or true;
      openssh = {
        authorizedKeys = user.openssh.authorizedKeys or {};
        authorizedPrincipals = user.openssh.authorizedPrincipals or [];
        publicKey = trim (readFile "${users}/${dir}/id_ed25519.pub"); # custom option
        privateKey = null; # custom option
      };

    })
  )
