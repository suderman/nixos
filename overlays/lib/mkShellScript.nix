# this.lib.mkShellScript
{ pkgs, lib, this }:

  { name, text, inputs ? [] }: pkgs.writeTextFile {

    inherit name;
    executable = true;
    destination = "/bin/${name}";

    text = ''
      #!${pkgs.runtimeShell}
    '' + lib.optionalString (inputs != []) ''
      export PATH="${lib.makeBinPath inputs}:$PATH"
    '' + ''
      ${text}
    '';

    meta = with lib; {
      mainProgram = name;
      description = "Personal shell script";
      license = licenses.mit;
      platforms = platforms.all;
    };

  }
