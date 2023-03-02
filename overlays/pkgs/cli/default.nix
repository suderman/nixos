{ lib, writeShellApplication, curl, less, gnused }: (writeShellApplication {
  name = "nixos";
  runtimeInputs = [ curl less gnused ];
  text = builtins.readFile ./nixos;
}) // {
  meta = with lib; {
    description = "cli script";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
