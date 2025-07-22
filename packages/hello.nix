{
  pkgs,
  perSystem,
  flake,
  ...
}:
perSystem.self.mkScript {
  path = [pkgs.owofetch];
  name = "hello";
  text =
    # bash
    ''
      source ${flake.lib.bash}
      info hello world
      owofetch
      warn goodbye world
    '';
}
