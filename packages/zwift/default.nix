# Assume "docker" available system-wide
# including in "inputs" doesn't seem to work with nvidia-flavour
{ flake, pkgs, perSystem, ... }: perSystem.self.mkApplication {
  name = "zwift";
  path = [ pkgs.hostname ];
  text = ./zwift.sh;
  desktopName = "Zwift";
  icon = ./zwift.svg; 
}
