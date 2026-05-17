# programs.iamb.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.iamb;

  iamb-native-tls = pkgs.iamb.overrideAttrs (old: {
    # The default iamb build uses rustls/webpki roots, which do not trust this
    # repo's private CA. Native TLS uses the system trust store instead.
    cargoBuildNoDefaultFeatures = true;
    cargoBuildFeatures = ["native-tls"];
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.pkg-config];
    buildInputs = (old.buildInputs or []) ++ [pkgs.openssl pkgs.sqlite];
  });
in {
  config = lib.mkIf cfg.enable {
    persist.scratch.directories = [".cache/iamb"];

    programs.iamb = {
      package = iamb-native-tls;
      settings = {
        settings = {
          message_user_color = true;
          request_timeout = 180;
          typing_notice_display = false;
          typing_notice_send = false;
          username_display = "localpart";
          notifications.enabled = true;
        };
        layout.style = "restore";
      };
    };
  };
}
