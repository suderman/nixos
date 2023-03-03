{ lib, writeTextFile, runtimeShell, git, fzf, gawk, gnused, linode-cli }: 

let 
  name = "nixos";
  description = "nixos-cli script";
  runtimeInputs = [ git fzf gawk gnused linode-cli ];
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
