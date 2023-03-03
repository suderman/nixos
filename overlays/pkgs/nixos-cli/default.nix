# { lib, writeShellApplication, fzf, curl, less, gnused }: (writeShellApplication {
#   name = "nixos";
#   runtimeInputs = [ fzf curl less gnused ];
#   text = builtins.readFile ./nixos;
#   checkPhase = false;
# }) // {
#   meta = with lib; {
#     description = "nixos-cli script";
#     license = licenses.mit;
#     platforms = platforms.all;
#   };
# }
{ lib, runtimeShell, writeTextFile, fzf, curl, less, gnused }: 

let 
  name = "nixos";
  description = "nixos-cli script";
  runtimeInputs = [ fzf curl less gnused ];
  text = builtins.readFile ./nixos;
in 

writeTextFile {
  inherit name;
  executable = true;
  destination = "/bin/${name}";

  text = ''
    #!${runtimeShell}
  '' + lib.optionalString (runtimeInputs != [ ]) ''
    export PATH="${lib.makeBinPath runtimeInputs}:$PATH"
  '' + ''
    ${text}
  '';

  meta = with lib; {
    mainProgram = name;
    description = description;
    license = licenses.mit;
    platforms = platforms.all;
  };

}
