{
  flake,
  pkgs,
  ...
}: let
  lib = pkgs.lib;
  cfg = flake.nixosConfigurations.kit.config;
  sunshine = cfg.services.sunshine;
  firewall = cfg.networking.firewall;
  persistence = cfg.home-manager.users.jon.persist.storage.directories;
  phone = lib.findFirst (package: lib.getName package == "sunshine-phone") null cfg.environment.systemPackages;
in
  assert sunshine.enable && sunshine.autoStart;
  assert !sunshine.capSysAdmin && !sunshine.openFirewall;
  assert sunshine.settings.capture == "wlr";
  assert sunshine.settings.encoder == "nvenc";
  assert sunshine.settings.upnp == "disabled";
  assert sunshine.settings.origin_web_ui_allowed == "pc";
  assert sunshine.settings.csrf_allowed_origins == "https://sunshine.kit";
  assert cfg.services.traefik.proxy.sunshine == "https://127.0.0.1:47990";
  assert cfg.services.traefik.dynamicConfigOptions.http.routers.sunshine
  == {
    entrypoints = "websecure";
    rule = "Host(`sunshine.kit`)";
    tls = true;
    middlewares = ["sunshine" "local"];
    service = "sunshine";
  };
  assert builtins.elem "sunshine.kit" cfg.services.traefik.internalHostNames;
  assert cfg.services.traefik.records."sunshine.kit" == cfg.networking.address;
  assert phone != null;
  assert sunshine.applications.apps
  == [
    {name = "Desktop";}
    {
      name = "Desktop (phone)";
      prep-cmd = [
        {
          do = "${phone}/bin/sunshine-phone start";
          undo = "${phone}/bin/sunshine-phone reset";
        }
      ];
    }
  ];
  assert firewall.interfaces.tailscale0.allowedTCPPorts == [47984 47989 48010];
  assert firewall.interfaces.tailscale0.allowedUDPPorts == [47998 47999 48000 48002 48010];
  assert lib.all (port: !(builtins.elem port firewall.allowedTCPPorts)) [47984 47989 47990 48010];
  assert lib.all (range: lib.hasInfix "-s ${range}" firewall.extraCommands) ["10.1.0.0/16" "10.2.0.0/16"];
  assert cfg.systemd.user.services.sunshine.environment.LD_LIBRARY_PATH == "/run/opengl-driver/lib";
  assert builtins.elem {
    directory = ".config/sunshine";
    mode = "0700";
  }
  persistence;
  assert builtins.elem {
    directory = ".config/Moonlight Game Streaming Project";
    mode = "0700";
  }
  persistence;
    pkgs.runCommand "sunshine-check" {nativeBuildInputs = [pkgs.bash pkgs.jq pkgs.python3];} ''
      bash -n ${pkgs.writeText "sunshine-firewall.sh" firewall.extraCommands}
      test -x ${phone}/bin/sunshine-phone
      python ${./sunshine-phone.py} ${../modules/nixos/desktop/default/options/sunshine-phone.sh}
      touch "$out"
    ''
