{ flake, pkgs, perSystem, ... }: perSystem.self.mkScript {

  path = [ pkgs.owofetch ];
  name = "hello";
  text = ''
    source ${flake.lib.bash}
    info hello world
    owofetch
    warn goodbye world
  '';

}
