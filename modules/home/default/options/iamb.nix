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
        # https://iamb.chat/configure.html
        settings = {
          message_user_color = true;
          request_timeout = 180;
          typing_notice_display = true;
          typing_notice_send = true;
          username_display = "localpart";
          notifications.enabled = true;
          reaction_display = true;
          reaction_shortcode_display = false;
          image_preview.protocol.type = "kitty";
        };
        layout.style = "restore";
      };
    };
  };
}
