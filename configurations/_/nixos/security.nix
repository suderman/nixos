{ config, lib, pkgs, ... }: 

let

  inherit (lib) filterAttrs listToAttrs attrNames mkIf;

in {

  security = {

    # Does sudo need a password?
    sudo.wheelNeedsPassword = true;

    # If so, how long before asking again?
    sudo.extraConfig = lib.mkAfter ''
      Defaults timestamp_timeout=60
      Defaults lecture=never
    '';

    # Increase open file limit for sudoers
    pam.loginLimits = [
      { domain = "@wheel"; item = "nofile"; type = "soft"; value = "524288"; }
      { domain = "@wheel"; item = "nofile"; type = "hard"; value = "1048576"; }
    ];

    # Passwordless sudo when SSH'ing with keys
    pam.enableSSHAgentAuth = true;

  };

  services.openssh = {
    enable = true;

    # Harden
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "yes";

    # Automatically remove stale sockets
    extraConfig = ''
      StreamLocalBindUnlink yes
    '';

    # Allow forwarding ports to everywhere
    settings.GatewayPorts = "clientspecified";

  };

  # Start ssh agent and add all configurations as known hosts
  programs.ssh = let 
    keys = filterAttrs (k: v: k != "all") config.modules.secrets.keys.systems;
    knownHost = name: { 
      inherit name;
      value.publicKey = keys.${name};
    };
  in {
    knownHosts = listToAttrs ( map knownHost (attrNames keys) );
    startAgent = true;
  };

  # MOTD
  programs.rust-motd = {
    enable = true;
    # enableMotdInSSHD = true;
    settings = {
      global = {};
      banner = {
        color = "red";
        command = ''
          ${pkgs.inetutils}/bin/hostname | ${pkgs.figlet}/bin/figlet -f slant
        '';
      };
      uptime.prefix = "Up";
      memory.swap_pos = "beside";
      filesystems = {
        root = "/";
      };
      # docker = {};
      # fail2_ban = {};
      # filesystems = {};
      # last_login = {};
      # last_run = {};
      # memory = {};
      # service_status = {};
      # user_service_status = {};
      # s_s_l_certs = {};
      # uptime = {};
      # weather = {};
    };

    # settings = {
    #   banner = {
    #     color = "yellow";
    #     command = ''
    #       echo ""
    #       echo " +-------------+"
    #       echo " | 10110 010   |"
    #       echo " | 101 101 10  |"
    #       echo " | 0   _____   |"
    #       echo " |    / ___ \  |"
    #       echo " |   / /__/ /  |"
    #       echo " +--/ _____/---+"
    #       echo "   / /"
    #       echo "  /_/"
    #       echo ""
    #       systemctl --failed --quiet
    #     '';
    #   };
    #   uptime.prefix = "Uptime:";
    #   last_login = builtins.listToAttrs (map
    #   (user: {
    #     name = user;
    #     value = 2;
    #   })
    #   (builtins.attrNames config.home-manager.users));
    # };
  };

}
