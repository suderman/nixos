# perSystem.self.mkScript {}
{pkgs, ...}: let
  inherit (builtins) isAttrs isPath isString readFile;
  inherit (pkgs) lib runtimeShell writeTextFile;
  inherit (lib) concatLines makeBinPath mapAttrsToList optionalString;

  fromPath = text: fromAttrs {inherit text;};
  fromString = text: fromAttrs {inherit text;};

  fromAttrs = {
    name ? "script",
    text ? "",
    path ? [pkgs.coreutils],
    env ? {},
    ...
  }:
    writeTextFile {
      inherit name;
      executable = true;
      destination =
        if name == "script"
        then ""
        else "/bin/${name}";

      text =
        # bash
        ''
          #!${runtimeShell}
        ''
        + optionalString (path != []) ''
          set -euo pipefail
          export PATH="${makeBinPath path}:''${PATH-}"

        ''
        + concatLines (mapAttrsToList (n: v: "export ${n}=\"${v}\"") env)
        + ''
          ${
            if (isPath text)
            then readFile text
            else text
          }
        '';

      meta = with lib; {
        mainProgram = name;
        description = "Personal shell script";
        license = licenses.mit;
        platforms = platforms.all;
      };
    };
in
  x:
    if (isString x)
    then (fromString x)
    else if (isPath x)
    then (fromPath x)
    else if (isAttrs x)
    then (fromAttrs x)
    else {}
