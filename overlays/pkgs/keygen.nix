{ pkgs, lib, writeShellApplication, git }: (writeShellApplication {
  name = "keygen";
  runtimeInputs = [ git ];
  text = builtins.readFile ../../secrets/keygen.sh;
}) // {
  meta = with lib; {
    description = "keygen script";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
