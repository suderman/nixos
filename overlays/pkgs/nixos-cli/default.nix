{ lib, writeShellApplication, fzf, curl, less, gnused }: (writeShellApplication {
  name = "nixos";
  runtimeInputs = [ fzf curl less gnused ];
  text = builtins.readFile ./nixos;
  checkPhase = false;
}) // {
  meta = with lib; {
    description = "nixos-cli script";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
