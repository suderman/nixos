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
  laptop = pkgs.writeShellApplication {
    name = "sunshine-laptop";
    runtimeInputs = [config.programs.hyprland.package pkgs.jq pkgs.coreutils];
    text = builtins.readFile ./sunshine-laptop.sh;
  };
in {
  config = lib.mkIf cfg.enable {
    services.sunshine = {
      # Guard-only backport of LizardByte/Sunshine#5748; remove after an upstream fix.
      package = lib.mkDefault (pkgs.unstable.sunshine.overrideAttrs (old: {
        patches = (old.patches or []) ++ [./wlr-pending-frame.patch];
      }));
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
        };
    };

    environment.systemPackages = lib.optionals config.programs.hyprland.enable [phone laptop];

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
