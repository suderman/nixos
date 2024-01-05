# this.lib.mkShellScript
{ pkgs, lib, this }: let

  inherit (builtins) isPath readFile;
  inherit (pkgs) runtimeShell writeTextFile;
  inherit (lib) concatLines makeBinPath mapAttrsToList optionalString;

in { name, text ? "", inputs ? [], env ? {} }: writeTextFile {

  inherit name;
  executable = true;
  destination = "/bin/${name}";

  text = ''
    #!${runtimeShell}
  '' + optionalString ( inputs != [] ) ''
    export PATH="${makeBinPath inputs}:$PATH"
  '' + concatLines ( mapAttrsToList (n: v: "export ${n}=\"${v}\"") env ) + ''
    ${if (isPath text) then readFile text else text}
  '';

  meta = with lib; {
    mainProgram = name;
    description = "Personal shell script";
    license = licenses.mit;
    platforms = platforms.all;
  };

}
