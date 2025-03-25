{ flake, ... }: users: let
  inherit (builtins) baseNameOf pathExists;
  inherit (flake.lib) mkAttrs;
in 

  mkAttrs users ( dir: let
    user = import "${users}/${dir}";
    path = "/${baseNameOf users}/${dir}";
    privateKey = "${users}/${dir}/id_ed25519.age";
    publicKey = "${users}/${dir}/id_ed25519.pub";

  in user // (

    # Special case for root user
    if dir == "root" then rec {
      inherit path;
      name = "root";
      uid = 0;
      description = "System administrator";
      isSystemUser = true;
      isNormalUser = false;
      linger = false;
      openssh = {
        authorizedKeys = user.openssh.authorizedKeys or {};
        authorizedPrincipals = user.openssh.authorizedPrincipals or [];
        privateKey = if pathExists privateKey then privateKey else null; # custom option
        publicKey = if pathExists publicKey then publicKey else null; # custom option
      };

    # Normal users with custom defaults
    } else rec {
      inherit path;
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
        privateKey = if pathExists privateKey then privateKey else null; # custom option
        publicKey = if pathExists publicKey then publicKey else null; # custom option
      };

    })
  )
