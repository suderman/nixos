{
  pkgs,
  perSystem,
  flake,
  ...
}:
perSystem.self.mkScript {
  name = "isy";
  path = [pkgs.adoptopenjdk-icedtea-web];
  text =
    # bash
    ''
      # echo $ISY_BASIC_AUTH | base64 -d | cut -d':' -f2 | wl-copy
      javaws http://${flake.networking.zones.home.isy}/admin.jnlp
    '';
}
