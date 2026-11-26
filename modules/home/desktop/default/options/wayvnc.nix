# services.wayvnc.enable = true;
# This desktop in a browser: wayvnc on localhost, noVNC beside it, and Traefik in
# front as vnc-USER.HOST (the NixOS module of the same name). Logins are the
# user's own password through PAM, encrypted with RSA-AES, which noVNC speaks.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.wayvnc;
  stateDir = ".local/state/wayvnc";
  rsaKey = "${config.home.homeDirectory}/${stateDir}/rsa_key.pem";
in {
  options.services.wayvnc.webPort = lib.mkOption {
    type = lib.types.port;
    default = 6080 + config.home.portOffset;
    description = "Local port where noVNC serves its browser client for Traefik.";
  };

  config = lib.mkIf cfg.enable {
    services.wayvnc = {
      autoStart = true;
      settings = {
        address = "127.0.0.1";
        port = 5900 + config.home.portOffset;
        enable_auth = true;
        enable_pam = true;
        rsa_private_key_file = rsaKey;
      };
    };

    # wayvnc needs the RSA key before it starts; make one the first time.
    systemd.user.services.wayvnc.Service.ExecStartPre = lib.getExe (pkgs.self.mkScript {
      name = "wayvnc-rsa-key";
      path = [pkgs.openssh];
      text =
        # bash
        ''
          [[ -s ${rsaKey} ]] && exit 0
          install -d -m 700 "$(dirname ${rsaKey})"
          ssh-keygen -q -m pem -t rsa -b 4096 -N "" -f ${rsaKey}
        '';
    });

    systemd.user.services.novnc = {
      Unit = {
        Description = "noVNC browser client for wayvnc";
        After = ["wayvnc.service"];
        PartOf = [cfg.systemdTarget];
      };
      Service = {
        ExecStart = "${lib.getExe' pkgs.novnc "novnc"} --listen 127.0.0.1:${toString cfg.webPort} --vnc 127.0.0.1:${toString cfg.settings.port} --file-only";
        Restart = "on-failure";
      };
      Install.WantedBy = [cfg.systemdTarget];
    };

    persist.scratch.directories = [
      {
        directory = stateDir;
        mode = "0700";
      }
    ];
  };
}
