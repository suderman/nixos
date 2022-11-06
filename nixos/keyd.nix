{ pkgs, ... }:
{
    users.groups.keyd.name = "keyd";

    environment.etc = {
      "keyd/default.conf".source = pkgs.writeText "keyd.conf" ''
        [ids]
        *
        [main]
        capslock = overload(capslock, capslock)
        leftcontrol = layer(control)
        [capslock]
        h = left
        j = down
        k = up
        l = right
        y = home
        u = pageup
        i = pagedown
        o = end
        [control:C]
        h = backspace
        [ = esc
      '';
    };

    environment.systemPackages = [ pkgs.keyd ];

    systemd.services.keyd = {
      wantedBy = [ "graphical.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = ''${pkgs.keyd}/bin/keyd'';
        Restart = "always";
      };
    };

}

# { config, pkgs, lib, ... }:
# let cfg = config.own.keyd; in
# with lib; with types;
# {
#   options.own.keyd = {
#     enable = mkEnableOption "";
#   };
#
#   config = mkIf cfg.enable {
#     environment.etc = {
#       "keyd/default.conf".source = pkgs.writeText "keyd.conf" ''
#         [ids]
#         *
#         [main]
#         capslock = overload(capslock, capslock)
#         leftcontrol = layer(control)
#         [capslock]
#         h = left
#         j = down
#         k = up
#         l = right
#         y = home
#         u = pageup
#         i = pagedown
#         o = end
#         [control:C]
#         h = backspace
#         [ = esc
#       '';
#     };
#
#     systemd.services.keyd = {
#       wantedBy = [ "graphical.target" ];
#       serviceConfig = {
#         Type = "simple";
#         ExecStart = ''${pkgs.keyd}/bin/keyd'';
#         Restart = "always";
#       };
#     };
#   };
#
# }
