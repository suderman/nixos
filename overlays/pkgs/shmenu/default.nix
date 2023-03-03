{ lib, writeShellApplication }: (writeShellApplication {
  name = "shmenu";
  runtimeInputs = [];
  text = builtins.readFile ./shmenu.sh;
  checkPhase = false;
}) // {
  meta = with lib; {
    description = "shmenu";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
