# services.sunshine.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.sunshine;
  tcpPorts = map (offset: cfg.settings.port + offset) [(-5) 0 21];
  udpPorts = map (offset: cfg.settings.port + offset) [9 10 11 13 21];
  portList = ports: lib.concatMapStringsSep "," toString ports;
  phone = pkgs.writeShellApplication {
    name = "sunshine-phone";
    runtimeInputs = [config.programs.hyprland.package pkgs.jq pkgs.coreutils];
    text = builtins.readFile ./sunshine-phone.sh;
  };
  laptopProfiles = {
    normal = lib.getAttrs ["output" "mode" "scale"] cfg.laptop.monitor;
    laptop = laptopProfiles.normal // {inherit (cfg.laptop) mode scale;};
  };
  laptop = pkgs.writeShellApplication {
    name = "sunshine-laptop";
    runtimeInputs = [config.programs.hyprland.package pkgs.jq pkgs.coreutils];
    text = ''
      normalProfile=${lib.escapeShellArg (builtins.toJSON laptopProfiles.normal)}
      laptopProfile=${lib.escapeShellArg (builtins.toJSON laptopProfiles.laptop)}
      ${builtins.readFile ./sunshine-laptop.sh}
    '';
  };
in {
  options.services.sunshine.laptop = {
    enable = lib.mkEnableOption "the Laptop application for the existing Hyprland output";
    monitor = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.bool);
      description = "Normal Home Manager Hyprland monitor declaration to restore.";
    };
    mode = lib.mkOption {
      type = lib.types.str;
      description = "Temporary physical output mode, such as 2560x1440@60Hz.";
    };
    scale = lib.mkOption {
      type = lib.types.str;
      description = "Temporary Hyprland output scale.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.laptop.enable || config.programs.hyprland.enable;
        message = "The Sunshine Laptop application requires Hyprland.";
      }
    ];
    services.sunshine = {
      package = lib.mkDefault pkgs.unstable.sunshine;
      settings = {
        sunshine_name = config.networking.hostName;
        capture = lib.mkDefault "wlr";
        upnp = "disabled";
        origin_web_ui_allowed = "pc";
        csrf_allowed_origins = "https://sunshine.${config.networking.hostName}";
      };
      applications.apps =
        [{name = "Desktop";}]
        ++ lib.optional config.programs.hyprland.enable {
          name = "Phone";
          prep-cmd = [
            {
              do = "${phone}/bin/sunshine-phone start";
              undo = "${phone}/bin/sunshine-phone reset";
            }
          ];
        }
        ++ lib.optional cfg.laptop.enable {
          name = "Laptop";
          prep-cmd = [
            {
              do = "${laptop}/bin/sunshine-laptop start";
              undo = "${laptop}/bin/sunshine-laptop reset";
            }
          ];
        };
    };

    environment.systemPackages =
      lib.optional config.programs.hyprland.enable phone
      ++ lib.optional cfg.laptop.enable laptop;

    # FFmpeg loads driver libraries dynamically, including libcuda for NVENC.
    systemd.user.services.sunshine.environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";

    services.traefik = {
      enable = true;
      proxy.sunshine = "https://127.0.0.1:${toString (cfg.settings.port + 1)}";
    };

    # Streaming is private. Admin access uses Traefik, not an open admin port.
    networking.firewall = {
      interfaces.tailscale0 = {
        allowedTCPPorts = tcpPorts;
        allowedUDPPorts = udpPorts;
      };
      extraCommands = lib.concatMapStringsSep "\n" (range: ''
        iptables -A nixos-fw -s ${range} -p tcp -m multiport --dports ${portList tcpPorts} -j nixos-fw-accept
        iptables -A nixos-fw -s ${range} -p udp -m multiport --dports ${portList udpPorts} -j nixos-fw-accept
      '') ["10.1.0.0/16" "10.2.0.0/16"];
    };

    home-manager.sharedModules = [
      {
        home.packages = [pkgs.moonlight-qt];
        persist.storage.directories = [
          {
            directory = ".config/sunshine";
            mode = "0700";
          }
          {
            directory = ".config/Moonlight Game Streaming Project";
            mode = "0700";
          }
        ];
      }
    ];
  };
}
