{ lib, writeTextFile, runtimeShell, gawk, git, gnused, linode-cli, jq, smenu, wl-clipboard, xdg-utils }: 

let 
  name = "nixos";
  description = "nixos-cli script";
  runtimeInputs = [ gawk git gnused linode-cli jq smenu wl-clipboard xdg-utils ];
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
